

cohortStrata <- function(con,
                         cohortDatabaseSchema,
                         cohortTable,
                         targetId,
                         strataId) {
  
  cli::cat_bullet("Building strata for target cohort id ", crayon::magenta(targetId),
                  " using strata cohort id ", crayon::magenta(strataId),
                  bullet = "checkbox_on", bullet_col = "green")
  
  # create ids for cohort with and without strata
  cohortIdWithStrata <- as.integer(paste0(as.character(targetId), "01", strataId))
  cohortIdWithoutStrata <- as.integer(paste0(as.character(targetId), "00", strataId))
  
  cohortStrataSql <- "
        select @cohortIdWithStrata as cohort_definition_id,
              tar_cohort.subject_id,
              tar_cohort.cohort_start_date,
              tar_cohort.cohort_end_date
        into #t_w_s_cohort
              from (
                select * from @cohortDatabaseSchema.@cohortTable
                where cohort_definition_id IN (@targetId)
              ) tar_cohort
        join (
              select * from @cohortDatabaseSchema.@cohortTable
              where cohort_definition_id IN (@strataId)
          ) strata_cohort
        ON tar_cohort.subject_id = strata_cohort.subject_id
        and strata_cohort.cohort_start_date between DATEADD(days, -4, tar_cohort.cohort_start_date) and tar_cohort.cohort_start_date
        and strata_cohort.cohort_end_date >= tar_cohort.cohort_start_date
        ;


        select @cohortIdWithoutStrata as cohort_definition_id,
              tar_cohort.subject_id,
              tar_cohort.cohort_start_date,
              tar_cohort.cohort_end_date
        into #t_wo_s_cohort
        from (
            select * from @cohortDatabaseSchema.@cohortTable
            where cohort_definition_id IN (@targetId)
          ) tar_cohort
        left join (
            select * from @cohortDatabaseSchema.@cohortTable
            where cohort_definition_id IN (@strataId)
          ) strata_cohort
        ON tar_cohort.subject_id = strata_cohort.subject_id
        and tar_cohort.cohort_start_date >= DATEADD(days, 4, strata_cohort.cohort_start_date) 
        and strata_cohort.cohort_end_date >= tar_cohort.cohort_start_date
        ;


        delete from @cohortDatabaseSchema.@cohortTable where cohort_definition_id = @cohortIdWithStrata;
        delete from @cohortDatabaseSchema.@cohortTable where cohort_definition_id = @cohortIdWithoutStrata;


        INSERT INTO @cohortDatabaseSchema.@cohortTable (
        	cohort_definition_id,
        	subject_id,
        	cohort_start_date,
        	cohort_end_date
        )
        -- T with S
        select cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
        from #t_w_s_cohort

        UNION ALL
        
        -- T without S
        select cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
        from #t_wo_s_cohort
        ;


        TRUNCATE TABLE #t_w_s_cohort;
        DROP TABLE #t_w_s_cohort;

        TRUNCATE TABLE #t_wo_s_cohort;
        DROP TABLE #t_wo_s_cohort;
  "
  
  cohortStrataSql <- SqlRender::render(
    cohortStrataSql,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTable = cohortTable,
    targetId = targetId,
    strataId = strataId,
    cohortIdWithStrata = cohortIdWithStrata,
    cohortIdWithoutStrata = cohortIdWithoutStrata) %>%
     SqlRender::translate(targetDialect = con@dbms)
  
  DatabaseConnector::executeSql(connection = con, cohortStrataSql, progressBar = FALSE)
  
  ## Strata IDs
  ids <- c(cohortIdWithoutStrata, cohortIdWithStrata)
  strataIds <- data.frame(id = ids)
  
  #TODO Add timing
  cohortSchemaTable <- paste(cohortDatabaseSchema, cohortTable, sep = ".")
  cli::cat_bullet("Cohort strata written to ", cohortSchemaTable,
                  bullet = "tick", bullet_col = "green")
  
  
  return(strataIds)
}


buildStrata <- function(con,
                        executionSettings,
                        analysisSettings) {
  
  ## get schema vars
  cdmDatabaseSchema <- executionSettings$cdmDatabaseSchema
  workDatabaseSchema <- executionSettings$workDatabaseSchema
  cohortTable <- executionSettings$cohortTable
  databaseId <- executionSettings$databaseName
  outputFolder <- fs::path(here::here("results"), databaseId, analysisSettings$strata$outputFolder) %>%
    fs::dir_create()
  
  
  ## get cohort Ids
  targetCohorts <- analysisSettings$strata$cohorts$targetCohorts
  strataCohorts <- analysisSettings$strata$cohorts$strataCohorts 
  
  grid <- tidyr::expand_grid(targetCohorts$targetId, strataCohorts$strataId)
  
  cli::cat_rule("Building Cohort Strata")
  

  strataIds <- purrr::pmap_dfr(grid,
                               ~ cohortStrata(con = con,
                                              cohortDatabaseSchema = workDatabaseSchema,
                                              cohortTable = cohortTable,
                                              targetId = ..1,
                                              strataId = ..2)
  )

  
  sql <- "
    SELECT
      cohort_definition_id as id,
      'strata' as type,
      count(distinct subject_id) as subjects,
      count(subject_id) as entries
    FROM @cohortDatabaseSchema.@cohortTable
    WHERE cohort_definition_id IN (@strataIds)
    GROUP BY cohort_definition_id;
  "
  
  renderedSql <- SqlRender::render(
    sql,
    cohortDatabaseSchema = workDatabaseSchema,
    cohortTable = cohortTable,
    strataIds = strataIds$id) %>% 
    SqlRender::translate(targetDialect = con@dbms)
    
  
  strataCounts <- DatabaseConnector::querySql(connection = con, sql = renderedSql, snakeCaseToCamelCase = TRUE) %>%
    dplyr::mutate(
      name = dplyr::case_when(
        id == 2017 ~ "c2: earlyToxicity",
        id == 2007 ~ "c2: lateToxicity",
        id == 3017 ~ "c3: earlyToxicity",
        id == 3007 ~ "c3: lateToxicity",
        id == 4017 ~ "c4: earlyToxicity",
        id == 4007 ~ "c4: lateToxicity",
        id == 5017 ~ "c5: earlyToxicity",
        id == 5007 ~ "c5: lateToxicity",
        TRUE ~ NA_character_
        ),
      file = NA,
      database = executionSettings$databaseName
    )
  
  verboseSave(
    object = strataCounts,
    saveName = "cohortManifest_strata",
    saveLocation = outputFolder
  )
  
  invisible(strataCounts)
}

