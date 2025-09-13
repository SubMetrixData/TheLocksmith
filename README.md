# 🏈 NFL Score Prediction Program

A comprehensive R program with a beautiful web interface that predicts NFL game scores using the `nflreadr` library and machine learning techniques.

## ✨ Features

- **🎨 Modern Web Interface**: Beautiful, responsive Shiny dashboard
- **📊 Interactive Visualizations**: Dynamic charts and data tables
- **🤖 Advanced ML Models**: Linear Regression, Random Forest, and Ensemble methods
- **📈 Real-time Updates**: Live prediction generation and model performance tracking
- **⚙️ Customizable Settings**: Adjustable model parameters and data sources
- **📱 Mobile Responsive**: Works perfectly on desktop, tablet, and mobile
- **📥 Export Capabilities**: Download predictions in multiple formats
- **🎯 Historical Analysis**: Uses play-by-play data from multiple NFL seasons
- **🔧 Advanced Feature Engineering**: Rolling averages, efficiency metrics, and game context

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

## 🚀 Quick Start

### Option 1: Web Interface (Recommended)

```bash
# Make the script executable
chmod +x run_ui.sh

# Launch the web app
./run_ui.sh

# Or install dependencies first
./run_ui.sh install
./run_ui.sh
```

The app will open in your browser at `http://localhost:3838`

### Option 2: R Console

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

### Option 3: Command Line

```bash
# Run the script directly
Rscript nfl_score_predictor.R

# Or run the example
Rscript run_example.R
```

## 🎨 Web Interface Features

### Dashboard
- **Overview Stats**: Games analyzed, model accuracy, upcoming games
- **Recent Predictions**: Quick preview of latest predictions
- **Quick Start**: One-click prediction generation

### Predictions Tab
- **Interactive Table**: Sortable, searchable predictions table
- **Visual Charts**: Bar charts showing predicted scores
- **Game Cards**: Beautiful individual game predictions
- **Export Options**: Download predictions as CSV/Excel

### Model Performance Tab
- **Performance Metrics**: MAE, RMSE, and accuracy scores
- **Comparison Charts**: Side-by-side model performance
- **Accuracy Visualization**: Visual representation of prediction quality

### Settings Tab
- **Model Parameters**: Adjust training/test split, CV folds
- **Feature Engineering**: Toggle rolling averages, efficiency metrics
- **Data Sources**: Include/exclude playoffs, preseason games
- **Export Settings**: Choose format and included data

### About Tab
- **Methodology**: Detailed explanation of the prediction system
- **Technical Details**: Information about models and data sources
- **Accuracy Metrics**: Expected performance benchmarks

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

## 🛠️ Troubleshooting

### Common Issues

1. **Package Installation Errors**
   ```bash
   # Try installing dependencies manually
   ./run_ui.sh install
   
   # Or in R console
   install.packages("nflreadr", repos = "https://cran.r-project.org")
   ```

2. **Web App Won't Start**
   ```bash
   # Check if port 3838 is available
   lsof -i :3838
   
   # Try a different port
   Rscript -e "runApp('app.R', port = 3839)"
   ```

3. **Data Loading Issues**
   ```r
   # Check internet connection
   # nflreadr requires internet access
   ```

4. **Memory Issues**
   ```r
   # Reduce the number of seasons for training
   results <- run_nfl_predictor(seasons = 2022:2024)
   ```

### Performance Tips

- Use fewer seasons for faster execution
- Reduce rolling window size for quicker processing
- Run in background: `./run_ui.sh background`
- Check app status: `./run_ui.sh status`
- Stop background app: `./run_ui.sh stop`

### Web Interface Tips

- **Refresh Data**: Use the refresh button to update predictions
- **Export Results**: Download predictions in your preferred format
- **Customize Settings**: Adjust model parameters in the Settings tab
- **Mobile View**: The interface is fully responsive for mobile devices

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