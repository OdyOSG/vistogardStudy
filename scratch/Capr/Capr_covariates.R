# Capr_covariates.R

# A. File Info -----------------------

# Study: vistogard
# Name: Capr Script for covariates
# Author: Martin Lavallee
# Date: 10/25/2023
# Description: The purpose of this Capr script is to develop 
# create the covariate cohorts


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

covList <- list(
  
  'all_cancer' = cs(
    descendants(
      439392, # primary malignancy,
      exclude(
        4112752, #Basal cell carcinoma of skin
        4111921 #Squamous cell carcinoma of skin
      )
    ),
    name = "all cancers except non-melenoma skin"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'breast_cancer' = cs(
    descendants(
      4112853 # breast cancer
    ),
    name = "breast cancer"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  
  'pancreas_cancer' = cs(
    descendants(
      4180793 # pancreas cancer
    ),
    name = "pancreas cance"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'gastric_cancer' = cs(
    descendants(
      443387 # stomach cancer
    ),
    name = "gastric cancer"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'head_neck_cancer' = cs(
    descendants(
      4114222 # head and neck cancer
    ),
    name = "head and neck cancer"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  
  'cervix_cancer' = cs(
    descendants(
      198984 # cervix cancer
    ),
    name = "cervical cancer"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'colorectal_cancer' = cs(
    descendants(
      4180790, # colon cancer
      443390 # rectum cancer
    ),
    name = "colorectal cancer"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'bladder_cancer' = cs(
    descendants(
      197508 # bladder cancer
    ),
    name = "bladder cancer"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  
  'esophagial_cancer' = cs(
    descendants(
      4181343 # esophagus cancer
    ),
    name = "esophagial cancer"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  
  'renal_failure' = cs(
    descendants(
      192359 # renal failure
    ),
    name = "renal failure"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  
  'chronic_kidney_disease' = cs(
    descendants(
      46271022 # ckd
    ),
    name = "ckd"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  
  'coronary_artery_disease' = cs(
    descendants(
      43531588, # Angina associated with type 2 diabetes mellitus
      317576 # Coronary arteriosclerosis
    ),
    name = "cad"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'atrial_fibrillation' = cs(
    descendants(
      313217, # afib
      314665 # atrial flutter
    ),
    name = "afib"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'heart_failure' = cs(
    descendants(
      316139, # hf
      exclude(315295) # congestive rheumatic heart failure
    ),
    name = "hf"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'cardiomyopathy' = cs(
    descendants(
      321319 # Cardiomyopathy
    ),
    name = "Cardiomyopathy"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'myocardial_infarction' = cs(
    descendants(
      4329847, # mi
      exclude(314666) # old mi
    ),
    name = "myocardial infarction"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'type_2_diabetes' = cs(
    descendants(
      exclude(
        40484648, 201254, 195771, 435216, 4058243, 761051
      ),
      443238, # diabetic - poor control
      201820, # diabetes mellitus
      442793 # complication due to dm
    ),
    name = "t2d"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema),
  
  'hyperthyroidism' = cs(
    descendants(
      4142479 # hyperthyroidism
    ),
    name = "hyperthyroidism"
  ) %>%
    getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema)
  
)


# F. Cohort Definition ----------------

covariate_cohorts <- function(cs, name, path){
  
  cd <- cohort(
    entry = entry(
      conditionOccurrence(cs)
    )
  )
  save_path <- fs::path(path, name, ext = "json")
  Capr::writeCohort(cd, path = save_path)
  invisible(cd)
}


purrr::walk2(
  covList,
  names(covList),
  ~covariate_cohorts(
    cs = .x,
    name = .y,
    path = here::here("cohortsToCreate/02_covariates"))
)
