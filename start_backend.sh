#!/bin/bash
# Quick start script for the FastAPI backend

echo "🚀 Starting CropSense AI Backend..."
echo ""

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "   Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
echo "📦 Activating virtual environment..."
source .venv/bin/activate

# Check if requirements are installed
if ! python -c "import fastapi" 2>/dev/null; then
    echo "📥 Installing dependencies..."
    pip install -r requirements.txt
fi

# Check if model exists
if [ ! -f "outputs/best_MobileNetV2.keras" ]; then
    echo "⚠️  Warning: Model file not found at outputs/best_MobileNetV2.keras"
    echo "   The backend will still start but predictions may not work."
    echo "   Consider uploading model to Hugging Face (see HUGGINGFACE_SETUP.md)"
fi

echo ""
echo "✅ Starting server on http://localhost:8000"
echo "   Press Ctrl+C to stop"
echo ""
echo "📝 Test endpoints:"
echo "   - Health: curl http://localhost:8000/"
echo "   - Docs: http://localhost:8000/docs"
echo ""

# Start the server
python main.py
