# A. Meta Info -----------------------

# Task: Execution Settings
# Author: Martin Lavallee
# Date: 2023-04-12
# Description: The purpose of the _executionSettings.R script is to
# set the execution settings and initialize cohorts

# B. Functions ------------------------

getCohortManifest <- function(inputPath = here::here("cohortsToCreate")) {

  #get cohort file paths
  cohortFiles <- fs::dir_ls(inputPath, recurse = TRUE, type = "file", glob = "*.json")
  #get cohort names
  cohortNames <- fs::path_file(cohortFiles) %>%
    fs::path_ext_remove()
  #get cohort type
  cohortType <- fs::path_dir(cohortFiles) %>%
    basename() %>%
    gsub(".*_", "", .)

  #future addition of hash
  hash <- purrr::map(cohortFiles, ~readr::read_file(.x)) %>%
    purrr::map_chr(~digest::digest(.x, algo = "sha1")) %>%
    unname()

  #return tibble with info
  tb <- tibble::tibble(
    name = cohortNames,
    type = cohortType,
    hash = hash,
    file = cohortFiles %>% as.character()
  ) %>%
    dplyr::mutate(
      id = dplyr::row_number(), .before = 1
    )
  return(tb)
}


startSnowflakeSession <- function(con, executionSettings) {
  sql <- "
  ALTER SESSION SET JDBC_QUERY_RESULT_FORMAT='JSON';
    USE ROLE @user_role;
    USE SECONDARY ROLES ALL;
    USE DATABASE @write_database;
    USE SCHEMA @write_schema;
  "
  crd <- stringr::str_split_1(string = executionSettings$workDatabaseSchema, pattern = "\\.")

  sessionSql <- SqlRender::render(
    sql = sql,
    user_role = executionSettings$role,
    write_database = crd[1],
    write_schema = crd[2]
  ) %>%
    SqlRender::translate(targetDialect = con@dbms)

  DatabaseConnector::executeSql(connection = con, sql = sessionSql)
  cli::cat_line("Setting up Snowflake session")

  invisible(sessionSql)
}


readSettingsFile <- function(settingsFile) {

  tt <- yaml::read_yaml(file = settingsFile)

  # convert cohorts into dataframes
  for (i in seq_along(tt[[1]][[1]])) {
    tt[[1]][[1]][[i]] <- listToTibble(tt[[1]][[1]][[i]])
  }

  #convert unnamed lists into dataframes
  ss <- seq_along(tt[[1]])
  for (j in ss[-1]) {
    check <- is.list(tt[[1]][[j]]) && is.null(names(tt[[1]][[j]]))
    if (check) {
      tt[[1]][[j]] <- listToTibble(tt[[1]][[j]])
    } else {
      next
    }
  }

  return(tt)
}


listToTibble <- function(ll) {
  df <- do.call(rbind.data.frame, ll) |>
    tibble::as_tibble()
  return(df)
}


verboseSave <- function(object, saveName, saveLocation) {

  savePath <- fs::path(saveLocation, saveName, ext = "csv")
  readr::write_csv(object, file = savePath)
  cli::cat_line()
  cli::cat_bullet("Saved file ", crayon::green(basename(savePath)), " to:",
                  bullet = "info", bullet_col = "blue")
  cli::cat_bullet(crayon::cyan(saveLocation), bullet = "pointer", bullet_col = "yellow")
  cli::cat_line()
  invisible(savePath)
}


# Create data frame to run in purrr::map functions (three inputs)
createGrid <- function(cohortKey, timeA, timeB) {
  
  
  combos <- tidyr::expand_grid(cohortKey, timeA)
  
  repNo <- (nrow(cohortKey) * length(timeA))/length(timeB)
  
  combosAll <- combos %>%
    dplyr::mutate(timeB = rep(timeB, repNo))
  
  return(combosAll)
}


# Create data frame to run in purrr::map functions (four inputs)
createGrid2 <- function(cohortKey, covariateKey, timeA, timeB) {
  
  
  combos <- tidyr::expand_grid(cohortKey, covariateKey, timeA)
  
  repNo <- nrow(cohortKey) * nrow(covariateKey)
  
  combosAll <- combos %>%
    dplyr::mutate(timeB = rep(timeB, repNo))
  
  return(combosAll)
}



bindFiles <- function(inputPath,
                      database,
                      pattern = NULL)  {
  
  
  # List all csv files in folder
  filepath <- list.files(inputPath, full.names = TRUE, pattern = pattern, recursive = TRUE)
  
  # Read all csv files and save in list
  listed_files <- lapply(filepath, readr::read_csv, show_col_types = FALSE)
  
  # Bind all data frames of list
  binded_df <- dplyr::bind_rows(listed_files)
  
  ## Save output
  readr::write_csv(
    x = binded_df,
    file = file.path(here::here("report", paste0(pattern, ".csv"))),
    append = FALSE
  )
  
}


bindAndZipResults <- function(database) {
  
  resultsPath <- here::here("results", database)
  outputPath <- here::here("report") %>% 
    fs::dir_create()
  
  
  # 1. Cohort Manifest
  fileTypes <- c("cohortManifest")
  
  purrr::walk(fileTypes,
              ~bindFiles(inputPath = here::here(resultsPath, "01_buildCohorts"),
                         database = database,
                         pattern = ..1)
  )
  
  
  # 2. Cohort Diagnostics
  file.copy(here::here(resultsPath, "02_cohortDiagnostics", paste0("Results_", database, ".zip")), outputPath)
  
            
  # 3. Baseline Characteristics
  fileTypes <- c("conditions", "condition_chapters", "drugs", "continuous", "demographics", "cohort") %>%
    paste0("_baseline")
  
  purrr::walk(fileTypes,
                 ~bindFiles(inputPath = here::here(resultsPath, "03_baselineCharacteristics"),
                            database = database,
                            pattern = ..1)
  )
  
  
  # 4. Post-Index Characteristics
  fileTypes <- c("visits", "cohort") %>%
    paste0("_postIndex")
  
  purrr::walk(fileTypes,
              ~bindFiles(inputPath = here::here(resultsPath, "04_postIndexCharacteristics"),
                         database = database,
                         pattern = ..1)
  )
  
  
  # 5. HCRU Characteristics
  fileTypes <- c("los")
  
  purrr::walk(fileTypes,
              ~bindFiles(inputPath = here::here(resultsPath, "05_hcruCharacteristics"),
                         database = database,
                         pattern = ..1)
  )
  
  
  # 6. Time-To
  fileTypes <- c("timeTo")
  
  purrr::walk(fileTypes,
              ~bindFiles(inputPath = here::here(resultsPath, "06_timeTo"),
                         database = database,
                         pattern = ..1)
  )
  
  
  # 7. Incidence Analysis
  fileTypes <- c("incidence_analysis")
  
  purrr::walk(fileTypes,
              ~bindFiles(inputPath = here::here(resultsPath, "07_incidenceAnalysis"),
                         database = database,
                         pattern = ..1)
  )
  
  
  # Zip "report" folder
  files2zip <- dir(outputPath, full.names = TRUE)
  utils::zip(zipfile = 'reportFiles', files = files2zip)
  
}


