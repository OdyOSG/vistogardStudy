# Setup Credentials -------------
# This file setups the credential library for your study. The function establishes
# a config.yml file and creates a keyring for the study. Add your credentials
# into the keyring. Keep your database credentials handy before running this script.
# Ask your database administrator if you are unsure of your credentials.


# A) Depedendencies -------------

library(tidyverse, quietly = TRUE)
library(Ulysses)
library(keyring)


# B) Set Parameters ------------

configBlock <- ""      # Name of config block

database <- ""         # Name of the database in the config block

keyringPassword <- ""  # Password for the keyring


# C) Create Config.yml File -------------

## Check if file config.yml exists; if it doesn't create it by running Ulysses::makeConfig(block = configBlock, database = database)
checkConfig()


# D) Setup Keyring -------------

keyringName <- "vistogardStudy" # Name of the keyring (DO NOT EDIT)

## Set keyring
setStudyKeyring(keyringName = keyringName,
                keyringPassword = keyringPassword)

## Set credential keys in keyring
setMultipleCredentials(
  cred = defaultCredentials(),
  db = configBlock,
  keyringName = keyringName,
  keyringPassword = keyringPassword,
  forceCheck = TRUE
)

## If you'd like to edit a single credential, uncomment and run the command below by changing the 'cred' argument (Credential names can be found in the config.yml file)
# setCredential(cred = "password",
#               db = configBlock,
#               keyringName = keyringName,
#               keyringPassword = keyringPassword,
#               forceCheck = TRUE
# )


# E) Check (Optional) -------------

## Test connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = config::get("dbms", config = configBlock),
  user = config::get("user", config = configBlock),
  password = config::get("password", config = configBlock),
  connectionString = config::get("connectionString", config = configBlock)
)
connectionDetails$dbms


# G) Close out -------------

sessioninfo::session_info()
rm(list=ls())
