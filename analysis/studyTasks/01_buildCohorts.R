# A. File Info -----------------------

# Name: Build Cohorts


# B. Dependencies ----------------------

## Load libraries and scripts
library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)
source("analysis/private/_utilities.R")
source("analysis/private/_buildCohorts.R")
source("analysis/private/_buildStrata.R")


# C. Connection ----------------------

## Set connection block
# <<<
configBlock <- "[database]"
# >>>

## Provide connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = config::get("dbms", config = configBlock),
  user = config::get("user", config = configBlock),
  password = config::get("password", config = configBlock),
  connectionString = config::get("connectionString", config = configBlock)
)

## Connect to database
con <- DatabaseConnector::connect(connectionDetails)


# D. Study Variables -----------------------

## Administrative Variables
executionSettings <- config::get(config = configBlock) %>%
  purrr::discard_at(c("dbms", "user", "password", "connectionString"))

outputFolder <- here::here("results") %>%
  fs::path(executionSettings$databaseName, "01_buildCohorts") %>%
  fs::dir_create()

## Add study variables or load from settings
cohortManifest <- getCohortManifest()

## Analysis Settings
analysisSettings <- readSettingsFile(here::here("analysis/settings/strataSettings.yml"))


# E. Script --------------------

### RUN ONCE - Initialize cohort table ###
initializeCohortTables(executionSettings = executionSettings, con = con)


## Build cohorts

generatedCohorts <- generateCohorts(
  executionSettings = executionSettings,
  con = con,
  cohortManifest = cohortManifest,
  outputFolder = outputFolder
)


## Build Stratas

buildStrata(con = con,
            executionSettings = executionSettings,
            analysisSettings = analysisSettings)


# F. Session Info ------------------------
DatabaseConnector::disconnect(con)
