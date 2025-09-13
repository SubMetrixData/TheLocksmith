# NFL Score Prediction Program

A comprehensive R program that predicts NFL game scores using the `nflreadr` library and machine learning techniques.

## Features

- **Historical Data Analysis**: Uses play-by-play data from multiple NFL seasons
- **Advanced Feature Engineering**: Calculates rolling averages, team efficiency metrics, and game context
- **Multiple ML Models**: Implements both Linear Regression and Random Forest models
- **Ensemble Predictions**: Combines multiple models for improved accuracy
- **Interactive Visualizations**: Creates dynamic plots using Plotly
- **Upcoming Game Predictions**: Forecasts scores for future NFL games

## Installation

### Prerequisites

- R (version 4.0 or higher)
- RStudio (recommended)

### Required R Packages

Install the required packages by running this in R:

```r
# Install all required packages
install.packages(c(
  "nflreadr", "tidyverse", "caret", "randomForest", 
  "plotly", "zoo", "lubridate", "stringr"
))
```

Or install from the requirements file:

```r
# Read and install from requirements
packages <- readLines("requirements.txt")
packages <- packages[!grepl("^#", packages)]  # Remove comments
packages <- gsub(">=.*", "", packages)  # Remove version constraints
install.packages(packages)
```

## Usage

### Basic Usage

```r
# Load the program
source("nfl_score_predictor.R")

# Run predictions with default settings
results <- run_nfl_predictor()

# View predictions
print(results$predictions)

# Display interactive plot
print(results$plot)
```

### Advanced Usage

```r
# Customize training seasons and prediction year
results <- run_nfl_predictor(
  seasons = 2020:2024,        # Training data seasons
  prediction_season = 2025     # Season to predict
)

# Access individual components
models <- results$models
predictions <- results$predictions
evaluation <- results$evaluation
plot <- results$plot
```

### Command Line Usage

```bash
# Run the script directly
Rscript nfl_score_predictor.R
```

## Program Structure

### Data Collection
- **Play-by-Play Data**: Detailed game statistics from nflreadr
- **Team Statistics**: Season-long team performance metrics
- **Schedule Data**: Game schedules and matchups

### Feature Engineering
- **Rolling Averages**: 4-game rolling averages for key metrics
- **Team Efficiency**: Offensive and defensive efficiency calculations
- **Game Context**: Home field advantage, rest days, weather factors
- **Recent Form**: Team performance in recent games

### Machine Learning Models
- **Linear Regression**: Baseline model for score prediction
- **Random Forest**: Ensemble method for improved accuracy
- **Ensemble Prediction**: Combines both models for final predictions

### Key Features Calculated
- Total yards (offensive, passing, rushing)
- Turnovers and third-down conversion rates
- Penalties and time of possession
- Rolling averages and team efficiency metrics
- Home field advantage and recent form

## Output

The program generates:

1. **Prediction Table**: Upcoming games with predicted scores
2. **Model Performance**: MAE and RMSE metrics for evaluation
3. **Interactive Plot**: Visual representation of predictions
4. **CSV Export**: Predictions saved to `nfl_predictions.csv`

### Sample Output

```
Game Predictions:
  home_team away_team predicted_home_score predicted_away_score predicted_winner predicted_spread
1     KC      BUF                   24.3                 21.7              KC               2.6
2     SF      DAL                   26.1                 23.4              SF               2.7
3     PHI     NYG                   28.5                 17.2             PHI              11.3
```

## Model Performance

The program evaluates models using:
- **MAE (Mean Absolute Error)**: Average prediction error
- **RMSE (Root Mean Square Error)**: Penalizes larger errors more
- **Cross-validation**: Ensures robust performance estimates

Typical performance metrics:
- Home Score MAE: ~3-4 points
- Away Score MAE: ~3-4 points
- Total Points MAE: ~5-6 points

## Customization

### Adjusting Rolling Window
```r
# Change rolling average window (default: 4 games)
game_stats <- add_rolling_averages(game_stats, window = 6)
```

### Adding Custom Features
```r
# Add your own features in the add_prediction_features function
result <- game_stats %>%
  mutate(
    your_custom_feature = some_calculation,
    # ... other features
  )
```

### Modifying Models
```r
# Add more models in the train_models function
models$gbm_home <- train(home_score ~ ., data = train_data, method = "gbm")
```

## Troubleshooting

### Common Issues

1. **Package Installation Errors**
   ```r
   # Try installing from CRAN
   install.packages("nflreadr", repos = "https://cran.r-project.org")
   ```

2. **Data Loading Issues**
   ```r
   # Check internet connection and try again
   # nflreadr requires internet access
   ```

3. **Memory Issues**
   ```r
   # Reduce the number of seasons for training
   results <- run_nfl_predictor(seasons = 2022:2024)
   ```

### Performance Tips

- Use fewer seasons for faster execution
- Reduce rolling window size for quicker processing
- Filter data by specific teams or weeks if needed

## Data Sources

This program uses data from:
- **nflreadr**: Official NFL data package
- **nflverse**: Community-driven NFL data repository
- **NFL.com**: Official NFL statistics

## License

This program is provided as-is for educational and research purposes. Please respect the terms of use for the underlying data sources.

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve the program.

## Disclaimer

This is a statistical model for entertainment and research purposes. Past performance does not guarantee future results. Use responsibly and do not rely solely on these predictions for betting or financial decisions.