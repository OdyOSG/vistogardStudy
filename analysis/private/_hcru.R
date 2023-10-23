# A. Meta Info -----------------------

# Task: Hcru
# Author: Martin Lavallee
# Date: 2023-07-26
# Description: The purpose of the _hcru.R script is to
# provide internal functions to run the hcru analysis

# B. Functions ------------------------


## Helpers -----------------
silentCovariates <- function(con, cdmDatabaseSchema, cohortTable, cohortDatabaseSchema, cohortId, covSettings) {
  
  cli::cat_bullet("Getting Covariates from database...",
                  bullet = "info", bullet_col = "blue")
  
  tik <- Sys.time()
  
  # Get covariate data
  quietCov <- purrr::quietly(FeatureExtraction::getDbCovariateData)
  cov <- quietCov(
    connection = con,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = cohortTable,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortId = cohortId,
    covariateSettings = covSettings,
    aggregated = FALSE
  )$result
  
  tok <- Sys.time()
  cli::cat_bullet("Covariates built at: ", crayon::red(tok),
                  bullet = "info", bullet_col = "blue")
  tdif <- tok - tik
  tok_format <- paste(scales::label_number(0.01)(as.numeric(tdif)), attr(tdif, "units"))
  cli::cat_bullet("Covariate build took: ", crayon::red(tok_format),
                  bullet = "info", bullet_col = "blue")
  
  return(cov)
}

# run hcru

visitContextAnalysis <- function(con,
                                 cohortDatabaseSchema,
                                 cohortTable,
                                 cdmDatabaseSchema,
                                 cohortId,
                                 timeA,
                                 timeB,
                                 outputFolder) {
  
  cli::cat_line()
  txt <- glue::glue("Run Visit Analysis for cohort id: {crayon::magenta(cohortId)}")
  cli::cat_bullet(txt, bullet = "pointer", bullet_col = "yellow")
  cli::cat_line()
  
  # Create Continuous settings
  covSettings <- FeatureExtraction::createCovariateSettings(
    useVisitConceptCountLongTerm = TRUE,
    longTermStartDays = timeA,
    endDays = timeB
  )
  
  # Run FE
  cov <- silentCovariates(con = con,
                          cdmDatabaseSchema = cdmDatabaseSchema,
                          cohortTable = cohortTable,
                          cohortDatabaseSchema = cohortDatabaseSchema,
                          cohortId = cohortId,
                          covSettings = covSettings)
  
  # Create temp table
  tmp <- cov$covariates %>%
    dplyr::left_join(cov$covariateRef, by = c("covariateId")) %>%
    dplyr::collect() %>%
    dplyr::mutate(
      covariateId = as.integer(gsub('.{3}$', '', covariateId)),
      covariateName = gsub(".*: ", "", covariateName)
    )
  
  # Aggregate counts
  visitCts <- tmp %>%
    group_by(
      covariateId,
      covariateName
    ) %>%
    summarize(
      min = min(covariateValue),
      p25 = quantile(covariateValue, probs = c(0.25)),
      median = median(covariateValue),
      p75 = quantile(covariateValue, probs = c(0.75)),
      max = max(covariateValue)
    ) %>%
    dplyr::mutate(
      cohortId = !!cohortId,
      timeFrame = glue::glue("{timeA}d - {timeB}d"),
      .before = 1
    )
  
  #create temp directory
  tmpDir1 <- fs::path(outputFolder, "tmp_continuous") %>%
    fs::dir_create()
  
  #savename
  save_path1 <- fs::file_temp(pattern = "visitCts",
                              tmp_dir = tmpDir1,
                              ext = "csv")
  #write csv to path
  readr::write_csv(visitCts, file = save_path1)
  cli::cat_bullet("Saved to:\n", crayon::cyan(save_path1), bullet = "info", bullet_col = "blue")
  
  # add total patients for zero count
  numPatients <- dplyr::tbl(
    con, dbplyr::in_schema(cohortDatabaseSchema, cohortTable)
  ) %>%
    dplyr::filter(
      cohort_definition_id == !!cohortId
    ) %>%
    dplyr::count(cohort_definition_id) %>%
    dplyr::collect() %>%
    dplyr::pull(n)
  
  
  # aggregate categorical
  visitCat <- tmp %>%
    group_by(
      covariateId,
      covariateName
    ) %>%
    summarize(
      oneVisit = sum(covariateValue == 1),
      twoVisits = sum(covariateValue == 2),
      threeVisits = sum(covariateValue == 3),
      fourVisits = sum(covariateValue == 4),
      fiveOrMoreVisits = sum(covariateValue >= 5)
    ) %>%
    dplyr::mutate(
      cohortId = !!cohortId,
      timeFrame = glue::glue("{timeA}d - {timeB}d"),
      .before = 1
    ) %>%
    dplyr::mutate(
      zeroVisit = numPatients - (oneVisit + twoVisits + threeVisits + fourVisits + fiveOrMoreVisits),
      .before = 5
    )
  
  #create temp directory
  tmpDir2 <- fs::path(outputFolder, "tmp_categorical") %>%
    fs::dir_create()
  # create save path
  save_path2 <- fs::file_temp(pattern = "visitCat",
                              tmp_dir = tmpDir2,
                              ext = "csv")
  readr::write_csv(visitCat, file = save_path2)
  cli::cat_bullet("Saved to:\n", crayon::cyan(save_path2), bullet = "info", bullet_col = "blue")
  
  
  invisible(c(save_path1, save_path2))
}


lengthOfStayAnalysis <- function(con,
                                 cohortDatabaseSchema,
                                 cohortTable,
                                 cdmDatabaseSchema,
                                 cohortId,
                                 timeA,
                                 timeB,
                                 outputFolder) {
  
  
  cli::cat_rule("Build Length of Stay Analysis")
  
  # SQL to get length of stay
  sql <- "
  SELECT b.cohort_definition_id, b.visit_concept_id,
    MIN(length_of_stay) AS min,
    percentile_cont(0.10) WITHIN GROUP (ORDER BY length_of_stay) AS p10,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY length_of_stay) AS p25,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY length_of_stay) AS median,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY length_of_stay) AS p75,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY length_of_stay) AS p90,
    STDDEV(length_of_stay) AS sd,
    MAX(length_of_stay) AS max
  FROM (
    SELECT
      t.cohort_definition_id, t.subject_id, t.cohort_start_date, t.cohort_end_date,
      v.visit_concept_id,
      v.visit_start_date, v.visit_end_date,
      CASE
        WHEN v.visit_end_date > t.win_b THEN DATEDIFF(day, v.visit_start_date, t.win_b)
        WHEN v.visit_start_date < t.win_a THEN DATEDIFF(day, t.win_a, v.visit_end_date)
        ELSE DATEDIFF(day, v.visit_start_date, v.visit_end_date) END AS length_of_stay
    FROM (
      SELECT *,
      DATEADD(day, @timeA, a.cohort_start_date) AS win_a,
      DATEADD(day, @timeB, a.cohort_start_date) AS win_b
      FROM @cohortDatabaseSchema.@cohortTable a
      WHERE cohort_definition_id IN (@targetId)
    ) t
    JOIN (
      SELECT *
      FROM @cdmDatabaseSchema.visit_occurrence
    ) v
    ON t.subject_id = v.person_id
    AND v.visit_start_date BETWEEN win_a AND win_b
    WHERE v.visit_concept_id IN (9201)
    ) b
    GROUP BY b.cohort_definition_id, b.visit_concept_id;
  "
  
  losSql <- SqlRender::render(
    sql,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTable = cohortTable,
    cdmDatabaseSchema = cdmDatabaseSchema,
    targetId = cohortId,
    timeA = timeA,
    timeB = timeB
  ) %>%
    SqlRender::translate(targetDialect = con@dbms)
  
  # Format
  losTbl <- DatabaseConnector::querySql(con, sql = losSql,
                                        snakeCaseToCamelCase = TRUE) %>%
    dplyr::mutate(
      covariateName = "Length of Stay",
      conceptName = dplyr::case_when(
        visitConceptId == 9201 ~ "Inpatient Visit",
        TRUE ~ NA_character_
      ),
      timeWindow = paste0(abs(timeA), "_", abs(timeB))
    ) %>%
    dplyr::select(cohortDefinitionId, covariateName, visitConceptId, timeWindow, conceptName, min:max)
  
  
  # Output file name
  saveName <- paste0("los_", cohortId, "_", abs(timeA), "_", abs(timeB))
  
  # Save results
  verboseSave(
    object = losTbl,
    saveName = saveName,
    saveLocation = outputFolder
  )
  
  invisible(losTbl)
}


# HCRU module -------------
executeHcruAnalysis <- function(con,
                                executionSettings,
                                analysisSettings) {
  
  # Get variables
  cdmDatabaseSchema <- executionSettings$cdmDatabaseSchema
  workDatabaseSchema <- executionSettings$workDatabaseSchema
  cohortTable <- executionSettings$cohortTable
  databaseId <- executionSettings$databaseName
  
  outputFolder <- fs::path(here::here("results"), databaseId, analysisSettings[[1]]$outputFolder) %>%
    fs::dir_create()
  
  
  # Target cohort ids
  cohortKey <- analysisSettings[[1]]$cohorts$targetCohorts
  cohortId <- cohortKey$targetId
  
  # Time windows
  timeA <- analysisSettings[[1]]$timeWindow$startDay
  timeB <- analysisSettings[[1]]$timeWindow$endDay
  
  
  # Job Log
  cli::cat_boxx("Building HCRU Analysis")
  cli::cat_line()
  tik <- Sys.time()
  cli::cat_bullet("Running HCRU at window: [",
                  crayon::green(timeA), " - ",
                  crayon::green(timeB), "]",
                  bullet = "info", bullet_col = "blue")
  cat_cohortId <- paste(cohortId, collapse = ", ")
  cli::cat_bullet("Building HCRU analysis for cohort ids:\n   ",crayon::green(cat_cohortId),
                  bullet = "info", bullet_col = "blue")
  
  
  # Create grid df for execution
  grid <- createGrid(cohortKey = cohortKey, 
                     timeA = timeA, 
                     timeB = timeB)
  
  # Run Length of Stay Analysis
  purrr::pmap_dfr(grid,
                  ~ lengthOfStayAnalysis(con = con,
                                         cohortDatabaseSchema = workDatabaseSchema,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         cohortTable = cohortTable,
                                         cohortId = ..2,
                                         timeA = ..3,
                                         timeB = ..4,
                                         outputFolder = outputFolder)
  )
  
  
  tok <- Sys.time()
  cli::cat_bullet("Execution Completed at: ", crayon::red(tok),
                  bullet = "info", bullet_col = "blue")
  tdif <- tok - tik
  tok_format <- paste(scales::label_number(0.01)(as.numeric(tdif)), attr(tdif, "units"))
  cli::cat_bullet("Execution took: ", crayon::red(tok_format),
                  bullet = "info", bullet_col = "blue")
  
  invisible(tok)
}
