
rm(list = ls())

source("R/install_packages.R")
source("R/preprocessing.R")
source("R/tables.R")
source("R/utils.R")


### Change settings here ###
perfect_quiz <- FALSE



################################################################################
# Replicate Figure 7
################################################################################

# Preprocess the data
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv", perfect_quiz)

# Execute all scripts to get estimation and simulation results
# Refer to this function in R/utils.R for more details on the running order
estimation_and_simulation()


