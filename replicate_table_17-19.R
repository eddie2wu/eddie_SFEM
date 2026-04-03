
rm(list = ls())

source("R/install_packages.R")
source("R/preprocessing.R")
source("R/tables.R")
source("R/utils.R")


### Change settings here ###
perfect_quiz <- FALSE



################################################################################
# Using six strategies to replicate table 17-19
################################################################################

# Preprocess the data
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv", perfect_quiz)

# Create dataframe for the estimation in MATLAB
strategy_selected = c("ad", "ac", "g", "tft", "wsls", "t2")
dfformatlab <- dfformatlab_special(data, strategies_selected = strategy_selected)

# Run MATLAB script, note this takes around 1 hour on 8 cores
run_matlab_script("est_part1_b_all_s.m")

# Replicate table
result_dir <- "scripts/raw/"
strategy_selected = c("AD", "AC", "G", "TFT", "WSLS", "T2")
match_list = list(NULL, "drop1qtr", "first5", "last5")
for (match_type in match_list) {
  generate_table7(file_count = 8, result_dir, parameter_names = c("gamma", strategy_selected), match_type = match_type)
}



################################################################################
# Using three strategies to replicate table 17-19
################################################################################

# Preprocess the data
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv", perfect_quiz)

# Create dataframe for the estimation in MATLAB
strategy_selected = c("ad", "ac", "g")
dfformatlab <- dfformatlab_special(data, strategies_selected = strategy_selected)

# Run MATLAB script, note this takes around 30 minutes on 8 cores
run_matlab_script("est_part1_b_all_s_substrg.m")

# Replicate table
result_dir <- "scripts/raw_substrg/"
strategy_selected = c("AD", "AC", "G")
match_list = list(NULL, "drop1qtr", "first5", "last5")
for (match_type in match_list) {
  generate_table7(file_count = 8, result_dir, output_file = "tex/results_table7_substrg.tex", parameter_names = c("gamma", strategy_selected), match_type = match_type)
}




