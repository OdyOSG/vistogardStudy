# Capr_outcomes.R

# A. File Info -----------------------

# Study: vistogard
# Name: Capr Script for outcomes
# Author: Martin Lavallee
# Date: 10/25/2023
# Description: The purpose of this Capr script is to develop 
# create the outcome cohorts


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

# D. Variables -----------------------

### Administrative Variables
executionSettings <- config::get(config = configBlock) %>%
  purrr::discard_at(c("dbms", "user", "password", "connectionString"))

# specify cohort folder
cohortFolder <- fs::path(here::here(), "cohortsToCreate/01_target")

# E. Concept Sets --------------------

procList <- list(
  

  'intubation' = cs(
    descendants(
      4202832, # intubation
      2106469 # Intubation, endotracheal, emergency procedure
    ),
    name = "intubation"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  
  'blood_transfusion' = cs(
    descendants(
      2108119 # Transfusion, blood or blood components
    ),
    name = "blood transfusion"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'ventilation_management' = cs(
    descendants(
      45887795 # Ventilator Management
    ),
    name = "ventilation management"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'cardiac_assist' = cs(
    descendants(
      
      45888564 # Cardiac Assist Procedures
    ),
    name = "Cardiac Assist Procedures"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema)
  
  
)


# F. Cohort Definition ----------------

proc_cohorts <- function(cs, name, path){
  
  cd <- cohort(
    entry = entry(
      procedure(cs)
    )
  )
  save_path <- fs::path(path, name, ext = "json")
  Capr::writeCohort(cd, path = save_path)
  invisible(cd)
}


purrr::walk2(
  procList,
  names(procList),
  ~proc_cohorts(
    cs = .x,
    name = .y,
    path = here::here("cohortsToCreate/03_outcomes"))
)
