# Define a vector of required packages
required_packages <- c(
  "readr", "dplyr", "stargazer", "R.matlab", "knitr", "kableExtra",
  "tidyr", "haven", "broom", "MASS", "multcomp", "xtable",
  "clusterSEs", "sandwich", "lmtest", "mfx", "RStata", "readxl",
  "tidyverse"
)

# Function to check and install missing packages
install_if_missing <- function(packages) {
  # Find packages that are not installed
  missing_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  
  # Install missing packages
  if (length(missing_packages) > 0) {
    message("Installing missing packages: ", paste(missing_packages, collapse = ", "))
    install.packages(missing_packages, dependencies = TRUE)
  } else {
    message("All required packages are already installed.")
  }
}

# Install missing packages
install_if_missing(required_packages)

# Load all required packages
lapply(required_packages, library, character.only = TRUE)

# Confirm loading
message("All packages loaded successfully.")
