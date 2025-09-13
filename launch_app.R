#!/usr/bin/env Rscript
# Launch script for NFL Score Prediction Shiny App
# This script installs dependencies and launches the web application

cat("🏈 NFL Score Prediction App Launcher\n")
cat("=====================================\n\n")

# Check if required packages are installed
required_packages <- c(
  "shiny", "shinydashboard", "DT", "plotly", "tidyverse", 
  "nflreadr", "caret", "randomForest", "shinycssloaders", 
  "shinyWidgets", "zoo", "lubridate", "stringr"
)

cat("Checking required packages...\n")

missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]

if (length(missing_packages) > 0) {
  cat("Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  
  # Install packages
  install.packages(missing_packages, repos = "https://cran.r-project.org")
  
  # Verify installation
  still_missing <- missing_packages[!missing_packages %in% installed.packages()[,"Package"]]
  if (length(still_missing) > 0) {
    cat("❌ Failed to install:", paste(still_missing, collapse = ", "), "\n")
    cat("Please install manually: install.packages(c('", paste(still_missing, collapse = "', '"), "'))\n")
    stop("Missing required packages")
  }
}

cat("✅ All required packages are installed\n\n")

# Load required libraries
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(DT)
  library(plotly)
  library(tidyverse)
  library(nflreadr)
  library(caret)
  library(randomForest)
  library(shinycssloaders)
  library(shinyWidgets)
  library(zoo)
  library(lubridate)
  library(stringr)
})

cat("✅ All libraries loaded successfully\n\n")

# Check if the main app file exists
if (!file.exists("app.R")) {
  cat("❌ Error: app.R not found in current directory\n")
  cat("Please make sure you're in the correct directory\n")
  stop("App file not found")
}

cat("✅ App file found\n\n")

# Launch the app
cat("🚀 Launching NFL Score Prediction App...\n")
cat("The app will open in your default web browser\n")
cat("Press Ctrl+C to stop the app\n\n")

# Run the app
runApp("app.R", launch.browser = TRUE, host = "0.0.0.0", port = 3838)