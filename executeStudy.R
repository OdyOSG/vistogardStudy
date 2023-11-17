# A. File Info ----------------

# Name: Execute Study
# Author: Martin Lavallee
# Date: 2023-09-12
# Description: The purpose of executeStudy.R is to run all the tasks required for the study.


# B. Dependencies ----------------

## Load functions
source(here::here("analysis/private/_executeStudy.R"))


# C. Variables ----------------

## Edit to respective config block (database)
configBlock <- ""

## Provide path to tasks
studyTaskFolder <- here::here("analysis/studyTasks")
studyTaskFiles <- fs::dir_ls(studyTaskFolder, type = "file")


# D. Execute ----------------

## Task 1: Build Cohorts
runStudyTask(file = studyTaskFiles[1], configBlock = configBlock)

## Task 2: Run Cohort Diagnostics
runStudyTask(file = studyTaskFiles[2], configBlock = configBlock)

## Task 3: Run Baseline Characteristics 
runStudyTask(file = studyTaskFiles[3], configBlock = configBlock)

## Task 4: Run Post-Index Characteristics
runStudyTask(file = studyTaskFiles[4], configBlock = configBlock)

## Task 5: Run HCRU Analysis
runStudyTask(file = studyTaskFiles[5], configBlock = configBlock)

## Task 6: Run Time-To Analysis
runStudyTask(file = studyTaskFiles[6], configBlock = configBlock)

## Task 7: Run Incidence Analysis
runStudyTask(file = studyTaskFiles[7], configBlock = configBlock)

## Task 8: Share Results
runStudyTask(file = studyTaskFiles[8], configBlock = configBlock)
