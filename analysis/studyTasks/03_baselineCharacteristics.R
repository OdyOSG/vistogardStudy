# A. File Info -----------------------

# Name: Baseline Characteristics

# B. Dependencies ----------------------

library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)

source("analysis/private/_utilities.R")
source("analysis/private/_conceptPrevalence.R")
source("analysis/private/_conditionRollup.R")

# C. Connection ----------------------

# Set connection Block
# <<<
configBlock <- "[database]"
# >>>

# Provide connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = config::get("dbms",config = configBlock),
  user = config::get("user",config = configBlock),
  password = config::get("password", config = configBlock),
  connectionString = config::get("connectionString", config = configBlock)
)

# Connect to database
con <- DatabaseConnector::connect(connectionDetails)


# D. Variables -----------------------

### Administrative Variables
executionSettings <- config::get(config = configBlock) %>%
  purrr::discard_at(c("dbms", "user", "password", "connectionString"))

### Analysis Settings
analysisSettings <- readSettingsFile(here::here("analysis/settings/baselineCharacteristics.yml"))


# E. Script --------------------

# Run concept characterization

executeConceptCharacterization(con = con,
                               type = "baseline",
                               runDrugs = TRUE,
                               runConditions = TRUE,
                               runDemographics = TRUE,
                               runContinuous = TRUE,
                               runCohorts = TRUE,
                               executionSettings = executionSettings,
                               analysisSettings = analysisSettings)


# Run ICD chapters rollup

executeConditionRollup(con = con,
                       type = "baseline",
                       executionSettings = executionSettings,
                       analysisSettings = analysisSettings)


# F. Session Info ------------------------
DatabaseConnector::disconnect(con)
