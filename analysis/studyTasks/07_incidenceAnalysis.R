# A. File Info -----------------------

# Name: Incidence Analysis


# B. Dependencies ----------------------

## Load libraries and scripts
library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)
source("analysis/private/_utilities.R")
source("analysis/private/_incidenceAnalysis.R")


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
analysisSettings1 <- readSettingsFile(here::here("analysis/settings/incidenceAnalysis1.yml"))
analysisSettings2 <- readSettingsFile(here::here("analysis/settings/incidenceAnalysis2.yml"))


# E. Script --------------------

## Run Incidence Analysis

executeIncidenceAnalysis(con = con,
                         executionSettings = executionSettings,
                         analysisSettings = analysisSettings1)

executeIncidenceAnalysis(con = con,
                         executionSettings = executionSettings,
                         analysisSettings = analysisSettings2)


# F. Session Info ------------------------

DatabaseConnector::disconnect(con)
