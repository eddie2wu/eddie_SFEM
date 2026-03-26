
rm(list = ls())

source("R/install_packages.R")
source("R/preprocessing.R")
source("R/tables.R")
source("R/utils.R")

################################################################################
# Using six strategies to replicate table 17-19
################################################################################

# Preprocess the data
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv")

# Create dataframe for the estimation in MATLAB
strategy_selected = c("ad", "ac", "g", "tft", "wsls", "t2")
dfformatlab <- dfformatlab_special(data, strategies_selected = strategy_selected)

# Run MATLAB script, note this takes around 30 minutes on 8 cores
run_matlab_script("est_part1_b_all_s.m")

# Replicate table
strategy_selected = c("AD", "AC", "G", "TFT", "WSLS", "T2")
generate_table7(file_count = 8, parameter_names = c("gamma", strategy_selected))
generate_table7(file_count = 8, parameter_names = c("gamma", strategy_selected), match_type = "first5")
generate_table7(file_count = 8, parameter_names = c("gamma", strategy_selected), match_type = "last5")



################################################################################
# Using three strategies to replicate table 17-19
################################################################################

# Preprocess the data
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv")

# Create dataframe for the estimation in MATLAB
strategy_selected = c("ad", "ac", "g")
dfformatlab <- dfformatlab_special(data, strategies_selected = strategy_selected)

# Run MATLAB script, note this takes around 30 minutes on 8 cores
run_matlab_script("est_part1_b_all_s_substrg.m")

# Replicate table
strategy_selected = c("AD", "AC", "G")
generate_table7(file_count = 8, output_file = "tex/results_table7_substrg.tex", parameter_names = c("gamma", strategy_selected))
generate_table7(file_count = 8, output_file = "tex/results_table7_substrg.tex", parameter_names = c("gamma", strategy_selected), match_type = "first5")
generate_table7(file_count = 8, output_file = "tex/results_table7_substrg.tex", parameter_names = c("gamma", strategy_selected), match_type = "last5")









