library(readr)
library(dplyr)
library(stargazer)
library(R.matlab)
library(knitr)
library(kableExtra)
library(xtable)

# Function to generate the LaTeX table
generate_latex_table3 <- function(data, file_name = "tex/table3.tex") {
  latex_code <- paste0(
    "% Please add the following required packages to your document preamble:\n",
    "% \\usepackage[table,xcdraw]{xcolor}\n",
    "% Beamer presentation requires \\usepackage{colortbl} instead of \\usepackage[table,xcdraw]{xcolor}\n",
    "\\begin{table}[h]\n",
    "\\centering\n",
    "\\caption{Percentage of Cooperation by Treatment}\n",
    "\\begin{adjustbox}{width=1\\textwidth}\n",
    "\\begin{tabular}{cccclcccllccllcccc}\n",
    "\\hline\n",
    "\\multicolumn{1}{l}{} & \\multicolumn{8}{c}{First stage} & & \\multicolumn{8}{c}{All stages} \\\\ \\cline{2-9} \\cline{11-18}\n",
    "$\\delta \\setminus R$ & \\multicolumn{3}{c}{normal} & & & \\multicolumn{3}{c}{high} & & \\multicolumn{3}{c}{normal} & & & \\multicolumn{3}{c}{high} \\\\ \\cline{2-4} \\cline{7-9} \\cline{11-13} \\cline{16-18}\n",
    "& {\\color[HTML]{CB0000} no} & & {\\color[HTML]{32CB00} GT} & & & {\\color[HTML]{CB0000} no} & & \\multicolumn{1}{c}{{\\color[HTML]{32CB00} GT}} & & {\\color[HTML]{CB0000} no} & & \\multicolumn{1}{c}{{\\color[HTML]{32CB00} GT}} & & & {\\color[HTML]{CB0000} no} & & {\\color[HTML]{32CB00} GT} \\\\ \\hline\n",
    "\\multicolumn{18}{c}{\\textbf{First round}} \\\\\n",
    "low                  & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "low", "normal", 1, "no", 1), "}          & ", perform_probit_comparison(data, "low", "normal", NA, 1, 1), "    & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "low", "normal", 1, "GT", 1), "}          & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} }}                                                               & {\\color[HTML]{32CB00} }                                                            & {\\color[HTML]{CB0000} }                                                                &                                                              & {\\color[HTML]{32CB00} }                                                              &  & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "low", "normal", 0, "no", 1), "}          & ", perform_probit_comparison(data, "low", "normal", NA, 0, 1), "    & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "low", "normal", 0, "GT", 1), "}                        & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} }}                                                             & {\\color[HTML]{32CB00} }                                                            & {\\color[HTML]{CB0000} }      &              & {\\color[HTML]{32CB00} }      \\\\\n",
    "                     & {\\color[HTML]{CB0000} ", perform_probit_comparison(data, NA, "normal", "no", 1, 1), "}            &                                                                    & {\\color[HTML]{32CB00} ",perform_probit_comparison(data, NA, "normal", "GT", 1, 1),"}         & {\\color[HTML]{CB0000} }                                                                                    & {\\color[HTML]{32CB00} }                                                             & {\\color[HTML]{CB0000} }                                                                &                                                             & \\multicolumn{1}{c}{{\\color[HTML]{32CB00} }}                                         &  & {\\color[HTML]{CB0000} ", perform_probit_comparison(data, NA, "normal", "no", 0, 1), "}        &                                                                    & \\multicolumn{1}{c}{{\\color[HTML]{32CB00} ",perform_probit_comparison(data, NA, "normal", "GT", 0, 1),"}}    & {\\color[HTML]{CB0000} }                                                                                  & {\\color[HTML]{32CB00} }                                                            & {\\color[HTML]{CB0000} }      &              & {\\color[HTML]{32CB00} }      \\\\\n",
    "high                 & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "normal", 1, "no", 1), "}          & ", perform_probit_comparison(data, "high", "normal", NA, 1, 1), "    & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "normal", 1, "GT", 1), "}          & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} ",perform_probit_comparison(data, "high", NA, "no", 1, 1),"}} & {\\color[HTML]{32CB00} ",perform_probit_comparison(data, "high", NA, "GT", 1, 1),"} & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "high", 1, "no", 1), "} & ", perform_probit_comparison(data, "high", "high", NA, 1, 1), " & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "high", 1, "GT", 1), "} & & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "normal", 0, "no", 1), "}        & ", perform_probit_comparison(data, "high", "normal", NA, 0, 1), "   & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "normal", 0, "GT", 1), "}                        & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} ",perform_probit_comparison(data, "high", NA, "no", 0, 1),"}} & {\\color[HTML]{32CB00} ",perform_probit_comparison(data, "high", NA, "GT", 0, 1),"} & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "high", 0, "no", 1), "} & ", perform_probit_comparison(data, "high", "high", NA, 0, 1), " & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "high", 0, "GT", 1), "} \\\\ \\hline\n",
    "\\multicolumn{18}{c}{\\textbf{All repeated games}} \\\\\n",
    "low                  & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "low", "normal", 1, "no", 0), "}          & ", perform_probit_comparison(data, "low", "normal", NA, 1, 0), "    & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "low", "normal", 1, "GT", 0), "}          & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} }}                                                               & {\\color[HTML]{32CB00} }                                                            & {\\color[HTML]{CB0000} }                                                                &                                                              & {\\color[HTML]{32CB00} }                                                              &  & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "low", "normal", 0, "no", 0), "}          & ", perform_probit_comparison(data, "low", "normal", NA, 0, 0), "    & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "low", "normal", 0, "GT", 0), "}                        & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} }}                                                             & {\\color[HTML]{32CB00} }                                                            & {\\color[HTML]{CB0000} }      &              & {\\color[HTML]{32CB00} }      \\\\\n",
    "                     & {\\color[HTML]{CB0000} ", perform_probit_comparison(data, NA, "normal", "no", 1, 0), "}            &                                                                    & {\\color[HTML]{32CB00} ",perform_probit_comparison(data, NA, "normal", "GT", 1, 0),"}         & {\\color[HTML]{CB0000} }                                                                                    & {\\color[HTML]{32CB00} }                                                             & {\\color[HTML]{CB0000} }                                                                &                                                             & \\multicolumn{1}{c}{{\\color[HTML]{32CB00} }}                                         &  & {\\color[HTML]{CB0000} ", perform_probit_comparison(data, NA, "normal", "no", 0, 0), "}        &                                                                    & \\multicolumn{1}{c}{{\\color[HTML]{32CB00} ",perform_probit_comparison(data, NA, "normal", "GT", 0, 0),"}}    & {\\color[HTML]{CB0000} }                                                                                  & {\\color[HTML]{32CB00} }                                                            & {\\color[HTML]{CB0000} }      &              & {\\color[HTML]{32CB00} }      \\\\\n",
    "high                 & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "normal", 1, "no", 0), "}          & ", perform_probit_comparison(data, "high", "normal", NA, 1, 0), "    & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "normal", 1, "GT", 0), "}          & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} ",perform_probit_comparison(data, "high", NA, "no", 1, 0),"}} & {\\color[HTML]{32CB00} ",perform_probit_comparison(data, "high", NA, "GT", 1, 0),"} & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "high", 1, "no", 0), "} & ", perform_probit_comparison(data, "high", "high", NA, 1, 0), " & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "high", 1, "GT", 0), "} & & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "normal", 0, "no", 0), "}        & ", perform_probit_comparison(data, "high", "normal", NA, 0, 0), "   & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "normal", 0, "GT", 0), "}                        & \\multicolumn{1}{c}{{\\color[HTML]{CB0000} ",perform_probit_comparison(data, "high", NA, "no", 0, 0),"}} & {\\color[HTML]{32CB00} ",perform_probit_comparison(data, "high", NA, "GT", 0, 0),"} & {\\color[HTML]{CB0000} ", calculate_coop_share(data, "high", "high", 0, "no", 0), "} & ", perform_probit_comparison(data, "high", "high", NA, 0, 0), " & {\\color[HTML]{32CB00} ", calculate_coop_share(data, "high", "high", 0, "GT", 0), "} \\\\ \\hline\n",
    "\\end{tabular}\n",
    "\\end{adjustbox}\n",
    "\\end{table}"
  )
  
  # Write the LaTeX code to a .tex file
  writeLines(latex_code, file_name)
}


# Function to generate the LaTeX table for a given max_stage
generate_latex_table4 <- function(data, first_stage, file_name = "tex/table4.tex") {
  rounds <- seq(1, 61, by = 5)
  latex_code <- paste0(
    "% Please add the following required packages to your document preamble:\n",
    "% \\usepackage[table,xcdraw]{xcolor}\n",
    "% Beamer presentation requires \\usepackage{colortbl} instead of \\usepackage[table,xcdraw]{xcolor}\n",
    "\\begin{table}[h]\n",
    "\\centering\n",
    "\\caption{Percentage of Cooperation by Equilibrium Condition and Risk Dominance (",
    ifelse(first_stage == 1, "First stage", "All stages"), ")}\n",
    "\\begin{tabular}{cccccccc}\n",
    "\\hline\n",
    "\\multicolumn{1}{l}{} & \\multicolumn{6}{c}{",
    ifelse(first_stage == 1, "First stage cooperation is", "All stages cooperation is"), 
    "} \\\\ \n",
    "Round Range & \\multicolumn{2}{c}{not SGPE} & \\multicolumn{2}{c}{SGPE not RD} & \\multicolumn{2}{c}{SGPE and RD} \\\\ \\cline{2-7}\n",
    "& no & GT & no & GT & no & GT \\\\ \\cline{1-7}\n"
  )
  
  for (i in seq_along(rounds)[-length(rounds)]) {
    round_start <- rounds[i]
    round_end <- rounds[i + 1] - 1
    
    latex_code <- paste0(
      latex_code,
      round_start, "--", round_end, " & {\\color[HTML]{CB0000}",
      sprintf("%.2f", calculate_coop_share2(data, "no", 0, first_stage, round_start, round_end)), "} & {\\color[HTML]{009901}",
      sprintf("%.2f", calculate_coop_share2(data, "GT", 0, first_stage, round_start, round_end)), "} & {\\color[HTML]{CB0000}",
      sprintf("%.2f", calculate_coop_share2(data, "no", 1, first_stage, round_start, round_end)), "} & {\\color[HTML]{009901}",
      sprintf("%.2f", calculate_coop_share2(data, "GT", 1, first_stage, round_start, round_end)), "} & {\\color[HTML]{CB0000}",
      sprintf("%.2f", calculate_coop_share2(data, "no", 2, first_stage, round_start, round_end)), "} & {\\color[HTML]{009901}",
      sprintf("%.2f", calculate_coop_share2(data, "GT", 2, first_stage, round_start, round_end)), "} \\\\\n"
    )
  }
  
  latex_code <- paste0(
    latex_code,
    "\\hline\n",
    "\\end{tabular}\n",
    "\\end{table}\n"
  )
  
  # replace NaN with ""
  latex_code <- gsub("NaN", "", latex_code)
  
  # Write the LaTeX code to a .tex file
  writeLines(latex_code, file_name)
}

# Function to generate all LaTeX tables for Table 4
generate_all_latex_table4 <- function(data) {
  # Generate table4a for the first stage
  generate_latex_table4(data, first_stage = 1, file_name = "tex/table4a.tex")
  
  # Generate table4b for all stages
  generate_latex_table4(data, first_stage = 100, file_name = "tex/table4b.tex")
}


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

# generate the table6 for the paper

generate_table6 <- function(model_results_list = table6_analysis(), output_file = "tex/table6.tex") {

  
  # Parse each result and store the formatted values
  results <- list()
  for (i in 1:length(model_results_list)) {
    model_result <- model_results_list[[i]]$mfxest
    result_table <- as.data.frame(model_result)
    result_table$significance <- sapply(result_table[, "P>|z|"], add_significance_stars)
    
    # Format the values with SE in parentheses and add LaTeX math mode
    formatted_estimates <- sprintf("%.4f%s", result_table[, "dF/dx"], result_table$significance)
    formatted_se <- sprintf("(%.4f)", result_table[, "Std. Err."])
    
    # Create a data frame for this model result
    result_df <- data.frame(Parameter = rownames(result_table), 
                            Estimate = formatted_estimates, 
                            SE = formatted_se, 
                            stringsAsFactors = FALSE)
    result_df <- rbind(result_df, c("Observations", as.character(length(model_results_list[[i]]$fit$y)), ""))
    
    # Store the result
    results[[paste("T", i, sep = "")]] <- result_df
  }
  
  # Prepare the data for the LaTeX table
  parameter_names <- c(rownames(result_table), "Observations")
  double_row_names <- rep(parameter_names, each = 2)
  double_row_names[seq(2, length(double_row_names), 2)] <- ""
  
  # Combine results into a single data frame
  combined_results <- data.frame(Parameter = double_row_names)
  for (i in 1:length(results)) {
    col_data <- c()
    for (j in 1:nrow(results[[i]])) {
      col_data <- c(col_data, results[[i]]$Estimate[j], results[[i]]$SE[j])
    }
    combined_results[[paste("T", i, sep = "")]] <- col_data
  }
  
  # Generate LaTeX table
  latex_table <- kable(combined_results, 
                       caption = "Effect of Past Observations on Round 1 Cooperation (probit - marginal effects)",
                       format = "latex", booktabs = TRUE, row.names = FALSE) %>%
    kable_styling(latex_options = c("striped", "hold_position"))
  
  # Write the LaTeX table to a .tex file
  cat(latex_table, file = output_file)
  
  print(paste("LaTeX table written to", output_file))
}





#' Generate Table 7 for the paper
#'
#' @param file_count Integer. Number of treatment files (default: 6)
#' @param output_file Character. Path to save the output LaTeX file
#' @param parameter_names Character vector. Names of the parameters
#' @param match_type Character. Type of matches to analyze: NULL (original), "first5", "last5"
#' @return None. Saves LaTeX table to specified output file
generate_table7 <- function(file_count = 6,
                            input_dir = "scripts/raw/",
                            output_file = "tex/results_table7.tex", 
                            parameter_names = c("gamma", "AD", "AC", "G", "TFT", "WSLS", "T2"),
                            match_type = NULL) {
  
  # Determine output file name based on match_type
  if (!is.null(match_type)) {
    # Modify output file name to include match_type
    output_file <- sub("\\.tex$", paste0("_", match_type, ".tex"), output_file)
  }
  
  # Load the results
  matlab_results <- load_matlab_est(file_count, input_dir, parameter_names, match_type)
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
    # table_caption <- paste0(table_caption, " (", 
    #                         ifelse(match_type == "first5", "First 5 SG", "Last 5 SG"), ")")
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






#' Perform Pairwise Wald Tests for Strategy Parameter Estimates Across Treatments
#'
#' @param num_treatments Integer. Number of treatment groups (default: 6)
#' @param parameter_names Character vector. Names of the parameters
#' @param match_type Character. Type of matches to analyze: NULL (original), "first5", "last5"
#' @return A data frame with pairwise Wald test p-values
wald_test_pairwise <- function(num_treatments = 6, 
                               parameter_names = c("gamma", "AD", "AC", "G", "TFT", "WSLS"),
                               match_type = NULL) {
  
  # Determine output file name based on match_type
  output_file <- "tex/wald_test_results.tex"
  if (!is.null(match_type)) {
    output_file <- sub("\\.tex$", paste0("_", match_type, ".tex"), output_file)
  }
  
  # Load MATLAB estimates and standard errors
  matlab_est <- load_matlab_est(num_treatments, c(parameter_names, "T2"), match_type)
  gamma_values <- matlab_est$gamma_values
  est_values <- matlab_est$est_values
  
  # delete the last row of est_values and rbind gamma_values with est_values
  est_values <- est_values[-nrow(est_values), ]
  est_values <- rbind(gamma_values, est_values)
  
  se_values <- matlab_est$se_values
  
  # Initialize results list
  results_list <- list()
  
  # Perform pairwise Wald tests
  row_names <- c()
  for (i in 1:(num_treatments - 1)) {
    for (j in (i + 1):num_treatments) {
      comparison_name <- paste0("T", i, " vs T", j)
      row_names <- c(row_names, comparison_name)
      
      # Compute Wald test for each parameter
      test_stats <- (est_values[, i] - est_values[, j]) / sqrt(se_values[, i]^2 + se_values[, j]^2)
      p_values <- 2 * (1 - pnorm(abs(test_stats)))
      
      results_list[[comparison_name]] <- p_values
    }
  }
  
  # Convert results list to data frame
  results_df <- as.data.frame(do.call(rbind, results_list))
  colnames(results_df) <- parameter_names
  rownames(results_df) <- row_names
  
  # Create table caption based on match_type
  table_caption <- "Pairwise Wald Test p-values for Treatment Comparisons"
  if (!is.null(match_type)) {
    table_caption <- paste0(table_caption, " (", 
                            ifelse(match_type == "first5", "First 5 Matches", "Last 5 Matches"), ")")
  }
  
  # Create LaTeX table
  latex_table <- xtable(results_df, 
                        caption = table_caption, 
                        label = ifelse(is.null(match_type), 
                                       "tab:wald_results", 
                                       paste0("tab:wald_results_", match_type)), 
                        digits = rep(3, ncol(results_df) + 1))
  
  print(latex_table, type = "latex", file = output_file)
  
  return(results_df)
}




#' Read LR Test Results and Reshape into a Wide Table
#'
#' This function reads a MATLAB `.mat` file containing LR test results and processes it 
#' to create a table where rows represent comparisons between treatment groups and columns 
#' correspond to different parameters.
#'
#' @param file_path Character. Path to the `.mat` file. choices can be "scripts/lr_test_results.mat", 
#'  "scripts/lr_test_results_first5_special.mat", or "scripts/lr_test_results_last5_special.mat".
#' @param parameter_names Character vector. Names of the parameters being tested.
#'   Defaults to c("gamma", "AD", "AC", "G", "TFT", "WSLS", "T2").
#'
#' @return A data frame with pairwise LR test p-values, where rows represent comparisons
#'         between two treatments and columns correspond to parameters.
#'         
#'         # Example usage
#' file_path <- "scripts/lr_test_results.mat"  
#' lr_results_df <- read_and_process_lr_test(file_path)
#' print(lr_results_df)
#'
#' @export
read_and_process_lr_test <- function(file_path = "scripts/lr_test_results.mat", 
                                     parameter_names = c("gamma", "AD", "AC", "G", "TFT", "WSLS", "T2")) {
  library(R.matlab)
  library(dplyr)
  library(tidyr)
  library(xtable)
  
  # Read MATLAB .mat file
  mat_data <- readMat(file_path)
  lr_results <- mat_data$lr.results
  
  # Extract relevant information
  treatment_pairs <- lr_results[[1]]
  param_indices <- lr_results[[2]]
  p_values <- lr_results[[4]]
  
  treatment_pairs_vector <- paste0("T", treatment_pairs[,1], " vs T", treatment_pairs[,2])
  
  # Create a data frame in long format
  long_df <- data.frame(
    Treatment_Pair = treatment_pairs_vector,
    Param_Index = param_indices,
    P_Value = p_values
  )
  
  # Reshape into wide format
  wide_df <- long_df %>%
    mutate(Param_Index = factor(Param_Index, levels = 1:length(parameter_names), labels = parameter_names)) %>%
    pivot_wider(names_from = Param_Index, values_from = P_Value)
  
  # Remove "T2" column if it exists
  if ("T2" %in% colnames(wide_df)) {
    wide_df <- wide_df[, -which(colnames(wide_df) == "T2")]
  }
  
  # Determine save filename based on the file name
  cap_suffix <- ifelse(grepl("first5", file_path), "First 5 Matches", 
                        ifelse(grepl("last5", file_path), "Last 5 Matches", "All Matches"))
  
  file_suffix <- ifelse(grepl("first5", file_path), "first5", 
                        ifelse(grepl("last5", file_path), "last5", "all"))
  
  save_file_name <- paste0("tex/lr_test_results_", file_suffix, ".tex")
  
  # Generate LaTeX table
  latex_table <- xtable(wide_df, caption = paste("Pairwise LR Test p-values for Treatment Comparisons (",
                                                 cap_suffix, ")", sep = ""),
                        label = paste0("tab:lr_results_", file_suffix), 
                        digits = rep(3, ncol(wide_df) + 1))
  
  print(latex_table, type = "latex", file = save_file_name)
  
  return(wide_df)
}



