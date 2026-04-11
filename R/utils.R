run_matlab_script <- function(script_name, matlab_command = "", check_interval = 1) {
  matlab_bin <- "/Applications/MATLAB_R2024a.app/bin/matlab"
  
  out_dir <- normalizePath("intermediate_output", mustWork = FALSE)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  indicator_file <- file.path(out_dir, "done.txt")
  
  if (file.exists(indicator_file)) {
    file.remove(indicator_file)
  }
  
  matlab_code <- sprintf(
    "%s; try, run('%s'); fid=fopen('%s','w'); fclose(fid); catch ME, disp(getReport(ME)); end; exit",
    matlab_command,
    script_name,
    gsub("\\\\", "/", indicator_file)
  )
  
  command <- sprintf('"%s" -nodisplay -nosplash -nodesktop -r "%s"', matlab_bin, matlab_code)
  
  print(command)
  system(command, wait = FALSE)
  
  wait_for_completion <- function(file_path, check_interval = 1) {
    symbols <- c("-", "\\", "|", "/")
    i <- 1
    while (!file.exists(file_path)) {
      cat(sprintf("\rWaiting for MATLAB script to finish... %s", symbols[i]))
      i <- ifelse(i == length(symbols), 1, i + 1)
      Sys.sleep(check_interval)
    }
    cat("\rWaiting for MATLAB script to finish... done!\n")
  }
  
  wait_for_completion(indicator_file, check_interval)
  file.remove(indicator_file)
  print("MATLAB script has finished executing.")
}



run_stata_script <- function(script_name, autoplay_tag = NULL, sample = NULL) {
  wrapper <- tempfile(fileext = ".do")

  lines <- character(0)

  if (!is.null(autoplay_tag)) {
    lines <- c(lines, sprintf('global autoplay_tag "%s"', autoplay_tag))
  }

  if (!is.null(sample)) {
    lines <- c(lines, sprintf('global sample "%s"', sample))
  }

  lines <- c(
    lines,
    "set more off",
    sprintf('do "%s"', normalizePath(script_name, winslash = "/"))
  )

  writeLines(lines, wrapper)
  stata(wrapper, stata.echo = FALSE)
}




estimation_and_simulation <- function(autoplayer = FALSE, sample = "full") {
  
  # Define variable
  autoplay_tag = if (autoplayer) "ap1" else "ap0"
  
  # # Set options for RStata
  # cat("Please select the path to your Stata executable:\n")
  
  options(
    RStata.StataPath = "/Applications/Stata/StataSE.app/Contents/MacOS/StataSE",
    RStata.StataVersion = 18
  )
  
# 
#   # Run R script 1
#   cat("Executing R script: learning1.R\n")
#   source("R/learning1.R")
#   cat("Finished executing R script: learning1.R\n")
# 
#   # Run MATLAB script 1
#   run_matlab_script("MATLAB/learningestimation.m")
# 
#   # Run Stata script 1
#   run_stata_script("Stata/learning2.do")
# 
#   # Run MATLAB script 2
#   matlab_command <- sprintf("sample = '%s'; autoplayer = %d; ", sample, autoplayer)
#   run_matlab_script("MATLAB/learningsimulation.m", matlab_command)
#   
  # Run Stata script 2
  run_stata_script("Stata/learning3.do", autoplay_tag, sample)

  
  print("All scripts have finished executing.")
}





#' Load MATLAB estimation results
#'
#' @param file_count Integer. Number of treatment files to load (default: 6)
#' @param parameter_names Character vector. Names of the parameters.
#' @param match_type Character. Type of matches to analyze: NULL (original), "first5", "last5"
#' @return A list containing gamma values, parameter estimates, standard errors, and p-values
load_matlab_est <- function(file_count, 
                            input_dir,
                            parameter_names = c("gamma", "AD", "AC", "G", "TFT", "WSLS", "T2"),
                            match_type = NULL,
                            strategy_count = NULL,
                            sample_tag = NULL) {
  
  # Initialize lists to store results
  gamma_values <- numeric(file_count)
  est_values <- matrix(NA, nrow = length(parameter_names)-1, ncol = file_count)
  se_values <- matrix(NA, nrow = length(parameter_names)-1, ncol = file_count)
  p_values <- matrix(NA, nrow = length(parameter_names), ncol = file_count)
  

  if (is.null(match_type)) {
    temp <- sprintf("est_part1_b_S%d_%%d_%s.mat", strategy_count, sample_tag)
  } else {
    temp <- sprintf("est_part1_b_S%d_%%d_%s_%s.mat", strategy_count, match_type, sample_tag)
  }
  
  file_pattern <- paste0(
    input_dir,
    temp
  )
  
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



