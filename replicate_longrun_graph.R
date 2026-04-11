
rm(list = ls())

source("R/install_packages.R")
source("R/preprocessing.R")
source("R/tables.R")
source("R/utils.R")


### Change settings here ###
perfect_quiz <- TRUE
autoplayer <- TRUE


# Define var
sample = if (perfect_quiz) "perfect" else "full" 


################################################################################
# Replicate Figure 7
################################################################################

# Execute all scripts to get estimation and simulation results
# Refer to this function in R/utils.R for more details on the running order
estimation_and_simulation(autoplayer = autoplayer, sample = sample)


source("replicate_mean_median_CDF.R")





