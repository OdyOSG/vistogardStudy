# A. Meta Info -----------------------

# Task: Time To Covariate

source("analysis/private/_utilities.R")

# B. Functions ------------------------


# Time To Covariate -----------
timeToCovariate <- function(con,
                            cohortDatabaseSchema,
                            cohortTable,
                            cohortKey,
                            covariateKey,
                            database,
                            outputFolder) {
  
  cli::cat_rule("Calculate time to covariate")
  
  targetId <- cohortKey$targetId
  eventId <- covariateKey$covariateId
  
  
  # SQL to get cohort covariates 
  sql <- "
    SELECT target_cohort_id, covariate_cohort_id,
    MIN(timeTo) AS min,
    percentile_cont(0.10) WITHIN GROUP (ORDER BY timeTo) AS p10,
    percentile_cont(0.25) WITHIN GROUP (ORDER BY timeTo) AS p25,
    percentile_cont(0.50) WITHIN GROUP (ORDER BY timeTo) AS median,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY timeTo) AS p75,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY timeTo) AS p90,
    STDDEV(timeTo) as sd,
    MAX(timeTo) AS max
  FROM (
    SELECT
      t.cohort_definition_id AS target_cohort_id,
      e.cohort_definition_id AS covariate_cohort_id,
      DATEDIFF(day, t.cohort_start_date, e.cohort_start_date) as timeTo
    FROM (
      SELECT *
      FROM @cohortDatabaseSchema.@cohortTable
      WHERE cohort_definition_id IN (@targetId)
    ) t
    JOIN (
      SELECT *
      FROM @cohortDatabaseSchema.@cohortTable
      WHERE cohort_definition_id IN (@eventId)
    ) e
    ON t.subject_id = e.subject_id AND e.cohort_start_date >= t.cohort_start_date
    ) b
    GROUP BY target_cohort_id, covariate_cohort_id;
"
  
  # Render and translate sql
  cohortCovariateSql <- SqlRender::render(
    sql,
    cohortDatabaseSchema = cohortDatabaseSchema,
    cohortTable = cohortTable,
    targetId = targetId,
    eventId = eventId
  ) %>%
    SqlRender::translate(targetDialect = con@dbms)
  
  # Run query on connection
  tb <- DatabaseConnector::querySql(connection = con, sql = cohortCovariateSql)
  names(tb) <- tolower(names(tb))
  tb <- tb %>%
    dplyr::mutate(database = executionSettings$databaseName)
  
  # Save results
  verboseSave(
    object = tb,
    saveName = "timeTo_covariates",
    saveLocation = outputFolder
  )
  
  invisible(tb)
}


# Time to covariate module -------------


executeTimeToCovariate <- function(con,
                                   executionSettings,
                                   analysisSettings) {
  
  # Get variables
  cdmDatabaseSchema <- executionSettings$cdmDatabaseSchema
  workDatabaseSchema <- executionSettings$workDatabaseSchema
  cohortTable <- executionSettings$cohortTable
  databaseId <- executionSettings$databaseName
  
  outputFolder <- fs::path(here::here("results"), databaseId, analysisSettings[[1]]$outputFolder) %>%
    fs::dir_create()
  
  
  # Target and covariate cohort ids
  cohortKey <- analysisSettings[[1]]$cohorts$targetCohort
  covariateKey <- analysisSettings[[1]]$cohorts$covariateCohorts
  cohortId <- cohortKey$targetId
  covId <- covariateKey$covariateId
  
  # Time Windows
  timeA <- analysisSettings[[1]]$timeWindow$startDay
  timeB <- analysisSettings[[1]]$timeWindow$endDay

  
  # Job Log
  cli::cat_boxx("Building Time-To Covariates")
  cli::cat_line()
  
  tik <- Sys.time()
  
  cli::cat_bullet("Running Post-Index Analysis at window: [", crayon::green(timeA), " - ", crayon::green(timeB), "]",
                  bullet = "info", bullet_col = "blue")
  cat_cohortId <- paste(cohortId, collapse = ", ")
  cli::cat_bullet("Building time-to for cohort ids:\n   ",crayon::green(cat_cohortId),
                  bullet = "info", bullet_col = "blue")
  cat_cohortId <- paste(covId, collapse = ", ")
  cli::cat_bullet("Using covariate cohorts ids:\n   ", crayon::green(cat_cohortId),
                  bullet = "info", bullet_col = "blue")
    
  
    # Run time-to covariate analysis
    timeToCovariate(con = con,
                    cohortDatabaseSchema = workDatabaseSchema,
                    cohortTable = cohortTable,
                    cohortKey = cohortKey,
                    covariateKey = covariateKey,
                    database = databaseId,
                    outputFolder = outputFolder)

  
  tok <- Sys.time()
  cli::cat_bullet("Execution Completed at: ", crayon::red(tok),
                  bullet = "info", bullet_col = "blue")
  tdif <- tok - tik
  tok_format <- paste(scales::label_number(0.01)(as.numeric(tdif)), attr(tdif, "units"))
  cli::cat_bullet("Execution took: ", crayon::red(tok_format),
                  bullet = "info", bullet_col = "blue")
  
  invisible(tok)
}
