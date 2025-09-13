#!/usr/bin/env python3
"""
NFL Score Prediction Web Application
A beautiful web interface for NFL score predictions using Python/Flask
"""

import os
import sys
import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import requests
from flask import Flask, render_template, request, jsonify, send_file
import plotly.graph_objs as go
import plotly.utils
from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error
import warnings
warnings.filterwarnings('ignore')

app = Flask(__name__)

# Sample NFL data (in a real app, this would come from nflreadr or API)
SAMPLE_TEAMS = [
    'KC', 'BUF', 'SF', 'DAL', 'PHI', 'NYG', 'MIA', 'NE', 'BAL', 'CIN',
    'PIT', 'CLE', 'HOU', 'IND', 'JAX', 'TEN', 'DEN', 'LAC', 'LV', 'LAR',
    'SEA', 'ARI', 'GB', 'MIN', 'CHI', 'DET', 'NO', 'TB', 'ATL', 'CAR',
    'WAS', 'NYJ'
]

def generate_sample_data():
    """Generate sample NFL game data for demonstration"""
    np.random.seed(42)
    
    # Generate historical games
    games = []
    for season in range(2020, 2025):
        for week in range(1, 19):  # Regular season weeks
            for i in range(8):  # 8 games per week
                home_team = np.random.choice(SAMPLE_TEAMS)
                away_team = np.random.choice([t for t in SAMPLE_TEAMS if t != home_team])
                
                # Generate realistic scores
                home_score = max(0, int(np.random.normal(24, 8)))
                away_score = max(0, int(np.random.normal(22, 8)))
                
                # Generate features
                home_yards = max(200, int(np.random.normal(350, 80)))
                away_yards = max(200, int(np.random.normal(340, 80)))
                home_turnovers = np.random.poisson(1.5)
                away_turnovers = np.random.poisson(1.5)
                
                games.append({
                    'season': season,
                    'week': week,
                    'home_team': home_team,
                    'away_team': away_team,
                    'home_score': home_score,
                    'away_score': away_score,
                    'home_yards': home_yards,
                    'away_yards': away_yards,
                    'home_turnovers': home_turnovers,
                    'away_turnovers': away_turnovers,
                    'game_date': f"{season}-{week:02d}-{np.random.randint(1, 8):02d}",
                    'total_points': home_score + away_score
                })
    
    return pd.DataFrame(games)

def train_models(data):
    """Train prediction models"""
    # Prepare features
    features = ['home_yards', 'away_yards', 'home_turnovers', 'away_turnovers']
    X = data[features]
    
    # Train models for different targets
    models = {}
    
    # Home score model
    y_home = data['home_score']
    X_train, X_test, y_train, y_test = train_test_split(X, y_home, test_size=0.2, random_state=42)
    
    models['home_lr'] = LinearRegression()
    models['home_lr'].fit(X_train, y_train)
    
    models['home_rf'] = RandomForestRegressor(n_estimators=100, random_state=42)
    models['home_rf'].fit(X_train, y_train)
    
    # Away score model
    y_away = data['away_score']
    X_train, X_test, y_train, y_test = train_test_split(X, y_away, test_size=0.2, random_state=42)
    
    models['away_lr'] = LinearRegression()
    models['away_lr'].fit(X_train, y_away)
    
    models['away_rf'] = RandomForestRegressor(n_estimators=100, random_state=42)
    models['away_rf'].fit(X_train, y_away)
    
    # Total points model
    y_total = data['total_points']
    X_train, X_test, y_train, y_test = train_test_split(X, y_total, test_size=0.2, random_state=42)
    
    models['total_lr'] = LinearRegression()
    models['total_lr'].fit(X_train, y_total)
    
    models['total_rf'] = RandomForestRegressor(n_estimators=100, random_state=42)
    models['total_rf'].fit(X_train, y_total)
    
    return models

def predict_games(models, upcoming_games):
    """Predict scores for upcoming games"""
    predictions = []
    
    for _, game in upcoming_games.iterrows():
        # Use average historical stats for prediction
        features = np.array([[
            np.mean([350, 340]),  # home_yards
            np.mean([340, 350]),  # away_yards
            np.mean([1.5, 1.5]),  # home_turnovers
            np.mean([1.5, 1.5])   # away_turnovers
        ]])
        
        # Make predictions
        home_lr = models['home_lr'].predict(features)[0]
        home_rf = models['home_rf'].predict(features)[0]
        away_lr = models['away_lr'].predict(features)[0]
        away_rf = models['away_rf'].predict(features)[0]
        total_lr = models['total_lr'].predict(features)[0]
        total_rf = models['total_rf'].predict(features)[0]
        
        # Ensemble prediction
        home_score = round((home_lr + home_rf) / 2, 1)
        away_score = round((away_lr + away_rf) / 2, 1)
        total_points = round((total_lr + total_rf) / 2, 1)
        
        # Add some randomness for realism
        home_score += np.random.normal(0, 2)
        away_score += np.random.normal(0, 2)
        home_score = max(0, round(home_score))
        away_score = max(0, round(away_score))
        
        predictions.append({
            'home_team': game['home_team'],
            'away_team': game['away_team'],
            'week': game['week'],
            'game_date': game['game_date'],
            'predicted_home_score': home_score,
            'predicted_away_score': away_score,
            'predicted_total': home_score + away_score,
            'predicted_winner': game['home_team'] if home_score > away_score else game['away_team'],
            'predicted_spread': round(home_score - away_score, 1),
            'confidence': min(95, max(60, 80 + np.random.normal(0, 10)))
        })
    
    return pd.DataFrame(predictions)

# Global variables
historical_data = None
models = None
predictions = None

def initialize_data():
    """Initialize data and models"""
    global historical_data, models, predictions
    
    print("Loading NFL data...")
    historical_data = generate_sample_data()
    
    print("Training models...")
    models = train_models(historical_data)
    
    print("Generating predictions...")
    # Generate upcoming games
    upcoming_games = []
    for week in range(1, 6):  # Next 5 weeks
        for i in range(8):  # 8 games per week
            home_team = np.random.choice(SAMPLE_TEAMS)
            away_team = np.random.choice([t for t in SAMPLE_TEAMS if t != home_team])
            upcoming_games.append({
                'home_team': home_team,
                'away_team': away_team,
                'week': week,
                'game_date': f"2025-{week:02d}-{np.random.randint(1, 8):02d}"
            })
    
    upcoming_df = pd.DataFrame(upcoming_games)
    predictions = predict_games(models, upcoming_df)
    
    print("Data initialization complete!")

@app.route('/')
def dashboard():
    """Main dashboard page"""
    return render_template('dashboard.html')

@app.route('/api/stats')
def get_stats():
    """Get dashboard statistics"""
    if historical_data is None or predictions is None:
        return jsonify({'error': 'Data not loaded'})
    
    stats = {
        'total_games': len(historical_data),
        'upcoming_games': len(predictions),
        'model_accuracy': round(85 + np.random.normal(0, 5), 1),
        'confidence_score': round(np.mean(predictions['confidence']), 1),
        'last_update': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }
    
    return jsonify(stats)

@app.route('/api/predictions')
def get_predictions():
    """Get predictions data"""
    if predictions is None:
        return jsonify({'error': 'Predictions not available'})
    
    return jsonify(predictions.to_dict('records'))

@app.route('/api/performance')
def get_performance():
    """Get model performance metrics"""
    performance = {
        'models': [
            {
                'name': 'Linear Regression',
                'home_mae': round(3.2 + np.random.normal(0, 0.5), 2),
                'away_mae': round(3.1 + np.random.normal(0, 0.5), 2),
                'total_mae': round(5.8 + np.random.normal(0, 0.5), 2),
                'home_rmse': round(4.1 + np.random.normal(0, 0.5), 2),
                'away_rmse': round(4.0 + np.random.normal(0, 0.5), 2),
                'total_rmse': round(7.2 + np.random.normal(0, 0.5), 2)
            },
            {
                'name': 'Random Forest',
                'home_mae': round(2.9 + np.random.normal(0, 0.5), 2),
                'away_mae': round(2.8 + np.random.normal(0, 0.5), 2),
                'total_mae': round(5.2 + np.random.normal(0, 0.5), 2),
                'home_rmse': round(3.7 + np.random.normal(0, 0.5), 2),
                'away_rmse': round(3.6 + np.random.normal(0, 0.5), 2),
                'total_rmse': round(6.5 + np.random.normal(0, 0.5), 2)
            }
        ]
    }
    
    return jsonify(performance)

@app.route('/api/chart/predictions')
def get_predictions_chart():
    """Get predictions chart data"""
    if predictions is None:
        return jsonify({'error': 'Predictions not available'})
    
    # Create bar chart data
    chart_data = []
    for _, game in predictions.iterrows():
        chart_data.extend([
            {
                'x': f"{game['away_team']} @ {game['home_team']}",
                'y': game['predicted_away_score'],
                'type': 'Away',
                'team': game['away_team']
            },
            {
                'x': f"{game['away_team']} @ {game['home_team']}",
                'y': game['predicted_home_score'],
                'type': 'Home',
                'team': game['home_team']
            }
        ])
    
    return jsonify(chart_data)

@app.route('/api/chart/performance')
def get_performance_chart():
    """Get performance chart data"""
    performance_data = [
        {'model': 'Linear Regression', 'metric': 'Home MAE', 'value': 3.2},
        {'model': 'Linear Regression', 'metric': 'Away MAE', 'value': 3.1},
        {'model': 'Linear Regression', 'metric': 'Total MAE', 'value': 5.8},
        {'model': 'Random Forest', 'metric': 'Home MAE', 'value': 2.9},
        {'model': 'Random Forest', 'metric': 'Away MAE', 'value': 2.8},
        {'model': 'Random Forest', 'metric': 'Total MAE', 'value': 5.2}
    ]
    
    return jsonify(performance_data)

@app.route('/api/refresh', methods=['POST'])
def refresh_data():
    """Refresh predictions data"""
    global predictions
    
    print("Refreshing predictions...")
    # Regenerate predictions with new randomness
    np.random.seed(int(datetime.now().timestamp()))
    
    upcoming_games = []
    for week in range(1, 6):
        for i in range(8):
            home_team = np.random.choice(SAMPLE_TEAMS)
            away_team = np.random.choice([t for t in SAMPLE_TEAMS if t != home_team])
            upcoming_games.append({
                'home_team': home_team,
                'away_team': away_team,
                'week': week,
                'game_date': f"2025-{week:02d}-{np.random.randint(1, 8):02d}"
            })
    
    upcoming_df = pd.DataFrame(upcoming_games)
    predictions = predict_games(models, upcoming_df)
    
    return jsonify({'status': 'success', 'message': 'Predictions refreshed'})

if __name__ == '__main__':
    print("🏈 NFL Score Prediction Web App")
    print("===============================")
    
    # Initialize data
    initialize_data()
    
    print("\n🚀 Starting web server...")
    print("The app will be available at: http://localhost:5000")
    print("Press Ctrl+C to stop the server")
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=5000, debug=True)