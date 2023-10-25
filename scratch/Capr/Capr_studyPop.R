# Capr_studyPop.R

# A. File Info -----------------------

# Study: vistogard
# Name: Capr Script for study pop
# Author: Martin Lavallee
# Date: 10/25/2023
# Description: The purpose of this Capr script is to develop 
# create the study population cohorts


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


## 5-FU --------------
fu <- cs(
  descendants(
    955632, # fluorouracil
    1337620 # capecitabine
  ),
  name = "5-FU or capecitabine"
) %>%
  getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema)


## Cancer -----------------
cancer <- cs(
  descendants(
    439392, # primary malignancy,
    exclude(
      4112752, #Basal cell carcinoma of skin
      4111921 #Squamous cell carcinoma of skin
    )
  ),
  name = "Cancer"
) %>%
getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema)

## Hospitalization ---------------
hosp <- cs(
  descendants(
    9201, # inpatient visit
    262 # inpatient or ER
  ),
  name = "Inpatient Visit"
) %>%
  getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema)


## Vistogard ----------------
vistogard <- cs(
  descendants(
    46287389 #uridine triacetate
  ),
  name = "Vistogard"
) %>%
  getConceptSetDetails(con = con, vocabularyDatabaseSchema = executionSettings$vocabDatabaseSchema)

# F. Cohort Definition ----------------

## Cohort 1 Patients exposed to 5FU ---------------

Cohort1 <- cohort(
  entry = entry(
    drugExposure(fu,
                 age(gte(18L))),
    observationWindow = continuousObservation(priorDays = 365),
    primaryCriteriaLimit = "First"
  ),
  attrition = attrition(
    'cancerDx' = withAll(
      atLeast(1,
              query = conditionOccurrence(cancer),
              aperture = duringInterval(
                startWindow = eventStarts(a = -Inf, b = -1, index = "startDate")
              )
      )
    )
  ),
  exit = exit(
    endStrategy = observationExit()
  )
)

writeCohort(Cohort1, path = fs::path(cohortFolder, "patients_exposed_5fu", ext = "json"))


## Cohort 2 Patients experiencing toxicity ---------------

Cohort2 <- cohort(
  entry = entry(
    visit(hosp,
          age(gte(18L)),
          nestedWithAll(
            atLeast(1,
                     drugExposure(fu),
                     duringInterval(startWindow = eventStarts(a = 0, b = Inf, index = "startDate"),
                                    endWindow = eventStarts(a = -Inf, b = 0, index = "endDate")))
          )
    ),
    observationWindow = continuousObservation(priorDays = 365),
    primaryCriteriaLimit = "First"
  ),
  attrition = attrition(
    'cancerDx' = withAll(
      atLeast(1,
              query = conditionOccurrence(cancer),
              aperture = duringInterval(
                startWindow = eventStarts(a = -Inf, b = -1, index = "startDate")
              )
      )
    )
  ),
  exit = exit(
    endStrategy = observationExit()
  )
)

writeCohort(Cohort2, path = fs::path(cohortFolder, "patients_toxicity_5fu", ext = "json"))

## Cohort 3 Patients on vistogard -------------------------

Cohort3 <- cohort(
  entry = entry(
    drugExposure(vistogard,
                 age(gte(18L))),
    observationWindow = continuousObservation(priorDays = 365),
    primaryCriteriaLimit = "First"
  ),
  attrition = attrition(
    'cancerDx' = withAll(
      atLeast(1,
              query = conditionOccurrence(cancer),
              aperture = duringInterval(
                startWindow = eventStarts(a = -Inf, b = -1, index = "startDate")
              )
      )
    )
  ),
  exit = exit(
    endStrategy = observationExit()
  )
)

writeCohort(Cohort3, path = fs::path(cohortFolder, "patients_exposed_vistogard", ext = "json"))

# F. Clean up ------------------------

DatabaseConnector::disconnect(con)
rm(list = ls())
