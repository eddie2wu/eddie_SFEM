
rm(list = ls())

source("R/install_packages.R")
source("R/preprocessing.R")
source("R/utils.R")

# Preprocess the data
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv")

# Create dataframe for the estimation in MATLAB
strategy_selected = c("ad", "ac", "g", "tft", "wsls", "t2")
dfformatlab <- dfformatlab_special(data, strategies_selected = strategy_selected)























