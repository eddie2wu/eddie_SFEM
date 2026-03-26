run_matlab_script <- function(script_name, check_interval = 1) {
  # Construct the full path to the MATLAB script
  script_path <- file.path("scripts", script_name)
  
  matlab_bin <- "/Applications/MATLAB_R2024a.app/bin/matlab"
  
  # Create the command to run the MATLAB script
  # command <- sprintf('matlab -nodisplay -r "run(\'%s\'); exit"', script_path)
  command <- sprintf(
    '"%s" -nodisplay -r "run(\'%s\'); exit"',
    matlab_bin, script_path
  )
  
  # Set the path for the indicator file
  indicator_file <- file.path("scripts", "done.txt")
  
  # Remove any existing indicator file to ensure a clean start
  if (file.exists(indicator_file)) {
    file.remove(indicator_file)
  }
  
  # Run the MATLAB script
  system(command, wait = FALSE)
  
  # Function to check for completion with dynamic text feedback
  wait_for_completion <- function(file_path, check_interval = 1) {
    symbols <- c("-", "\\", "|", "/")  # Symbols for rotation
    i <- 1  # Index for rotating symbols
    
    while (!file.exists(file_path)) {
      # Print dynamic message with rotating symbol
      cat(sprintf("\rWaiting for MATLAB script to finish... %s", symbols[i]))
      
      # Rotate the symbol
      i <- ifelse(i == length(symbols), 1, i + 1)
      
      # Wait for the specified interval
      Sys.sleep(check_interval)
    }
    
    # Clear the line after completion
    cat("\rWaiting for MATLAB script to finish... done!\n")
  }
  
  # Wait for the MATLAB script to finish
  wait_for_completion(indicator_file, check_interval)
  
  # Delete the indicator file
  file.remove(indicator_file)
  
  # Inform that the script has finished executing
  print("MATLAB script has finished executing.")
}

estimation_and_simulation <- function() {
  
  # Set options for RStata
  cat("Please select the path to your Stata executable:\n")
  # chooseStataBin() # Replace with the path to your Stata executable
  
  
  options(
    RStata.StataPath = "/Applications/Stata/StataSE.app/Contents/MacOS/StataSE",
    RStata.StataVersion = 18
  )
  
  
  # # Ask the user to enter the Stata version number
  # stata_version <- as.numeric(readline(prompt = "Please enter your Stata version number (e.g., 18): "))
  
  # # Set options for RStata
  # options(RStata.StataVersion = stata_version)
  
  # Function to run Stata script with message
  run_stata_script <- function(script_name) {
    cat(sprintf("Executing Stata script: %s\n", script_name))
    stata(file.path("scripts", script_name), stata.echo = FALSE)
    cat(sprintf("Finished executing Stata script: %s\n", script_name))
  }
  
  # Run R script 1
  cat("Executing R script: learning1.R\n")
  source("R/learning1.R")
  cat("Finished executing R script: learning1.R\n")
  
  # Run MATLAB script 1
  run_matlab_script("learningestimation.m")
  
  # Run Stata script 1
  run_stata_script("learning2.do")
  
  # Run MATLAB script 2
  run_matlab_script("learningsimulation.m")
  
  # Run MATLAB script 3
  run_matlab_script("learningsimulationcross.m")
  
  # Run Stata script 2
  run_stata_script("learning3.do")
  
  print("All scripts have finished executing.")
  
}

#' Load MATLAB estimation results
#'
#' @param file_count Integer. Number of treatment files to load (default: 6)
#' @param parameter_names Character vector. Names of the parameters.
#' @param match_type Character. Type of matches to analyze: NULL (original), "first5", "last5"
#' @return A list containing gamma values, parameter estimates, standard errors, and p-values
load_matlab_est <- function(file_count = 6, 
                            parameter_names = c("gamma", "AD", "AC", "G", "TFT", "WSLS", "T2"),
                            match_type = NULL) {
  # Initialize lists to store results
  gamma_values <- numeric(file_count)
  est_values <- matrix(NA, nrow = length(parameter_names)-1, ncol = file_count)
  se_values <- matrix(NA, nrow = length(parameter_names)-1, ncol = file_count)
  p_values <- matrix(NA, nrow = length(parameter_names), ncol = file_count)
  
  # Determine file naming pattern based on match_type
  if (is.null(match_type)) {
    # Original pattern
    file_pattern <- 'scripts/raw/est_part1_b_%d_s.mat'
  } else {
    # New pattern with match_type
    file_pattern <- sprintf('scripts/raw/est_part1_b_%%d_s_%s.mat', match_type)
  }
  
  # Load the results from the .mat files
  for (filenum in 1:file_count) {
    filename <- sprintf(file_pattern, filenum)
    data <- readMat(filename)
    
    # Store the gamma value
    gamma_values[filenum] <- data$gamma
    
    # Store the parameter estimates and p-values
    est_values[, filenum] <- data$p
    p_values[, filenum] <- data$p.values
    
    # Calculate and store the standard errors
    se <- sqrt(diag(data$vc.bs))
    se_values[1:(length(parameter_names)-1), filenum] <- se
  }
  
  return(list(gamma_values = gamma_values, est_values = est_values, se_values = se_values, p_values = p_values))
}