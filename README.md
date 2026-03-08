# CropSense AI 🌾

**AI-Driven Decision Support for Climate-Resilient Smallholder Farming in Rwanda**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)](LICENSE)

---

## 📱 Overview

CropSense AI is a comprehensive mobile application designed to empower smallholder farmers in Rwanda with AI-powered agricultural insights. The app provides real-time crop disease detection, personalized crop recommendations based on location and weather, and season planning tools to optimize farming decisions.

### Key Capabilities

- 🔍 **Crop Disease Detection**: Upload leaf images for instant AI-powered disease identification
- 🌾 **AI Crop Advisor**: Get personalized crop recommendations based on location, season, and land type
- 📅 **Season Planning**: Plan your farming season with location-specific recommendations
- 🌤️ **Weather Integration**: Real-time weather data for informed decision-making
- 📍 **Location-Based Services**: Full Rwanda administrative hierarchy (Province → District → Sector → Cell → Village)

---

## ✨ Features

### Core Functionalities

1. **Crop Health Scanner**
   - Upload leaf images via camera or gallery
   - AI-powered disease detection (Healthy, Powdery, Rust)
   - Confidence scores and detailed recommendations
   - Weather-based agronomic advice

2. **AI Crop Advisor**
   - Location-based crop recommendations
   - Weather-integrated suggestions
   - Season-specific planning (Season A/B)
   - Land type considerations (Wetland, Hillside, Valley, Plateau)

3. **Season Planning**
   - Multi-step planning wizard
   - Location selection with full Rwanda hierarchy
   - Crop recommendations with weather data
   - Land size and type configuration

4. **Home Dashboard**
   - Real-time weather information
   - Quick action buttons
   - Personalized alerts and recommendations
   - Performance statistics

5. **User Profile Management**
   - Farmer information management
   - Settings and preferences
   - Authentication via Supabase

---

## 🛠️ Tech Stack

### Frontend (Mobile App)
- **Framework**: Flutter 3.0+
- **Language**: Dart 3.0+
- **UI**: Material Design 3
- **State Management**: StatefulWidget
- **HTTP Client**: `http` package
- **Image Picker**: `image_picker` package
- **Authentication**: Supabase Flutter

### Backend (API)
- **Framework**: FastAPI 0.115
- **Language**: Python 3.12+
- **ML Framework**: TensorFlow/Keras
- **Model Hosting**: Hugging Face (optional)
- **Weather API**: Open-Meteo API
- **Server**: Uvicorn

### Data
- **Crop Calendar**: CSV-based Rwanda crop calendar
- **Location Data**: Hierarchical Rwanda administrative data
- **ML Model**: MobileNetV2 (for disease detection)

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (3.0.0 or higher - comes with Flutter)

3. **Python** (3.12 or higher)
   ```bash
   python3 --version
   ```

4. **Git**
   ```bash
   git --version
   ```

### Platform-Specific Requirements

**For Android Development:**
- Android Studio
- Android SDK (API level 21+)
- Android Emulator or physical device

**For iOS Development (macOS only):**
- Xcode 14+
- CocoaPods
- iOS Simulator or physical device

**For Web Development:**
- Chrome browser (for testing)

### Optional Tools
- VS Code with Flutter extensions (recommended)
- Postman or curl (for API testing)

---

## 🚀 Installation

Follow these step-by-step instructions to set up the project:

### Step 1: Clone the Repository

```bash
git clone https://github.com/Diana-codes/cropsenseai-mobile-app.git
cd cropsenseai-mobile-app
```

### Step 2: Set Up Backend (FastAPI)

#### 2.1 Create Virtual Environment

```bash
# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
# On Linux/macOS:
source .venv/bin/activate
# On Windows:
# .venv\Scripts\activate
```

#### 2.2 Install Python Dependencies

```bash
pip install -r requirements.txt
```

#### 2.3 Set Up ML Model

**Option A: Use Local Model (Default)**
- Ensure `outputs/best_MobileNetV2.keras` exists
- Ensure `outputs/model_metadata.json` exists

**Option B: Use Hugging Face (Recommended for Production)**
```bash
# Install Hugging Face CLI
pip install huggingface_hub

# Login to Hugging Face
huggingface-cli login

# Upload your model (see HUGGINGFACE_SETUP.md for details)
python upload_to_hf.py your-username/cropsense-mobilenetv2

# Set environment variable
export HUGGINGFACE_MODEL_ID="your-username/cropsense-mobilenetv2"
```

### Step 3: Set Up Flutter Mobile App

#### 3.1 Install Flutter Dependencies

```bash
flutter pub get
```

#### 3.2 Configure API Base URL (Optional)

The app defaults to `http://localhost:8000` for web. For Android emulator, use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For physical devices, use your computer's IP address:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

### Step 4: Verify Installation

```bash
# Check Flutter setup
flutter doctor

# Verify Python environment
python --version
pip list | grep fastapi
```

---

## 🏃 Running the Application

### Backend Setup

#### Start the Backend Server

**Option 1: Using the Helper Script**
```bash
./start_backend.sh
```

**Option 2: Manual Start**
```bash
# Activate virtual environment
source .venv/bin/activate

# Start the server
python main.py
```

You should see:
```
✓ Model loaded successfully from outputs/best_MobileNetV2.keras
✓ Loaded class names from outputs/model_metadata.json: ['Healthy', 'Powdery', 'Rust']
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**Keep this terminal open!** The backend must stay running.

#### Verify Backend is Running

Open a new terminal and test:
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

### Mobile App Setup

#### Run on Web (Easiest for Testing)

```bash
flutter run -d chrome
```

#### Run on Android Emulator

1. Start Android Emulator:
   ```bash
   flutter emulators --launch <emulator_id>
   ```

2. Run the app:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
   ```

#### Run on Physical Android Device

1. Enable USB Debugging on your device
2. Connect via USB
3. Run:
   ```bash
   flutter devices  # Verify device is detected
   flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8000
   ```

#### Run on iOS (macOS only)

```bash
flutter run -d ios
```

### Quick Test

1. **Test Backend Endpoints:**
   ```bash
   ./test_backend.sh
   ```

2. **Test Image Prediction:**
   ```bash
   ./test_image.sh /path/to/your/image.jpg
   ```

3. **Test in App:**
   - Open the Flutter app
   - Navigate to "Crop Health Scanner"
   - Upload a leaf image
   - Verify prediction appears

---

## 📁 Project Structure

```
cropsenseai-mobile-app/
├── lib/                          # Flutter mobile app source code
│   ├── main.dart                # App entry point
│   ├── screens/                 # Screen widgets
│   │   ├── home_screen.dart
│   │   ├── crop_health_scanner_screen.dart
│   │   ├── ai_advisor_screen_enhanced.dart
│   │   ├── season_planning_screen.dart
│   │   ├── profile_screen.dart
│   │   └── ...
│   ├── widgets/                 # Reusable components
│   │   ├── weather_card.dart
│   │   ├── recommendation_card.dart
│   │   └── ...
│   ├── services/                # Service layer
│   │   ├── auth_service.dart
│   │   └── supabase_service.dart
│   ├── data/                    # Data files
│   │   └── rwanda_locations.dart
│   └── utils/                   # Utilities
│       └── colors.dart
│
├── main.py                      # FastAPI backend entry point
├── services.py                  # Backend services (Weather, Advisor, Planner)
├── requirements.txt             # Python dependencies
├── pubspec.yaml                 # Flutter dependencies
│
├── outputs/                     # ML model files (gitignored)
│   ├── best_MobileNetV2.keras
│   └── model_metadata.json
│
├── Rwanda_Crop_calendar_Data.csv  # Crop calendar data
│
├── Documentation/
│   ├── QUICK_START.md          # Quick start guide
│   ├── TESTING_GUIDE.md        # Comprehensive testing guide
│   ├── HUGGINGFACE_SETUP.md    # Hugging Face deployment guide
│   └── RUN_COMMANDS.md         # Command reference
│
└── Test Scripts/
    ├── start_backend.sh        # Backend starter script
    ├── test_backend.sh         # Backend test script
    ├── test_image.sh           # Image prediction tester
    └── debug_crops.py          # Crop matching debugger
```

---

## 🔌 API Endpoints

### Base URL
- **Local Development**: `http://localhost:8000`
- **Android Emulator**: `http://10.0.2.2:8000`
- **Physical Device**: `http://YOUR_COMPUTER_IP:8000`

### Available Endpoints

#### Health Check
```http
GET /
```
**Response:**
```json
{
  "status": "CropSense AI API is running",
  "version": "1.0.0",
  "model_loaded": true,
  "encoder_loaded": false
}
```

#### Crop Disease Prediction
```http
POST /predict
Content-Type: multipart/form-data
```
**Request:** Form data with `file` field (image file)

**Response:**
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

#### AI Crop Advisor
```http
POST /advisor
Content-Type: application/json
```
**Request Body:**
```json
{
  "province": "Eastern Province",
  "district": "Bugesera",
  "sector": "Gashora",
  "cell": "Biryogo",
  "village": "Akagera",
  "season": "Season A (Sept - Jan)",
  "landType": "Wetland"
}
```

**Response:**
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

#### Weather Data
```http
GET /weather?location=Rwanda
```

#### Available Crops
```http
GET /crops
```

### API Documentation

Interactive API documentation available at:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

---

## 🧪 Testing

### Backend Testing

```bash
# Run all backend tests
./test_backend.sh

# Test specific endpoint
curl http://localhost:8000/

# Test image prediction
./test_image.sh /path/to/image.jpg
```

### Flutter App Testing

```bash
# Run Flutter tests
flutter test

# Run with verbose output
flutter run -v
```

### Integration Testing

1. Start backend: `python main.py`
2. Run Flutter app: `flutter run -d chrome`
3. Test features:
   - Upload image in Crop Health Scanner
   - Get recommendations in AI Advisor
   - Plan season in Season Planning

---

## 📦 Building for Production

### Build Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Build iOS (macOS only)

```bash
flutter build ios --release
```

### Build Web

```bash
flutter build web --release
```

Output: `build/web/`

---

## 🚢 Deployment

### Backend Deployment

#### Option 1: Hugging Face (Recommended for Models)

1. Upload model to Hugging Face (see `HUGGINGFACE_SETUP.md`)
2. Set `HUGGINGFACE_MODEL_ID` environment variable
3. Deploy backend to cloud (Heroku, Railway, AWS, etc.)

#### Option 2: Local Model

1. Ensure model files are in `outputs/` directory
2. Deploy backend with model files included

### Mobile App Deployment

#### Android Play Store

1. Build app bundle: `flutter build appbundle --release`
2. Create app in Google Play Console
3. Upload the `.aab` file
4. Complete store listing and submit for review

#### iOS App Store (macOS only)

1. Build iOS app: `flutter build ios --release`
2. Archive in Xcode
3. Upload to App Store Connect
4. Submit for review

### Web Deployment

1. Build web: `flutter build web --release`
2. Deploy `build/web/` to:
   - Firebase Hosting
   - Netlify
   - Vercel
   - GitHub Pages

---

## 📚 Related Files

### Documentation Files
- `QUICK_START.md` - Quick reference guide
- `TESTING_GUIDE.md` - Comprehensive testing instructions
- `RUN_COMMANDS.md` - Command reference
- `HUGGINGFACE_SETUP.md` - Model deployment guide
- `TEST_SCRIPTS_README.md` - Test scripts documentation

### Configuration Files
- `pubspec.yaml` - Flutter dependencies and configuration
- `requirements.txt` - Python dependencies
- `analysis_options.yaml` - Dart linting rules
- `.gitignore` - Git ignore patterns

### Data Files
- `Rwanda_Crop_calendar_Data.csv` - Crop calendar data for recommendations
- `lib/data/rwanda_locations.dart` - Rwanda administrative hierarchy

### Script Files
- `start_backend.sh` - Backend startup script
- `test_backend.sh` - Backend testing script
- `test_image.sh` - Image prediction tester
- `upload_to_hf.py` - Hugging Face upload helper
- `debug_crops.py` - Crop matching debugger

### Source Code
- `main.py` - FastAPI backend entry point
- `services.py` - Backend business logic
- `lib/` - Flutter mobile app source code

---

## 🔗 Links

### Deployed Version / Application Package

**Note**: Update these links with your actual deployment URLs or download links.

#### Mobile App
- **Android APK**: [Download APK](https://your-download-link.com/app-release.apk)
- **iOS App**: [Download from App Store](https://apps.apple.com/app/cropsense-ai)
- **Web App**: [Access Web Version](https://cropsense-ai.web.app)

#### Backend API
- **Production API**: `https://api.cropsense-ai.com`
- **API Documentation**: `https://api.cropsense-ai.com/docs`

#### Model Repository
- **Hugging Face Model**: [View Model](https://huggingface.co/Ruzindana/cropsense-mobilenetv2)

---

## 🐛 Troubleshooting

### Backend Issues

**Problem**: Model not loading
```bash
# Check if model file exists
ls outputs/best_MobileNetV2.keras

# Verify model_metadata.json
cat outputs/model_metadata.json
```

**Problem**: Port already in use
```bash
# Kill process on port 8000
lsof -ti:8000 | xargs kill -9
```

**Problem**: CORS errors
- Backend already has CORS enabled for all origins
- Check `main.py` CORS settings if issues persist

### Flutter Issues

**Problem**: Can't connect to backend
- **Web**: Use `http://localhost:8000`
- **Android Emulator**: Use `http://10.0.2.2:8000`
- **Physical Device**: Use your computer's IP address

**Problem**: Build errors
```bash
flutter clean
flutter pub get
flutter run
```

**Problem**: Dependencies not found
```bash
flutter pub get
flutter pub upgrade
```

---

## 🤝 Contributing

This project is part of a BSc. Software Engineering thesis project by **Diana RUZINDANA**.

For contributions, please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

All rights reserved. This project is proprietary software.

---

## 👥 Contact & Support

**Developer**: Diana RUZINDANA

For questions, issues, or support:
- **GitHub Issues**: [Create an issue](https://github.com/Diana-codes/cropsenseai-mobile-app/issues)
- **Email**: [dianaruzindana8@gmail.com]

---

## 🙏 Acknowledgments

- Rwanda Agricultural Board for crop calendar data
- Open-Meteo for weather API services
- Hugging Face for model hosting infrastructure
- Flutter and FastAPI communities

---

## 📊 Project Status

- ✅ **Backend API**: Fully functional
- ✅ **Mobile App**: Production ready
- ✅ **ML Model**: Integrated and working
- ✅ **Weather Integration**: Active
- ✅ **Location Data**: Complete Rwanda hierarchy
- 🔄 **Continuous Improvement**: Ongoing

---

**Last Updated**: March 2025

**Version**: 1.0.0
