# A. File Info -----------------------

# Name: Post-Index Characteristics


# B. Dependencies ----------------------

## Load libraries and scripts
library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)
source("analysis/private/_utilities.R")
source("analysis/private/_conceptPrevalence.R")
source("analysis/private/_conditionRollup.R")


# C. Connection ----------------------

## Set connection block
# <<<
configBlock <- "[database]"
# >>>

## Provide connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = config::get("dbms",config = configBlock),
  user = config::get("user",config = configBlock),
  password = config::get("password", config = configBlock),
  connectionString = config::get("connectionString", config = configBlock)
)

## Connect to database
con <- DatabaseConnector::connect(connectionDetails)


# D. Variables -----------------------

## Administrative Variables
executionSettings <- config::get(config = configBlock) %>%
  purrr::discard_at(c("dbms", "user", "password", "connectionString"))

## Analysis Settings
analysisSettings <- readSettingsFile(here::here("analysis/settings/postIndexCharacteristics.yml"))


# E. Script --------------------

## Run concept characterization

executeConceptCharacterization(con = con,
                               type = "postIndex",
                               runVisits = TRUE,
                               runCohorts = TRUE,
                               executionSettings = executionSettings,
                               analysisSettings = analysisSettings)


# F. Session Info ------------------------
DatabaseConnector::disconnect(con)
