
rm(list = ls())

source("R/install_packages.R")
source("R/preprocessing.R")
source("R/tables.R")
source("R/utils.R")

library(ggplot2)
library(dplyr)
library(tidyr)


################################################################################
# Define helper functions 
################################################################################

### Format table to look nicer
format_table <- function(tab, digits = 3) {
  tab_out <- tab
  
  tab_out[[1]] <- as.character(tab_out[[1]])   # Treatment column
  
  tab_out[-1] <- lapply(tab_out[-1], function(x) {
    x <- as.numeric(x)
    ifelse(
      is.infinite(x),
      "Inf",
      formatC(x, format = "e", digits = digits)
    )
  })
  
  tab_out
}


### Generate LaTeX table
save_tex_table <- function(table, caption, output_file){
  latex_table <- kable(table, 
                       caption = caption,
                       format = "latex", booktabs = TRUE, row.names = FALSE) %>%
    kable_styling(latex_options = c("striped", "hold_position"))
  
  # Write the LaTeX table to a .tex file
  cat(latex_table, file = output_file)
  
  print(paste("LaTeX table written to", output_file))
}

################################################################################
# Define helper functions 
################################################################################


### Define output table
cols <- c(
  "T",
  "betaG_1", "betaG_mid", "betaG_1000",
  "betaD_1", "betaD_mid", "betaD_1000",
  "theta", "phi", "lambda_F", "lambda_V"
)

table_mean <- data.frame(matrix(ncol = length(cols), nrow = 0))
colnames(table_mean) <- cols

table_median <- table_mean



### Load data
learning_estimate <- read.table("scripts/learningestimatesall.txt", header = FALSE)
colnames(learning_estimate) <- c("treatment", "id", "learning_delta", "lambda_f", "lambda_v", "psi", "betaad_1", "betag_1")



### Loop over treatment
for (treat in 1:8) {
  
  # First period beta_G and beta_AD
  temp0 <- learning_estimate[learning_estimate["treatment"] == treat, c("betag_1", "betaad_1")]
  
  print(colMeans(temp0))
  
  # beta_G
  filename <- sprintf("scripts/beta_G_treatment_%d.txt", treat)
  temp1 <- read.table(filename, header = FALSE)
  
  # beta_AD
  filename <- sprintf("scripts/beta_AD_treatment_%d.txt", treat)
  temp2 <- read.table(filename, header = FALSE)
  
  # Get 60 for delta = 1/2, 30 for delta = 3/4
  if (treat %in% c(1, 3)) {
    temp1 = temp1[, 2:3]
    temp2 = temp2[, 2:3]
  }
  else {
    temp1 = temp1[, c(1,3)]
    temp2 = temp2[, c(1,3)]
  }
  
  
  # other params
  temp3 <- learning_estimate[learning_estimate["treatment"] == treat, c("learning_delta", "psi", "lambda_f", "lambda_v")]
  
  # Compute mean
  mean_row = c(treat, mean(temp0[, 1]), colMeans(temp1), mean(temp0[, 2]), colMeans(temp2), colMeans(temp3))
    
  # Compute median
  median_row = c(
    treat,
    median(temp0[, 1]),
    apply(temp1, 2, median),
    median(temp0[, 2]),
    apply(temp2, 2, median),
    apply(temp3, 2, median)
  )
  
  # Append to table
  mean_df <- as.data.frame(t(mean_row))
  median_df <- as.data.frame(t(median_row))
  
  colnames(mean_df) <- colnames(table_mean)
  colnames(median_df) <- colnames(table_median)
  
  table_mean <- rbind(table_mean, mean_df)
  table_median <- rbind(table_median, median_df)
  
  
  
  ##### CDF plots
  # build long data 
  colnames(temp0) <- c("betaG_1", "betaAD_1")
  colnames(temp1) <- paste0("betaG_", c("mid", "1000"))
  colnames(temp2) <- paste0("betaAD_", c("mid", "1000"))
  df_list <- list(
    temp0["betaG_1"],
    temp1,
    temp0["betaAD_1"],
    temp2,
    temp3
  )
  
  
  plot_long <- do.call(rbind, lapply(df_list, function(df) {
    data.frame(
      variable = rep(colnames(df), each = nrow(df)),
      value = as.vector(as.matrix(df))
    )
  }))
  
  # remove Inf / NA
  plot_long <- plot_long[is.finite(plot_long$value), ]
  
  # optional (strongly recommended for your huge numbers)
  plot_long$value <- log10(abs(plot_long$value) + 1)
  
  # plot
  p <- ggplot(plot_long, aes(x = value)) +
    stat_ecdf() +
    facet_wrap(~ variable, scales = "free", ncol = 5) +
    theme_minimal() +
    labs(
      title = paste("Treatment", treat),
      x = "log10(value + 1)",
      y = "CDF"
    )
  
  # save
  ggsave(
    filename = sprintf("figures/cdf_treatment_%d.pdf", treat),
    plot = p,
    width = 12,
    height = 6
  )
}



### Save table
table_mean <- format_table(table_mean, 2)
save_tex_table(table_mean, "Mean of Learning Model Estimates", "tex/summary_mean.tex")

table_median <- format_table(table_median, 2)
save_tex_table(table_median, "Median of Learning Model Estimates", "tex/summary_median.tex")








