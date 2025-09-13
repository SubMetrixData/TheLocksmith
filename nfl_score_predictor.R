#!/usr/bin/env Rscript
# NFL Score Prediction Program using nflreadr
# This program predicts NFL game scores using historical data and machine learning

# Load required libraries
suppressPackageStartupMessages({
  if (!require(nflreadr, quietly = TRUE)) {
    install.packages("nflreadr", repos = "https://cran.r-project.org")
    library(nflreadr)
  }
  if (!require(tidyverse, quietly = TRUE)) {
    install.packages("tidyverse", repos = "https://cran.r-project.org")
    library(tidyverse)
  }
  if (!require(caret, quietly = TRUE)) {
    install.packages("caret", repos = "https://cran.r-project.org")
    library(caret)
  }
  if (!require(randomForest, quietly = TRUE)) {
    install.packages("randomForest", repos = "https://cran.r-project.org")
    library(randomForest)
  }
  if (!require(plotly, quietly = TRUE)) {
    install.packages("plotly", repos = "https://cran.r-project.org")
    library(plotly)
  }
})

# Set random seed for reproducibility
set.seed(42)

# =============================================================================
# DATA COLLECTION AND PREPROCESSING FUNCTIONS
# =============================================================================

#' Load and prepare historical NFL data
#' @param seasons Vector of seasons to load (e.g., 2020:2024)
#' @return List containing play-by-play data and schedules
load_historical_data <- function(seasons = 2020:2024) {
  cat("Loading historical NFL data for seasons:", paste(seasons, collapse = ", "), "\n")
  
  # Load play-by-play data
  pbp_data <- load_pbp(seasons = seasons)
  
  # Load schedules
  schedules <- load_schedules(seasons = seasons)
  
  # Load team stats
  team_stats <- load_team_stats(seasons = seasons)
  
  cat("Data loaded successfully!\n")
  cat("Play-by-play records:", nrow(pbp_data), "\n")
  cat("Schedule records:", nrow(schedules), "\n")
  cat("Team stats records:", nrow(team_stats), "\n")
  
  return(list(
    pbp = pbp_data,
    schedules = schedules,
    team_stats = team_stats
  ))
}

#' Extract game-level statistics from play-by-play data
#' @param pbp_data Play-by-play data from nflreadr
#' @return Data frame with game-level statistics
extract_game_stats <- function(pbp_data) {
  cat("Extracting game-level statistics...\n")
  
  game_stats <- pbp_data %>%
    filter(!is.na(home_team), !is.na(away_team)) %>%
    group_by(game_id, season, week, home_team, away_team, game_date) %>%
    summarise(
      # Final scores
      home_score = max(home_score, na.rm = TRUE),
      away_score = max(away_score, na.rm = TRUE),
      
      # Offensive stats
      home_total_yards = sum(yards_gained[posteam == home_team], na.rm = TRUE),
      away_total_yards = sum(yards_gained[posteam == away_team], na.rm = TRUE),
      
      # Passing stats
      home_pass_yards = sum(yards_gained[posteam == home_team & pass == 1], na.rm = TRUE),
      away_pass_yards = sum(yards_gained[posteam == away_team & pass == 1], na.rm = TRUE),
      
      # Rushing stats
      home_rush_yards = sum(yards_gained[posteam == home_team & rush == 1], na.rm = TRUE),
      away_rush_yards = sum(yards_gained[posteam == away_team & rush == 1], na.rm = TRUE),
      
      # Turnovers
      home_turnovers = sum(interception[posteam == home_team], na.rm = TRUE) + 
                      sum(fumble_lost[posteam == home_team], na.rm = TRUE),
      away_turnovers = sum(interception[posteam == away_team], na.rm = TRUE) + 
                      sum(fumble_lost[posteam == away_team], na.rm = TRUE),
      
      # Third down conversions
      home_third_down_conv = sum(third_down_converted[posteam == home_team], na.rm = TRUE),
      away_third_down_conv = sum(third_down_converted[posteam == away_team], na.rm = TRUE),
      home_third_down_att = sum(third_down_attempt[posteam == home_team], na.rm = TRUE),
      away_third_down_att = sum(third_down_attempt[posteam == away_team], na.rm = TRUE),
      
      # Penalties
      home_penalties = sum(penalty[posteam == home_team], na.rm = TRUE),
      away_penalties = sum(penalty[posteam == away_team], na.rm = TRUE),
      
      # Time of possession (approximate)
      home_plays = sum(posteam == home_team, na.rm = TRUE),
      away_plays = sum(posteam == away_team, na.rm = TRUE),
      
      .groups = 'drop'
    ) %>%
    mutate(
      # Calculate derived metrics
      home_third_down_pct = ifelse(home_third_down_att > 0, home_third_down_conv / home_third_down_att, 0),
      away_third_down_pct = ifelse(away_third_down_att > 0, away_third_down_conv / away_third_down_att, 0),
      
      home_play_ratio = home_plays / (home_plays + away_plays),
      away_play_ratio = away_plays / (home_plays + away_plays),
      
      # Point differential
      home_point_diff = home_score - away_score,
      away_point_diff = away_score - home_score,
      
      # Total points
      total_points = home_score + away_score
    ) %>%
    filter(!is.na(home_score), !is.na(away_score))
  
  cat("Game statistics extracted:", nrow(game_stats), "games\n")
  return(game_stats)
}

# =============================================================================
# FEATURE ENGINEERING FUNCTIONS
# =============================================================================

#' Calculate rolling averages for team performance
#' @param game_stats Game-level statistics
#' @param window Number of games to include in rolling average
#' @return Data frame with rolling averages added
add_rolling_averages <- function(game_stats, window = 4) {
  cat("Calculating rolling averages (window =", window, "games)...\n")
  
  # Function to calculate rolling stats for a team
  calculate_team_rolling <- function(team_data, team_col, window) {
    team_data %>%
      arrange(game_date) %>%
      mutate(
        rolling_off_yards = zoo::rollmean(!!sym(paste0(team_col, "_total_yards")), 
                                        k = window, fill = NA, align = "right"),
        rolling_pass_yards = zoo::rollmean(!!sym(paste0(team_col, "_pass_yards")), 
                                         k = window, fill = NA, align = "right"),
        rolling_rush_yards = zoo::rollmean(!!sym(paste0(team_col, "_rush_yards")), 
                                         k = window, fill = NA, align = "right"),
        rolling_turnovers = zoo::rollmean(!!sym(paste0(team_col, "_turnovers")), 
                                        k = window, fill = NA, align = "right"),
        rolling_third_down_pct = zoo::rollmean(!!sym(paste0(team_col, "_third_down_pct")), 
                                             k = window, fill = NA, align = "right"),
        rolling_points = zoo::rollmean(!!sym(paste0(team_col, "_score")), 
                                     k = window, fill = NA, align = "right")
      )
  }
  
  # Calculate rolling averages for home teams
  home_rolling <- game_stats %>%
    group_by(home_team) %>%
    calculate_team_rolling("home", window) %>%
    ungroup()
  
  # Calculate rolling averages for away teams
  away_rolling <- game_stats %>%
    group_by(away_team) %>%
    calculate_team_rolling("away", window) %>%
    ungroup()
  
  # Merge the rolling averages back
  result <- home_rolling %>%
    left_join(away_rolling %>% 
              select(game_id, away_team, 
                     away_rolling_off_yards = rolling_off_yards,
                     away_rolling_pass_yards = rolling_pass_yards,
                     away_rolling_rush_yards = rolling_rush_yards,
                     away_rolling_turnovers = rolling_turnovers,
                     away_rolling_third_down_pct = rolling_third_down_pct,
                     away_rolling_points = rolling_points),
              by = c("game_id", "away_team")) %>%
    # Rename home team rolling stats
    rename(
      home_rolling_off_yards = rolling_off_yards,
      home_rolling_pass_yards = rolling_pass_yards,
      home_rolling_rush_yards = rolling_rush_yards,
      home_rolling_turnovers = rolling_turnovers,
      home_rolling_third_down_pct = rolling_third_down_pct,
      home_rolling_points = rolling_points
    )
  
  cat("Rolling averages calculated\n")
  return(result)
}

#' Add additional features for prediction
#' @param game_stats Game-level statistics with rolling averages
#' @return Data frame with additional features
add_prediction_features <- function(game_stats) {
  cat("Adding prediction features...\n")
  
  result <- game_stats %>%
    mutate(
      # Home field advantage (typically 2-3 points)
      home_field_advantage = 2.5,
      
      # Strength of schedule (simplified)
      home_sos = 0,  # Placeholder - would need more complex calculation
      away_sos = 0,  # Placeholder
      
      # Weather factors (simplified)
      weather_factor = 1,  # Placeholder - would need weather data
      
      # Rest days (simplified)
      home_rest_days = 7,  # Placeholder - would need to calculate actual rest
      away_rest_days = 7,  # Placeholder
      
      # Recent form (last 3 games)
      home_recent_form = case_when(
        !is.na(home_rolling_points) ~ home_rolling_points,
        TRUE ~ 20  # Default average
      ),
      away_recent_form = case_when(
        !is.na(away_rolling_points) ~ away_rolling_points,
        TRUE ~ 20  # Default average
      ),
      
      # Offensive efficiency
      home_off_efficiency = home_total_yards / (home_plays + 1),
      away_off_efficiency = away_total_yards / (away_plays + 1),
      
      # Defensive efficiency (inverse of opponent efficiency)
      home_def_efficiency = 1 / (away_off_efficiency + 1),
      away_def_efficiency = 1 / (home_off_efficiency + 1)
    )
  
  cat("Prediction features added\n")
  return(result)
}

# =============================================================================
# MODEL TRAINING FUNCTIONS
# =============================================================================

#' Train multiple models and select the best one
#' @param train_data Training dataset
#' @return List containing trained models and performance metrics
train_models <- function(train_data) {
  cat("Training prediction models...\n")
  
  # Define features for prediction
  features <- c(
    "home_rolling_off_yards", "away_rolling_off_yards",
    "home_rolling_pass_yards", "away_rolling_pass_yards", 
    "home_rolling_rush_yards", "away_rolling_rush_yards",
    "home_rolling_turnovers", "away_rolling_turnovers",
    "home_rolling_third_down_pct", "away_rolling_third_down_pct",
    "home_rolling_points", "away_rolling_points",
    "home_field_advantage", "home_recent_form", "away_recent_form",
    "home_off_efficiency", "away_off_efficiency",
    "home_def_efficiency", "away_def_efficiency"
  )
  
  # Remove rows with missing values
  clean_data <- train_data %>%
    select(all_of(features), home_score, away_score, total_points) %>%
    filter(complete.cases(.))
  
  cat("Training data points:", nrow(clean_data), "\n")
  
  # Train models
  models <- list()
  
  # Linear Regression
  cat("Training Linear Regression...\n")
  models$lm_home <- lm(home_score ~ ., data = clean_data %>% select(-away_score, -total_points))
  models$lm_away <- lm(away_score ~ ., data = clean_data %>% select(-home_score, -total_points))
  models$lm_total <- lm(total_points ~ ., data = clean_data %>% select(-home_score, -away_score))
  
  # Random Forest
  cat("Training Random Forest...\n")
  models$rf_home <- randomForest(home_score ~ ., data = clean_data %>% select(-away_score, -total_points))
  models$rf_away <- randomForest(away_score ~ ., data = clean_data %>% select(-home_score, -total_points))
  models$rf_total <- randomForest(total_points ~ ., data = clean_data %>% select(-home_score, -away_score))
  
  cat("Model training completed!\n")
  return(models)
}

#' Evaluate model performance
#' @param models Trained models
#' @param test_data Test dataset
#' @return Data frame with performance metrics
evaluate_models <- function(models, test_data) {
  cat("Evaluating model performance...\n")
  
  # Prepare test data
  features <- names(models$lm_home$coefficients)[-1]  # Remove intercept
  test_clean <- test_data %>%
    select(all_of(features), home_score, away_score, total_points) %>%
    filter(complete.cases(.))
  
  if (nrow(test_clean) == 0) {
    cat("Warning: No complete test cases available\n")
    return(data.frame())
  }
  
  # Make predictions
  predictions <- data.frame(
    actual_home = test_clean$home_score,
    actual_away = test_clean$away_score,
    actual_total = test_clean$total_points,
    
    lm_home = predict(models$lm_home, test_clean),
    lm_away = predict(models$lm_away, test_clean),
    lm_total = predict(models$lm_total, test_clean),
    
    rf_home = predict(models$rf_home, test_clean),
    rf_away = predict(models$rf_away, test_clean),
    rf_total = predict(models$rf_total, test_clean)
  )
  
  # Calculate metrics
  metrics <- data.frame(
    Model = c("Linear Regression", "Random Forest"),
    Home_MAE = c(
      mean(abs(predictions$actual_home - predictions$lm_home)),
      mean(abs(predictions$actual_home - predictions$rf_home))
    ),
    Away_MAE = c(
      mean(abs(predictions$actual_away - predictions$lm_away)),
      mean(abs(predictions$actual_away - predictions$rf_away))
    ),
    Total_MAE = c(
      mean(abs(predictions$actual_total - predictions$lm_total)),
      mean(abs(predictions$actual_total - predictions$rf_total))
    ),
    Home_RMSE = c(
      sqrt(mean((predictions$actual_home - predictions$lm_home)^2)),
      sqrt(mean((predictions$actual_home - predictions$rf_home)^2))
    ),
    Away_RMSE = c(
      sqrt(mean((predictions$actual_away - predictions$lm_away)^2)),
      sqrt(mean((predictions$actual_away - predictions$rf_away)^2))
    ),
    Total_RMSE = c(
      sqrt(mean((predictions$actual_total - predictions$lm_total)^2)),
      sqrt(mean((predictions$actual_total - predictions$rf_total)^2))
    )
  )
  
  print(metrics)
  return(list(predictions = predictions, metrics = metrics))
}

# =============================================================================
# PREDICTION FUNCTIONS
# =============================================================================

#' Predict scores for upcoming games
#' @param models Trained models
#' @param upcoming_games Data frame with upcoming games
#' @param team_stats Current team statistics
#' @return Data frame with predictions
predict_upcoming_games <- function(models, upcoming_games, team_stats) {
  cat("Predicting scores for upcoming games...\n")
  
  if (nrow(upcoming_games) == 0) {
    cat("No upcoming games found\n")
    return(data.frame())
  }
  
  # Prepare features for upcoming games
  # For simplicity, we'll use season averages for teams
  team_averages <- team_stats %>%
    group_by(team) %>%
    summarise(
      avg_off_yards = mean(total_offensive_yards, na.rm = TRUE),
      avg_pass_yards = mean(passing_yards, na.rm = TRUE),
      avg_rush_yards = mean(rushing_yards, na.rm = TRUE),
      avg_turnovers = mean(turnovers, na.rm = TRUE),
      avg_third_down_pct = mean(third_down_pct, na.rm = TRUE),
      avg_points = mean(team_score, na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Create prediction dataset
  pred_data <- upcoming_games %>%
    left_join(team_averages, by = c("home_team" = "team")) %>%
    left_join(team_averages, by = c("away_team" = "team"), suffix = c("_home", "_away")) %>%
    mutate(
      home_rolling_off_yards = avg_off_yards_home,
      away_rolling_off_yards = avg_off_yards_away,
      home_rolling_pass_yards = avg_pass_yards_home,
      away_rolling_pass_yards = avg_pass_yards_away,
      home_rolling_rush_yards = avg_rush_yards_home,
      away_rolling_rush_yards = avg_rush_yards_away,
      home_rolling_turnovers = avg_turnovers_home,
      away_rolling_turnovers = avg_turnovers_away,
      home_rolling_third_down_pct = avg_third_down_pct_home,
      away_rolling_third_down_pct = avg_third_down_pct_away,
      home_rolling_points = avg_points_home,
      away_rolling_points = avg_points_away,
      home_field_advantage = 2.5,
      home_recent_form = avg_points_home,
      away_recent_form = avg_points_away,
      home_off_efficiency = avg_off_yards_home / 70,  # Approximate plays per game
      away_off_efficiency = avg_off_yards_away / 70,
      home_def_efficiency = 1 / (away_off_efficiency + 1),
      away_def_efficiency = 1 / (home_off_efficiency + 1)
    ) %>%
    select(all_of(names(models$lm_home$coefficients)[-1]))
  
  # Make predictions
  predictions <- data.frame(
    game_id = upcoming_games$game_id,
    home_team = upcoming_games$home_team,
    away_team = upcoming_games$away_team,
    game_date = upcoming_games$game_date,
    week = upcoming_games$week,
    
    # Linear Regression predictions
    lm_home_score = predict(models$lm_home, pred_data),
    lm_away_score = predict(models$lm_away, pred_data),
    lm_total_points = predict(models$lm_total, pred_data),
    
    # Random Forest predictions
    rf_home_score = predict(models$rf_home, pred_data),
    rf_away_score = predict(models$rf_away, pred_data),
    rf_total_points = predict(models$rf_total, pred_data)
  ) %>%
    mutate(
      # Ensemble prediction (average of both models)
      predicted_home_score = round((lm_home_score + rf_home_score) / 2, 1),
      predicted_away_score = round((lm_away_score + rf_away_score) / 2, 1),
      predicted_total = round((lm_total_points + rf_total_points) / 2, 1),
      
      # Confidence based on model agreement
      confidence = 1 - abs(lm_home_score - rf_home_score) / max(lm_home_score, rf_home_score, 1),
      
      # Predicted winner
      predicted_winner = ifelse(predicted_home_score > predicted_away_score, 
                               home_team, away_team),
      predicted_spread = round(predicted_home_score - predicted_away_score, 1)
    )
  
  cat("Predictions completed for", nrow(predictions), "games\n")
  return(predictions)
}

# =============================================================================
# VISUALIZATION FUNCTIONS
# =============================================================================

#' Create prediction visualization
#' @param predictions Prediction results
#' @return Plotly visualization
create_prediction_plot <- function(predictions) {
  if (nrow(predictions) == 0) {
    cat("No predictions to visualize\n")
    return(NULL)
  }
  
  # Create a bar chart of predicted scores
  plot_data <- predictions %>%
    select(home_team, away_team, predicted_home_score, predicted_away_score, week) %>%
    pivot_longer(cols = c(predicted_home_score, predicted_away_score),
                names_to = "team_type", values_to = "predicted_score") %>%
    mutate(
      team = ifelse(team_type == "predicted_home_score", home_team, away_team),
      team_type = ifelse(team_type == "predicted_home_score", "Home", "Away"),
      game_label = paste(away_team, "@", home_team)
    )
  
  p <- plot_ly(plot_data, x = ~game_label, y = ~predicted_score, 
               color = ~team_type, type = "bar",
               text = ~paste(team, "<br>Predicted:", predicted_score),
               hoverinfo = "text") %>%
    layout(
      title = "NFL Game Score Predictions",
      xaxis = list(title = "Games", tickangle = 45),
      yaxis = list(title = "Predicted Score"),
      barmode = "group"
    )
  
  return(p)
}

# =============================================================================
# MAIN EXECUTION FUNCTION
# =============================================================================

#' Main function to run the NFL score prediction program
#' @param seasons Vector of seasons to use for training
#' @param prediction_season Season to predict (current year)
#' @return List containing models, predictions, and performance metrics
run_nfl_predictor <- function(seasons = 2020:2024, prediction_season = 2025) {
  cat("=== NFL Score Prediction Program ===\n")
  cat("Training seasons:", paste(seasons, collapse = ", "), "\n")
  cat("Prediction season:", prediction_season, "\n\n")
  
  # Step 1: Load historical data
  data <- load_historical_data(seasons)
  
  # Step 2: Extract game statistics
  game_stats <- extract_game_stats(data$pbp)
  
  # Step 3: Add rolling averages
  game_stats <- add_rolling_averages(game_stats, window = 4)
  
  # Step 4: Add prediction features
  game_stats <- add_prediction_features(game_stats)
  
  # Step 5: Split data for training and testing
  set.seed(42)
  train_index <- createDataPartition(game_stats$home_score, p = 0.8, list = FALSE)
  train_data <- game_stats[train_index, ]
  test_data <- game_stats[-train_index, ]
  
  cat("Training data:", nrow(train_data), "games\n")
  cat("Test data:", nrow(test_data), "games\n\n")
  
  # Step 6: Train models
  models <- train_models(train_data)
  
  # Step 7: Evaluate models
  evaluation <- evaluate_models(models, test_data)
  
  # Step 8: Load upcoming games
  upcoming_games <- data$schedules %>%
    filter(season == prediction_season, game_date >= Sys.Date()) %>%
    arrange(game_date)
  
  # Step 9: Make predictions
  predictions <- predict_upcoming_games(models, upcoming_games, data$team_stats)
  
  # Step 10: Create visualization
  plot <- create_prediction_plot(predictions)
  
  cat("\n=== Prediction Summary ===\n")
  if (nrow(predictions) > 0) {
    print(predictions %>% select(home_team, away_team, predicted_home_score, 
                                predicted_away_score, predicted_winner, predicted_spread))
  } else {
    cat("No upcoming games found for prediction\n")
  }
  
  return(list(
    models = models,
    predictions = predictions,
    evaluation = evaluation,
    plot = plot,
    game_stats = game_stats
  ))
}

# =============================================================================
# EXAMPLE USAGE
# =============================================================================

if (interactive()) {
  # Run the predictor
  results <- run_nfl_predictor(seasons = 2020:2024, prediction_season = 2025)
  
  # Display the plot
  if (!is.null(results$plot)) {
    print(results$plot)
  }
  
  # Save predictions to CSV
  if (nrow(results$predictions) > 0) {
    write.csv(results$predictions, "nfl_predictions.csv", row.names = FALSE)
    cat("\nPredictions saved to 'nfl_predictions.csv'\n")
  }
}

cat("\nNFL Score Prediction Program loaded successfully!\n")
cat("Usage: results <- run_nfl_predictor(seasons = 2020:2024, prediction_season = 2025)\n")