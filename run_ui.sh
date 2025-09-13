#!/bin/bash
# Launch script for NFL Score Prediction Shiny App
# This script provides multiple ways to run the application

echo "🏈 NFL Score Prediction App Launcher"
echo "===================================="
echo ""

# Check if R is installed
if ! command -v R &> /dev/null; then
    echo "❌ Error: R is not installed or not in PATH"
    echo "Please install R from https://cran.r-project.org/"
    exit 1
fi

echo "✅ R is installed"

# Check if we're in the right directory
if [ ! -f "app.R" ]; then
    echo "❌ Error: app.R not found in current directory"
    echo "Please navigate to the directory containing the app files"
    exit 1
fi

echo "✅ App files found"

# Function to run the app
run_app() {
    echo "🚀 Launching NFL Score Prediction App..."
    echo "The app will open in your default web browser"
    echo "Press Ctrl+C to stop the app"
    echo ""
    
    Rscript launch_app.R
}

# Function to install dependencies only
install_deps() {
    echo "📦 Installing dependencies..."
    Rscript -e "
    required_packages <- c('shiny', 'shinydashboard', 'DT', 'plotly', 'tidyverse', 'nflreadr', 'caret', 'randomForest', 'shinycssloaders', 'shinyWidgets', 'zoo', 'lubridate', 'stringr')
    missing_packages <- required_packages[!required_packages %in% installed.packages()[,'Package']]
    if (length(missing_packages) > 0) {
        install.packages(missing_packages, repos = 'https://cran.r-project.org')
        cat('✅ All packages installed successfully\n')
    } else {
        cat('✅ All packages already installed\n')
    }
    "
}

# Function to run in background
run_background() {
    echo "🚀 Starting app in background..."
    nohup Rscript launch_app.R > app.log 2>&1 &
    APP_PID=$!
    echo "App started with PID: $APP_PID"
    echo "Log file: app.log"
    echo "To stop the app, run: kill $APP_PID"
    echo "The app should be available at: http://localhost:3838"
}

# Function to stop background app
stop_app() {
    echo "🛑 Stopping background app..."
    pkill -f "Rscript launch_app.R"
    echo "App stopped"
}

# Function to check app status
check_status() {
    if pgrep -f "Rscript launch_app.R" > /dev/null; then
        echo "✅ App is running"
        echo "Available at: http://localhost:3838"
    else
        echo "❌ App is not running"
    fi
}

# Main menu
case "${1:-}" in
    "install")
        install_deps
        ;;
    "background")
        run_background
        ;;
    "stop")
        stop_app
        ;;
    "status")
        check_status
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no command)  - Run the app interactively"
        echo "  install       - Install dependencies only"
        echo "  background    - Run the app in background"
        echo "  stop          - Stop background app"
        echo "  status        - Check if app is running"
        echo "  help          - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Run app normally"
        echo "  $0 install           # Install dependencies"
        echo "  $0 background        # Run in background"
        echo "  $0 stop              # Stop background app"
        ;;
    "")
        run_app
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac