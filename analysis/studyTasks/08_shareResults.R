# A. File Info ----------------------

# Name: Share Results


# B. Dependencies ----------------------

## Load libraries and scripts
library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(config)
source("analysis/private/_utilities.R")


## Set connection block
# <<<
configBlock <- "[database]"
# >>>


# C. Script ----------------------

bindAndZipResults(database = configBlock)
