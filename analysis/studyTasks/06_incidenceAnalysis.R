# A. File Info -----------------------

# Name: Incidence Analysis

# B. Dependencies ----------------------

library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)

source("analysis/private/_utilities.R")
source("analysis/private/_incidenceAnalysis.R")


# C. Connection ----------------------

# Set connection Block
# <<<
configBlock <- "optum"
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
analysisSettings <- readSettingsFile(here::here("analysis/settings/incidenceAnalysis.yml"))


# E. Script --------------------

startSnowflakeSession(con, executionSettings)


## Get Baseline Covariates

executeIncidenceAnalysis(con = con,
                         executionSettings = executionSettings,
                         analysisSettings = analysisSettings)


# F. Session Info ------------------------
DatabaseConnector::disconnect(con)
