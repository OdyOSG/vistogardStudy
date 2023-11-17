# How to run Vistogard study

## Setup Study

### Download Zip

To avoid using git to leverage this study, the easiest way to access the study code is via a zip file. Instructions for downloading the zip file are below:

1)  Navigate to the [github repo website](https://github.com/OdyOSG/vistogardStudy).
2)  Select the green code button revealing a dropdown menu.
3)  Select *Download Zip*.
4)  Unzip the folder on your local computer that is easily accessible within R Studio.
5)  Open the unzipped folder and open `vistogardStudy.Rproj` with RStudio.

### Setup R Environment

#### Using `renv`

This study uses [`renv`](https://rstudio.github.io/renv/articles/renv.html) to reproduce the R environment to execute the study. The study code maintains a `renv.lock` file in the main branch of the repository. To activate the R dependencies through `renv` run the following command:

``` r
renv::restore()
```

#### Troubleshooting `renv`

Sometimes there are errors with the package installation via `renv`. If you encounter an error with a package try removing it from the `renv.lock` file and restore again. To remove a package from the lock file find the header of the package and delete all corresponding lines. Once you are able to get the remaining packages to install, manually install the package using one of the options below:

``` r

# Installing an R package from CRAN ------------

## Installing latest version of R package on CRAN
install.packages("ggplot2")

## Installing archived version of R package on CRAN
packageurl <- "http://cran.r-project.org/src/contrib/Archive/ggplot2/ggplot2_0.9.1.tar.gz"
install.packages(packageurl, repos=NULL, type="source")

# Installing an R package from Github -----------------

# Installing current version of R package from github
install.packages("remotes") # note you may also work devtools
remotes::install_github("ohdsi/FeatureExtraction")

# Installing develop version of R package from github
remotes::install_github("ohdsi/Ulysses", ref = "develop")

# Installing old version of R package from github
remotes::install_github("ohdsi/CohortGenerator", ref = "v0.7.0")
```

If there are any additional issues with the `renv` lock file, please file an [issue](https://github.com/OdyOSG/vistogardStudy/issues) in Github.

#### Conflicts

Some organizational IT setups pose conflicts with `renv`. One example is if your organization uses Broadsea Docker. If you are aware that your OHDSI environment will conflict with `renv`, deactivate it by running `renv::deactivate()` in the active vistogard.RProj. Also, delete the renv folder in your project directory. Review the list of R packages required to run the study in the **Technical Requirements** tab of the study hub and install manually.

It is **highly recommended** you stick with the `renv` snapshot as this is the easiest way to reproduce the study execution environment. Please only deactivate the lock file if it is a last resort.

### Load Execution Credentials

This study uses `keyring` and `config` to mask and query database credentials needed for execution. The study will help load these credentials using file `extras/KeyringSetup.R`.

#### Required Credentials

Data nodes executing this study require the following credentials:

1)  **dbms** - The name of the dbms you are using (redshift, postgresql, snowflake, etc.)
2)  **user** - The username credential used to connect to the OMOP database
3)  **password** - The password credential used to connect to the OMOP database
4)  **connectionString** - A composed string that establishes the connection to the OMOP database. An example of a connection string would be *jdbc:dbms://host-url.com:port/database_name*.
5)  **cdmDatabaseSchema** - The database and schema used to access the OMOP CDM data. Note that this credential may be separated by a dot to indicate the database and schema, which tends to be the case in SQL Server. For example: *our_db.our_cdm*.
6)  **vocabDatabaseSchema** - The database and schema used to access the vocabulary tables. Note this is typically the same as cdmDatabaseSchema.
7)  **workDatabaseSchema** - The database and schema where the user has read/write access. This schema is where we create the table used to enumerate the cohort definitions.

It is recommended that you write these credentials down in a text file to make it easier to load into the credential manager for the study.

#### Loading Credentials

1)  Open the file in the study names `extras/KeyringSetup.R`.
2)  On L17:19 place a name for your config block and the database. The configBlock name can be an abbreviation for the database. For example:

``` r
configBlock <- "synpuf"
database <- "synpuf_110k"
```

3)  One at a time run each line in the script and follow any prompts

-   L27 asks you to build a new config.yml file which can be done by running `Ulysses::makeConfig(block = configBlock, database = database)`. Running this function will open a new file.
-   L39 will setup all the credentials for the study. A prompt will appear asking to input credentials; using your text file add your credentials into the prompt. Review the credentials once you are done.

#### Troubleshooting

If you have a problem with the keyring, please post an [issue](https://github.com/OdyOSG/vistogardStudy/issues) in the study repository. Otherwise you can avoid the keyring api by hard-coding your credentials to the `config.yml` file as shown in the example:

``` yml
db: # replace with an acronym for your database (no underscore)
databaseName: db_ehr # replace with the name of your database
dbms: <your_dbms>
user:  <your_user>
password:  <your_pass>
connectionString: <your_connectionString>
cdmDatabaseSchema:  <your_ cdmDatabaseSchema>
vocabDatabaseSchema:  <your_ vocabDatabaseSchema>
workDatabaseSchema: <your_ workDatabaseSchema>
cohortTable: vistogard_<databaseName>
```

## Run Study

### Execution Script

Running all tasks sequentially can be done using the `executeStudy.R` file. Replace L18 with the configBlock (database) of choice and run the script.

### Study Tasks

Once your study is setup you are ready to run the Vistogard study. The Vistogard study contains six analytical tasks:

1)  **Build Cohorts** - Creates a cohort table and generates cohort counts from the Circe json files in the cohortsToCreate folder
2)  **Cohort Diagnostics** - Review of the Vistogard target cohorts definitions
3)  **Baseline Characteristics** - Generates prevalence of demographics and comorbidities at baseline
4)  **Post-Index Characteristics** - Generates drug and condition prevalence post-index
5)  **HCRU Analysis** - Generates length of stay analysis
6)  **Time-to Analysis** - Generates time-to Vistogard and next chemotherapy analysis
7)  **Incidence Analysis** - Generates incidence analysis
8)  **Share Results** - Binds and zips result files together

Each task will output to the `results` folder. **Note** that the first task *buildCohorts* is required to run any additional analytical task (base dependency).
