# Quick Start Guide

## 🚀 Fastest Way to Test Everything

### Step 1: Start the Backend (Terminal 1)

```bash
# Option A: Use the helper script
./start_backend.sh

# Option B: Manual start
source .venv/bin/activate
python main.py
```

**You should see:**
```
✓ Model loaded successfully from outputs/best_MobileNetV2.keras
✓ Loaded class names from outputs/model_metadata.json: ['Healthy', 'Powdery', 'Rust']
INFO:     Uvicorn running on http://0.0.0.0:8000
```

✅ **Backend is running!** Keep this terminal open.

---

### Step 2: Test Backend Endpoints (Terminal 2)

Open a **new terminal** and run:

```bash
# Quick test script
./test_backend.sh

# Or test manually:
curl http://localhost:8000/
```

✅ **Backend is working!**

---

### Step 3: Run Flutter App (Terminal 3)

Open **another terminal** and run:

```bash
# For Web (Easiest)
flutter run -d chrome

# For Android Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# For Physical Device
flutter run
```

✅ **App is running!**

---

## 🧪 Quick Feature Tests

### Test 1: Crop Health Scanner
1. In Flutter app → Tap "Crop Health Scanner"
2. Tap "Pick Image" → Select a leaf image
3. Wait for prediction

**Expected:** Prediction, confidence, weather, and advice appear

### Test 2: AI Crop Advisor
1. In Flutter app → Tap "AI Crop Advisor"
2. Fill in location (Province → District → Sector → Cell → Village)
3. Select Season and Land Type
4. Tap "Get AI Cultivation Guide"

**Expected:** Recommendations with weather data appear

### Test 3: Location Dropdowns
1. Select Province → Districts appear
2. Select District → Sectors appear
3. Select Sector → Cells appear
4. Select Cell → Villages appear

**Expected:** Each dropdown populates correctly

---

## 🐛 Troubleshooting

### Backend won't start?
```bash
# Check if port 8000 is in use
lsof -ti:8000 | xargs kill -9

# Reinstall dependencies
pip install -r requirements.txt
```

### Flutter can't connect?
- **Web:** Make sure backend is on `http://localhost:8000`
- **Android:** Use `http://10.0.2.2:8000`
- **Physical Device:** Use your computer's IP address

### Model not loading?
```bash
# Check if model file exists
ls outputs/best_MobileNetV2.keras

# If missing, see HUGGINGFACE_SETUP.md to use Hugging Face
```

---

## 📚 More Details

For comprehensive testing instructions, see **TESTING_GUIDE.md**
