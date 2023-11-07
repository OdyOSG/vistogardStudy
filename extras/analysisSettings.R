# Create Analysis settings ----------------

# A. File Info -----------------------

# Name: Analysis Settings

# B. Dependencies ----------------------

library(tidyverse, quietly = TRUE)
library(DatabaseConnector)
library(yaml)

source("analysis/private/_utilities.R")


# C. Script --------------------

cohortManifest <- getCohortManifest()


## 1. Baseline characteristics------------------

targetCohorts <- cohortManifest %>%
  dplyr::filter(type == "target") %>%
  dplyr::select(name, id) %>%
  dplyr::rename(targetId = id,
                targetName = name)

covariateCohorts <- cohortManifest %>%
  dplyr::filter(type == "covariates") %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id) %>%
  dplyr::rename(covariateId = id,
                covariateName = name)


ll <- list(
  'baselineCharacteristics' = list(
    'cohorts' = list(
      'targetCohorts' = targetCohorts,
      'covariateCohorts' = covariateCohorts
    ),
    'timeWindow' = tibble::tibble(
      startDay = c(-365L), 
      endDay = c(-1L)
      ),
    'outputFolder' = fs::path("03_baselineCharacteristics")
  )
)

write_yaml(ll, file = here::here("analysis/settings/baselineCharacteristics.yml"), column.major = FALSE)


## 2. Post-index Utilization----------------------

outcomeCohorts <- cohortManifest %>%
  dplyr::filter(type == "outcomes") %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id) %>%
  dplyr::rename(outcomeId = id,
                outcomeName = name)

ll <- list(
  'postIndexPrevalence' = list(
    'cohorts' = list(
      'targetCohorts' = targetCohorts,
      'outcomeCohorts' = outcomeCohorts
    ),
    'timeWindow' = tibble::tibble(
      startDay = c(0L, 1L, 1L, 1L),
      endDay = c(0L, 7L, 30L, 90L)
    ),
    'outputFolder' = fs::path("04_postIndexCharacteristics")
  )
)

write_yaml(ll, file = here::here("analysis/settings/postIndexCharacteristics.yml"), column.major = FALSE)


## 3. HCRU analysis---------------------------

ll <- list(
  'hcruAnalysis' = list(
    'cohorts' = list(
      'targetCohorts' = targetCohorts,
      'covariateCohorts' = covariateCohorts
    ),
    'timeWindow' = tibble::tibble(
      startDay = c(1L, 1L, 1L),
      endDay = c(7L, 30L, 183L)
    ),
    'outputFolder' = fs::path("05_hcruCharacteristics")
  )
)

write_yaml(ll, file = here::here("analysis/settings/hcruCharacteristics.yml"), column.major = FALSE)


## 4. Time-to analysis---------------------------

targetCohorts <- cohortManifest %>%
  dplyr::filter(type == "target" & id == 3L) %>%
  dplyr::select(name, id) %>%
  dplyr::rename(targetId = id,
                targetName = name)

covariateCohorts <- cohortManifest %>%
  dplyr::filter(type == "target" & id == 2L) %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id) %>%
  dplyr::rename(covariateId = id,
                covariateName = name)

ll <- list(
  'hcruAnalysis' = list(
    'cohorts' = list(
      'targetCohorts' = targetCohorts,
      'covariateCohorts' = covariateCohorts    
    ),
    'outputFolder' = fs::path("05_hcruCharacteristics")
  )
)

write_yaml(ll, file = here::here("analysis/settings/timeToAnalysis.yml"), column.major = FALSE)


## 5. Incidence analysis---------------------------


### Analysis: Numerator cohort 2

denomCohorts <- cohortManifest %>%
  dplyr::filter(id %in% c(1)) %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id)

numerCohorts <- cohortManifest %>%
  dplyr::filter(id %in% c(2)) %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id) 


ll1 <- list(
  'incidenceAnalysis' = list(
    'cohorts' = list(
      'denominator' = denomCohorts,
      'numerator' = numerCohorts
    ),
    'incidenceSettings' = list(
      'cleanWindow' = 0L,
      'startWith' = 'start',
      'startOffset' = c(0L, 0L),
      'endsWith' = 'start',
      'endOffset' = c(7L, 14L)
    ),
    'outputFolder' = fs::path("06_incidenceAnalysis/analysis1")
  )
)

write_yaml(ll1, file = here::here("analysis/settings/incidenceAnalysis1.yml"), column.major = FALSE)


### Analysis: Numerator cohort 3

denomCohorts <- cohortManifest %>%
  dplyr::filter(id %in% c(2)) %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id)

numerCohorts <- cohortManifest %>%
  dplyr::filter(id %in% c(3)) %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id) 


ll2 <- list(
  'incidenceAnalysis' = list(
    'cohorts' = list(
      'denominator' = denomCohorts,
      'numerator' = numerCohorts
    ),
    'incidenceSettings' = list(
      'cleanWindow' = 0L,
      'startWith' = 'start',
      'startOffset' = c(0L, 4L, 0L),
      'endsWith' = 'start',
      'endOffset' = c(4L, 9999L, 9999L)
    ),
    'outputFolder' = fs::path("06_incidenceAnalysis/analysis2")
  )
)

write_yaml(ll2, file = here::here("analysis/settings/incidenceAnalysis2.yml"), column.major = FALSE)

