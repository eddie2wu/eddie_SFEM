library(readr)
library(dplyr)
library(stargazer)
library(R.matlab)
library(knitr)
library(kableExtra)
library(xtable)


# Significance stars function
add_significance_stars <- function(p_value) {
  if (p_value < 0.001) {
    return("***")
  } else if (p_value < 0.01) {
    return("**")
  } else if (p_value < 0.05) {
    return("*")
  } else {
    return("")
  }
}



#' Generate Table 7 for the paper
#'
#' @param file_count Integer. Number of treatment files (default: 6)
#' @param output_file Character. Path to save the output LaTeX file
#' @param parameter_names Character vector. Names of the parameters
#' @param match_type Character. Type of matches to analyze: NULL (original), "first5", "last5"
#' @return None. Saves LaTeX table to specified output file
generate_table7 <- function(file_count,
                            input_dir,
                            output_file, 
                            parameter_names = c("gamma", "AD", "AC", "G", "TFT", "WSLS", "T2"),
                            match_type = NULL,
                            strategy_count = NULL,
                            sample_tag = NULL) {
  
  # Load the results
  matlab_results <- load_matlab_est(
    file_count = file_count,
    input_dir = input_dir,
    parameter_names = parameter_names,
    match_type = match_type,
    strategy_count = strategy_count,
    sample_tag = sample_tag
  )
  
  gamma_values <- matlab_results$gamma_values
  est_values <- matlab_results$est_values
  se_values <- matlab_results$se_values
  p_values <- matlab_results$p_values
  
  # Prepare the data for the LaTeX table
  results <- data.frame(Parameter = rep(parameter_names, each = 2))
  results$Parameter[seq(2, length(results$Parameter), 2)] <- ""  # Leave SE row names empty
  
  for (filenum in 1:file_count) {
    col_data <- c(sprintf("%.4f%s", gamma_values[filenum], add_significance_stars(p_values[1, filenum])))
    for (i in 1:(length(parameter_names)-1)) {
      col_data <- c(col_data, 
                    sprintf("(%.4f)", se_values[i, filenum]),
                    sprintf("%.4f%s", est_values[i, filenum], add_significance_stars(p_values[i+1, filenum])))
    }
    # Add p_values without SE for gamma
    col_data <- c(col_data, NA)
    results[[paste("T", filenum)]] <- col_data
  }
  
  
  # delete the last row
  results <- results[-nrow(results), ]
  
  # Generate LaTeX table
  table_caption <- "Estimation of Strategies Used"
  if (!is.null(match_type)) {
    if (match_type == "first5") {
      match_type_name <- "First 5 SG"
    }
    else if (match_type == "last5") {
      match_type_name <- "Last 5 SG"
    } else if (match_type == "drop1qtr") {
      match_type_name <- "Drop 1st Quarter"
    }

    table_caption <- paste0(table_caption, " (",
                            match_type_name, ")")
  }
  
  latex_table <- kable(results, 
                       caption = table_caption,
                       format = "latex", booktabs = TRUE, row.names = FALSE) %>%
    kable_styling(latex_options = c("striped", "hold_position"))
  
  # Write the LaTeX table to a .tex file
  cat(latex_table, file = output_file)
  
  print(paste("LaTeX table written to", output_file))
}






