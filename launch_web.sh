#!/bin/bash
# Simple launcher for NFL Score Predictor Web Interface

echo "🏈 NFL Score Predictor Web Interface"
echo "===================================="
echo ""

# Check if Python is available
if command -v python3 &> /dev/null; then
    echo "✅ Python 3 is available"
    
    # Try to start a simple HTTP server
    echo "🚀 Starting web server..."
    echo "The app will be available at: http://localhost:8000"
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    # Start Python HTTP server
    python3 -m http.server 8000
else
    echo "❌ Python 3 not found"
    echo "Please install Python 3 or open the HTML file directly in your browser"
    echo ""
    echo "To open directly:"
    echo "1. Open nfl_predictor_simple.html in your web browser"
    echo "2. Or use any local web server"
    echo ""
    echo "Alternative methods:"
    echo "- Use 'python -m http.server 8000' (if Python 2 is available)"
    echo "- Use 'php -S localhost:8000' (if PHP is available)"
    echo "- Use any other local web server"
fi