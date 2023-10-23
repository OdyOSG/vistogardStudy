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

ll <- list(
  'postIndexPrevalence' = list(
    'cohorts' = list(
      'targetCohorts' = targetCohorts,
      'covariateCohorts' = covariateCohorts
    ),
    'timeWindow' = tibble::tibble(
      startDay = c(1L, 1L, 1L),
      endDay = c(7L, 30L, 183L)
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


## 4. Incidence analysis---------------------------

denomCohorts <- cohortManifest %>%
  dplyr::filter(type == "outcomes" | id %in% c(1)) %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id)

numerCohorts <- cohortManifest %>%
  dplyr::filter(type %in% c("drugs", "outcomes")) %>%
  dplyr::mutate(id = as.integer(id)) %>%
  dplyr::select(name, id) 


ll <- list(
  'incidenceAnalysis' = list(
    'cohorts' = list(
      'denominator' = denomCohorts,
      'numerator' = numerCohorts
    ),
    'incidenceSettings' = list(
      'cleanWindow' = 0L,
      'startWith' = 'start',
      'startOffset' = c(1L, 1L),
      'endsWith' = 'start',
      'endOffset' = c(7L, 30L)
    ),
    'outputFolder' = fs::path("06_incidenceAnalysis")
  )
)

write_yaml(ll, file = here::here("analysis/settings/incidenceAnalysis.yml"), column.major = FALSE)

