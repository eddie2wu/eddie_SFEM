rm(list = ls())

source("R/install_packages.R")
source("R/preprocessing.R")
source("R/tables.R")
source("R/utils.R")

################################################################################
# Total number of results combinations:
# 2 samples:          perfect quiz or full sample
# 2 strategy sets:    6 or 3
# 4 supergame sets:   full, drop1qtr, first5, last5
# 8 treatments:       1, ..., 8
################################################################################

### Change settings here ###
perfect_quiz <- FALSE



# Define variables
sample_tag <- if (perfect_quiz) "perfect" else "full"
match_list <- list(NULL, "drop1qtr", "first5", "last5")

strategy_configs <- list(
  list(
    strategies_input = c("ad", "ac", "g", "tft", "wsls", "t2"),
    strategies_output = c("AD", "AC", "G", "TFT", "WSLS", "T2"),
    intermediate_dir = "intermediate_output/strat_used/"
  ),
  list(
    strategies_input = c("ad", "ac", "g"),
    strategies_output = c("AD", "AC", "G"),
    intermediate_dir = "intermediate_output/strat_used/"
  )
)


# Preprocess the data once
data <- preprocess_data("data/eddie_repeatedgamedata_sfem.csv", perfect_quiz)


# Loop over the strategy sets
for (config in strategy_configs) {

  numStrat <- length(config$strategies_input)

  dfformatlab_special(
    data,
    output_dir = config$intermediate_dir,
    strategies_selected = config$strategies_input,
    sample_tag = sample_tag
  )


  # Run MATLAB script, note this takes around 6 hours on 8 cores
  matlab_command <- sprintf("sample = '%s'; numStrat = %s; ", sample_tag, numStrat)
  run_matlab_script("MATLAB/est_part1_b_all_s.m", matlab_command)


  ### Make table
  for (match_type in match_list) {

    # Define output file name
    if (is.null(match_type)) {
      output_file <- sprintf(
        "tex/results_table7_S%d_%s.tex",
        numStrat,
        sample_tag
      )
    } else {
      output_file <- sprintf(
        "tex/results_table7_S%d_%s_%s.tex",
        numStrat,
        match_type,
        sample_tag
      )
    }

    generate_table7(
      file_count = 8,
      input_dir = config$intermediate_dir,
      output_file = output_file,
      parameter_names = c("gamma", config$strategies_output),
      match_type = match_type,
      strategy_count = numStrat,
      sample_tag = sample_tag
    )
  }
}




