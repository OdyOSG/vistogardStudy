# A. Meta Info ----------------------

# Name: Build Cohorts

# B. Dependencies ----------------------

library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)

source("analysis/private/_utilities.R")

# Set database name
# <<<
configBlock <- "[database]"
# >>>


# C. Script ----------------------

bindAndZipResults(database = configBlock)
