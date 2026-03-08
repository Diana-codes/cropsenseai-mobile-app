# Commands to Run - Step by Step

## Step 1: Start the Backend (Terminal 1)

```bash
cd ~/Desktop/cropsenseai-mobile-app
source .venv/bin/activate
python main.py
```

**Wait until you see:**
```
✓ Model loaded successfully...
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**Keep this terminal open!** The backend must stay running.

---

## Step 2: Test Backend Endpoints (Terminal 2)

Open a **NEW terminal** and run:

```bash
cd ~/Desktop/cropsenseai-mobile-app

# Test 1: Health Check
curl http://localhost:8000/

# Test 2: Run all backend tests
./test_backend.sh

# Test 3: Test image prediction (replace with your image path)
./test_image.sh /home/diana/Downloads/maize_images.jpg

# Test 4: Test AI Advisor
curl -X POST http://localhost:8000/advisor \
  -H "Content-Type: application/json" \
  -d '{"province":"Eastern Province","district":"Bugesera","sector":"Gashora","cell":"Biryogo","village":"Akagera","season":"Season A (Sept - Jan)","landType":"Wetland"}'
```

---

## Step 3: Run Flutter App (Terminal 3)

Open **ANOTHER terminal** and run:

```bash
cd ~/Desktop/cropsenseai-mobile-app

# For Web (Easiest - opens in Chrome)
flutter run -d chrome

# OR for Android Emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# OR for Physical Device
flutter run
```

---

## Quick Test Checklist

After running the commands above, test these in the Flutter app:

- [ ] **Crop Health Scanner**: Upload image → See prediction
- [ ] **AI Crop Advisor**: Fill form → Get recommendations
- [ ] **Location Dropdowns**: Province → District → Sector → Cell → Village

---

## Troubleshooting

### Backend won't start?
```bash
# Check if port 8000 is in use
lsof -ti:8000 | xargs kill -9

# Then restart
source .venv/bin/activate
python main.py
```

### Flutter can't connect?
- **Web**: Make sure backend is on `http://localhost:8000`
- **Android**: Use `http://10.0.2.2:8000` (see command above)

### Need to stop everything?
- Press `Ctrl+C` in each terminal to stop
