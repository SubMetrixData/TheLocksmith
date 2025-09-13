#!/usr/bin/env Rscript
# Example script to run the NFL Score Prediction Program
# This demonstrates how to use the program with different configurations

# Load the main program
source("nfl_score_predictor.R")

cat("=== NFL Score Prediction Example ===\n\n")

# Example 1: Basic prediction with recent seasons
cat("Example 1: Basic prediction (2020-2024 training, 2025 prediction)\n")
cat("=" * 60, "\n")

results1 <- run_nfl_predictor(
  seasons = 2020:2024,
  prediction_season = 2025
)

# Example 2: Quick prediction with fewer seasons (faster)
cat("\n\nExample 2: Quick prediction (2022-2024 training)\n")
cat("=" * 50, "\n")

results2 <- run_nfl_predictor(
  seasons = 2022:2024,
  prediction_season = 2025
)

# Example 3: Historical analysis (predict 2024 season)
cat("\n\nExample 3: Historical analysis (predict 2024 season)\n")
cat("=" * 50, "\n")

results3 <- run_nfl_predictor(
  seasons = 2020:2023,
  prediction_season = 2024
)

# Display summary of all results
cat("\n\n=== SUMMARY OF ALL PREDICTIONS ===\n")

if (nrow(results1$predictions) > 0) {
  cat("\n2025 Season Predictions (5-year training):\n")
  print(results1$predictions %>% 
        select(home_team, away_team, predicted_home_score, predicted_away_score, predicted_winner))
}

if (nrow(results2$predictions) > 0) {
  cat("\n2025 Season Predictions (3-year training):\n")
  print(results2$predictions %>% 
        select(home_team, away_team, predicted_home_score, predicted_away_score, predicted_winner))
}

if (nrow(results3$predictions) > 0) {
  cat("\n2024 Season Predictions (historical):\n")
  print(results3$predictions %>% 
        select(home_team, away_team, predicted_home_score, predicted_away_score, predicted_winner))
}

# Save all predictions
if (nrow(results1$predictions) > 0) {
  write.csv(results1$predictions, "nfl_predictions_2025_5yr.csv", row.names = FALSE)
  cat("\nPredictions saved to 'nfl_predictions_2025_5yr.csv'\n")
}

if (nrow(results2$predictions) > 0) {
  write.csv(results2$predictions, "nfl_predictions_2025_3yr.csv", row.names = FALSE)
  cat("Predictions saved to 'nfl_predictions_2025_3yr.csv'\n")
}

if (nrow(results3$predictions) > 0) {
  write.csv(results3$predictions, "nfl_predictions_2024_historical.csv", row.names = FALSE)
  cat("Predictions saved to 'nfl_predictions_2024_historical.csv'\n")
}

cat("\n=== Example completed successfully! ===\n")
cat("Check the generated CSV files for detailed predictions.\n")
cat("Use the interactive plots in RStudio for visualizations.\n")