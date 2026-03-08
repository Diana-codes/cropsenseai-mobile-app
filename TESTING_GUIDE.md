# Testing Guide - CropSense AI

This guide will help you test both the backend and Flutter mobile app.

## Prerequisites

1. **Python Backend Setup**
   ```bash
   # Activate virtual environment
   source .venv/bin/activate  # or: .venv\Scripts\activate on Windows
   
   # Install dependencies
   pip install -r requirements.txt
   ```

2. **Flutter Setup**
   ```bash
   # Check Flutter installation
   flutter doctor
   
   # Get Flutter dependencies
   flutter pub get
   ```

## Part 1: Testing the Backend (FastAPI)

### Step 1: Start the Backend Server

```bash
# Make sure you're in the project directory
cd ~/Desktop/cropsenseai-mobile-app

# Activate virtual environment
source .venv/bin/activate

# Start the server
python main.py
```

You should see:
```
✓ Model loaded successfully from outputs/best_MobileNetV2.keras
✓ Loaded class names from outputs/model_metadata.json: ['Healthy', 'Powdery', 'Rust']
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 2: Test Backend Endpoints

**Open a new terminal** (keep the backend running in the first one)

#### Test 1: Health Check
```bash
curl http://localhost:8000/
```

Expected response:
```json
{
  "status": "CropSense AI API is running",
  "version": "1.0.0",
  "model_loaded": true,
  "encoder_loaded": false
}
```

#### Test 2: Crop Disease Prediction
```bash
# Replace with path to an actual leaf image
curl -X POST http://localhost:8000/predict \
  -F "file=@/path/to/your/leaf_image.jpg"
```

Expected response:
```json
{
  "prediction": "Healthy",
  "confidence": 95.5,
  "weather": {
    "location": "Rwanda",
    "temperature": 24.1,
    "humidity": 60,
    "wind_speed": 13.7
  },
  "advice": {
    "crop": "Healthy",
    "advice": "Your crop appears healthy...",
    "additional_tips": [...]
  }
}
```

#### Test 3: AI Advisor Recommendations
```bash
curl -X POST http://localhost:8000/advisor \
  -H "Content-Type: application/json" \
  -d '{
    "province": "Eastern Province",
    "district": "Bugesera",
    "sector": "Gashora",
    "cell": "Biryogo",
    "village": "Akagera",
    "season": "Season A (Sept - Jan)",
    "landType": "Wetland"
  }'
```

Expected response:
```json
{
  "best_match": {
    "crop": "Rice",
    "match_score": 95,
    "weather": {...},
    "advice": {...}
  },
  "alternatives": [...]
}
```

#### Test 4: Weather Data
```bash
curl http://localhost:8000/weather?location=Rwanda
```

#### Test 5: Available Crops
```bash
curl http://localhost:8000/crops
```

## Part 2: Testing the Flutter Mobile App

### Option A: Run on Web (Easiest for Quick Testing)

```bash
# Make sure backend is running first!
# In a new terminal:
cd ~/Desktop/cropsenseai-mobile-app
flutter run -d chrome
```

This will:
- Open Chrome with your Flutter app
- Connect to `http://localhost:8000` (backend)

### Option B: Run on Android Emulator

1. **Start Android Emulator**
   ```bash
   # List available emulators
   flutter emulators
   
   # Launch an emulator
   flutter emulators --launch <emulator_id>
   ```

2. **Update API URL for Android**
   
   The app uses `http://localhost:8000` by default, but Android emulator needs `http://10.0.2.2:8000`
   
   Run with:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
   ```

### Option C: Run on Physical Device

1. **Enable USB Debugging** on your phone
2. **Connect via USB**
3. **Run:**
   ```bash
   flutter devices  # Check if device is detected
   flutter run
   ```

## Part 3: Testing Key Features

### Feature 1: Crop Health Scanner

1. Open the app
2. Navigate to "Crop Health Scanner"
3. Tap "Pick Image" or "Take Photo"
4. Select/upload a leaf image
5. Wait for prediction

**Expected Results:**
- ✅ Image preview shows
- ✅ Loading indicator appears
- ✅ Prediction displays (Healthy/Powdery/Rust)
- ✅ Confidence percentage shown
- ✅ Weather data displayed
- ✅ Agronomic advice shown

**Common Issues:**
- ❌ "Failed to analyze image" → Check backend is running
- ❌ Connection timeout → Check API URL (localhost vs 10.0.2.2)
- ❌ No prediction → Check model is loaded in backend

### Feature 2: AI Crop Advisor

1. Navigate to "AI Crop Advisor"
2. Fill in the form:
   - Select Province (e.g., "Eastern Province")
   - Select District (e.g., "Bugesera")
   - Select Sector (e.g., "Gashora")
   - Select Cell (e.g., "Biryogo")
   - Select Village (e.g., "Akagera")
   - Select Season (e.g., "Season A (Sept - Jan)")
   - Select Land Type (e.g., "Wetland")
3. Tap "Get AI Cultivation Guide"

**Expected Results:**
- ✅ Loading indicator
- ✅ Featured recommendation card (best match)
- ✅ Alternative crop recommendations
- ✅ Weather data for location
- ✅ Weather-based advice

**Common Issues:**
- ❌ "No cells available" → Check location data structure
- ❌ "Failed to fetch recommendations" → Check backend is running
- ❌ Empty recommendations → Check crop calendar CSV file

### Feature 3: Location Selection

Test the dropdown hierarchy:
1. Province → District → Sector → Cell → Village
2. Each dropdown should populate based on previous selection

**Expected Results:**
- ✅ All 5 provinces available
- ✅ Districts populate when province selected
- ✅ Sectors populate when district selected
- ✅ Cells populate when sector selected
- ✅ Villages populate when cell selected

**Common Issues:**
- ❌ Dropdown not clickable → Check if items list is empty
- ❌ Wrong data shown → Check `rwanda_locations.dart` structure

### Feature 4: Authentication (if using Supabase)

1. Test Registration
2. Test Login
3. Test Profile Update

## Part 4: Integration Testing

### Test Backend ↔ Frontend Communication

1. **Start Backend:**
   ```bash
   python main.py
   ```

2. **Start Flutter App:**
   ```bash
   flutter run -d chrome
   ```

3. **Test Flow:**
   - Upload image → Check backend logs for request
   - Get recommendations → Check backend logs for advisor request
   - Verify data matches between backend response and UI display

### Check Backend Logs

Watch the terminal where backend is running for:
- ✅ `POST /predict` requests
- ✅ `POST /advisor` requests
- ✅ Any error messages

## Part 5: Troubleshooting

### Backend Issues

**Problem: Model not loaded**
```bash
# Check if model file exists
ls outputs/best_MobileNetV2.keras

# Check model_metadata.json
cat outputs/model_metadata.json
```

**Problem: Port already in use**
```bash
# Kill process on port 8000
lsof -ti:8000 | xargs kill -9  # macOS/Linux
# Or change port in main.py
```

**Problem: CORS errors**
- Backend already has CORS enabled for all origins
- If issues persist, check `main.py` CORS settings

### Flutter Issues

**Problem: Can't connect to backend**
- Web: Use `http://localhost:8000`
- Android Emulator: Use `http://10.0.2.2:8000`
- Physical Device: Use your computer's IP (e.g., `http://192.168.1.100:8000`)

**Problem: Build errors**
```bash
flutter clean
flutter pub get
flutter run
```

**Problem: API URL not updating**
- Check `crop_health_scanner_screen.dart` and `ai_advisor_screen_enhanced.dart`
- Look for `_defaultApiBaseUrl` or `_advisorApiBaseUrl`

## Quick Test Checklist

- [ ] Backend starts without errors
- [ ] Health check endpoint works (`/`)
- [ ] Model is loaded (`model_loaded: true`)
- [ ] Flutter app builds successfully
- [ ] Flutter app connects to backend
- [ ] Image upload works
- [ ] Prediction displays correctly
- [ ] Location dropdowns work
- [ ] AI Advisor returns recommendations
- [ ] Weather data displays
- [ ] No console errors

## Next Steps After Testing

1. **Upload Model to Hugging Face** (see `HUGGINGFACE_SETUP.md`)
2. **Deploy Backend** (Heroku, Railway, etc.)
3. **Build Flutter App** for production
4. **Test on Real Devices**

## Getting Help

If something doesn't work:
1. Check backend logs
2. Check Flutter console (run with `flutter run -v` for verbose)
3. Check browser console (for web)
4. Verify all dependencies are installed
5. Check network connectivity
