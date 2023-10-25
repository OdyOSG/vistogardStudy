# Capr_drugUsage.R

# A. File Info -----------------------

# Study: afibBayerStudy
# Name: Capr Script for drugUsage
# Author: Carina
# Date: [Add Date]
# Description: The purpose of this Capr script is to develop xxx cohorts....

# B. Dependencies ----------------------

## include R libraries
library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)
library(Capr)

# C. Connection ----------------------

# set connection Block
configBlock <- "[add block]"

# provide connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = config::get("dbms",config = configBlock),
  user = config::get("user",config = configBlock),
  password = config::get("password", config = configBlock),
  connectionString = config::get("connectionString", config = configBlock)
)

# connect to database
con <- DatabaseConnector::connect(connectionDetails)
withr::defer(expr = DatabaseConnector::disconnect(con), envir = parent.frame())  #close on exit


# D. Variables -----------------------

### Administrative Variables
executionSettings <- config::get(config = configBlock) %>%
  purrr::discard_at(c("dbms", "user", "password", "connectionString"))


cohortFolder <- "drugUsage" %>% #if this is the target cohort do not make new folder
  Ulysses::addCohortFolder()

cohortFolder <- here::here("cohortsToCreate/06_drugUsage")

# E. Concept Sets --------------------


afibDrugs <- list(
  'anticoagulatnts' = cs(
    descendants(
      21600962 #anticoagulants
    ),
    name = "anticoagulants"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),

  'oralAntiarhytmics' = cs(
    descendants(
      40102898,40102900,21056256,35160346,21105365,
      40830578,36272029,40725226,40007699,21066450,
      21095891,40163615,43202064,35866619,21096371,
      21057096,40076564,40076568,40084486,45775830,
      40044850,42479230,21101384,40035361,40035354,
      40035359,40035357,21032611,36880835
    ),
    name = "oral Antiarhytmics"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),

  'rateControl' = cs(
    descendants(
      1307863,1314577,1307046,35197852,19063575,1328165,1326303,19026180,1346823,1338005,1314002
    ),
    exclude(
      descendants(
        35158436,41049024,40862036,42480742,40010619,21092214,
        41236547,41298484,41205625,40033837,36894438,
        40986482,44094630,40059515,43036128,40061831,
        36881824,42479796,40148216,42482485,42479694,40141461)
      ),
    name = "rate control drugs"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema)
)


# F. Cohort Definition ----------------


afibDrugCohortTemplate <- function(conceptSet, name, cohortFolder) {

  # build Cohort definition
  cd <- cohort(
    entry = entry(
      drugExposure(conceptSet = conceptSet),
      observationWindow = continuousObservation(priorDays = 365, postDays = 0),
      primaryCriteriaLimit = "All"
    ),
    exit = exit(
      endStrategy = drugExit(conceptSet = conceptSet,
                             persistenceWindow = 30L)
    ),
    era = era(eraDays = 30L)
  )
  txt <- glue::glue("Writing cohort definition {crayon::green(name)} to {crayon::cyan(cohortFolder)}")
  cli::cat_bullet(txt, bullet = "info", bullet_col = "blue")
  writeCohort(cd, path = fs::path(cohortFolder, name, ext = "json"))
  invisible(cd)
}

purrr::walk2(afibDrugs, names(afibDrugs),
             ~afibDrugCohortTemplate(
               conceptSet = .x,
               name = .y,
               cohortFolder = cohortFolder)
)


# F. Session Info ------------------------

sessioninfo::session_info()
rm(list = ls())
withr::deferred_run()
