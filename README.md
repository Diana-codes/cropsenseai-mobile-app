# CropSense AI

**AI-Driven Decision Support for Climate-Resilient Smallholder Farming in Rwanda**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com)

---

## Overview

CropSense AI is a mobile-first decision support system that helps Rwandan smallholder farmers make better planting decisions. It combines **AI crop recommendations**, **CNN-based disease detection**, and **real-time weather data** in one bilingual (English/Kinyarwanda) mobile app.

### Key Features

- **AI Crop Advisor** -- Rule-based crop recommendations using MINAGRI/FAO crop calendar data, localized to Rwanda's 6 agro-ecological zones
- **Crop Health Scanner** -- MobileNetV2 CNN classifies leaf images as Healthy, Powdery Mildew, or Rust (99.35% accuracy)
- **Real-time Weather** -- Dual weather providers (Open-Meteo + OpenWeatherMap) with district-level precision
- **Season Planning** -- 5-stage season tracker with crop-specific guidance for 9 major Rwanda crops
- **Bilingual** -- Full English/Kinyarwanda translation (150+ strings, crop names, stage guidance)
- **Offline Support** -- Weather (2h TTL) and advisor (6h TTL) caching for low-connectivity areas
- **Smart Alerts** -- Context-aware notifications: sowing windows, humidity warnings, crop recommendations
- **EULA & Privacy Policy** -- Consent-first registration with Rwanda data protection law compliance

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile App | Flutter (Dart) -- Android-first |
| Backend API | FastAPI (Python) |
| Database | PostgreSQL (production) / SQLite (development) |
| ML Model | MobileNetV2 (TensorFlow/Keras) |
| Authentication | JWT + bcrypt (FastAPI-based) |
| Weather | Open-Meteo + OpenWeatherMap APIs |
| Hosting | Render.com (backend + PostgreSQL) |
| Model Hosting | HuggingFace Hub |

---

## Deployed Version

| Type | Link |
|------|------|
| **Android APK** | [Download app-release.apk](https://github.com/Diana-codes/cropsenseai-mobile-app/releases/download/v1.0.0/app-release.apk) |
| **Backend API** | `https://cropsenseai-mobile-app.onrender.com` |
| **API Docs** | `https://cropsenseai-mobile-app.onrender.com/docs` |
| **Database Stats** | `https://cropsenseai-mobile-app.onrender.com/admin/stats` |

---

## Installation & Running

### Prerequisites

- **Flutter SDK** >= 3.0.0 ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Python** >= 3.10 ([Install Python](https://www.python.org/downloads/))
- **Android device or emulator** for running the mobile app
- **Git** for cloning the repository

### Step 1: Clone the Repository

```bash
git clone https://github.com/Diana-codes/cropsenseai-mobile-app.git
cd cropsenseai-mobile-app
```

### Step 2: Backend Setup (FastAPI)

```bash
# Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Run the backend
uvicorn main:app --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`. Visit `http://localhost:8000/docs` for interactive API documentation.

**Environment variables (optional for local dev):**

| Variable | Description |
|----------|-------------|
| `CROPSENSE_JWT_SECRET` | Secret key for JWT tokens (defaults to dev key) |
| `DATABASE_URL` | PostgreSQL connection string (defaults to SQLite) |
| `CROPSENSE_ENABLE_TF` | Set to `1` to enable TensorFlow model loading |
| `HUGGINGFACE_MODEL_ID` | HuggingFace repo ID for model download |
| `HUGGINGFACE_HUB_TOKEN` | HuggingFace auth token |
| `OPENWEATHER_API_KEY` | OpenWeatherMap API key (falls back to Open-Meteo) |

### Step 3: Flutter App Setup

```bash
# Install dependencies
flutter pub get

# Check connected devices
flutter devices

# Run on connected Android device
flutter run -d <DEVICE_ID>

# Or run against deployed backend (no local backend needed)
flutter run
```

### Step 4: Build APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Running Tests

```bash
# Flutter widget tests (20 tests)
flutter test

# Backend API tests (19 tests)
pip install pytest pytest-asyncio httpx python-jose[cryptography]
python -m pytest tests/ -v
```

**Total: 39 automated tests** covering authentication, API endpoints, UI navigation, settings, localization, and Rwanda location data.

---

## Project Structure

```
cropsenseai-mobile-app/
├── lib/                          # Flutter mobile app
│   ├── screens/                  # All app screens (12 screens)
│   ├── services/                 # API, auth, settings, connectivity
│   ├── l10n/                     # Localization (English + Kinyarwanda)
│   ├── widgets/                  # Reusable UI components
│   ├── data/                     # Rwanda locations hierarchy
│   └── main.dart                 # App entry point
├── main.py                       # FastAPI backend (all endpoints)
├── services.py                   # WeatherService, Advisor, CropPlanner
├── Rwanda_Crop_calendar_Data.csv # MINAGRI/FAO crop calendar (30+ crops)
├── training/                     # ML model training
│   └── CropSense_Model_Training.ipynb
├── dataset/Train/                # Training images (1,532 total)
│   ├── Healthy/                  # 528 images
│   ├── Powdery/                  # 500 images
│   └── Rust/                     # 504 images
├── tests/test_api.py             # 19 backend API tests
├── test/widget_test.dart         # 20 Flutter widget tests
└── FormattingGuidelines-IJCAI-ECAI-26/  # Research paper (LaTeX)
```

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/health` | GET | Detailed health status |
| `/auth/register` | POST | User registration |
| `/auth/login` | POST | User login (returns JWT) |
| `/auth/me` | GET | Get current user profile |
| `/auth/profile` | PUT | Update profile |
| `/auth/forgot-password` | POST | Request password reset |
| `/auth/reset-password` | POST | Reset password with token |
| `/advisor` | POST | Crop recommendations by location/season |
| `/predict` | POST | Disease detection from leaf image |
| `/weather` | GET | Weather data for location |
| `/crops` | GET | List supported crops |
| `/season-plans` | POST | Create season plan |
| `/season-plans/active` | GET | Get active season plan |
| `/season-plans/{id}/stages` | PATCH | Update stage progress |
| `/admin/stats` | GET | Database overview |

---

## Model Training

The training notebook is at `training/CropSense_Model_Training.ipynb`. Five models were benchmarked:

| Model | Accuracy | ROC-AUC | Parameters |
|-------|----------|---------|------------|
| **MobileNetV2** | **99.35%** | **0.9994** | ~3.4M |
| ResNet50V2 | 96.75% | 0.9990 | ~25.6M |
| Custom CNN | 92.21% | 0.9934 | ~0.5M |
| Logistic Regression | 77.92% | 0.9172 | ~49K |
| VGG16 | 76.62% | 0.9203 | ~138M |

**Training config:** 128x128 input, 30 epochs, batch size 32, Adam optimizer, early stopping (patience=5), stratified 70/20/10 split.

---

## Data Sources

| Source | Type | Used For |
|--------|------|----------|
| PlantVillage (Kaggle) | 1,532 leaf images | Disease detection model |
| FAO/MINAGRI Crop Calendar | CSV (30+ crops) | Crop recommendation engine |
| Open-Meteo | Real-time API | Weather data (primary) |
| OpenWeatherMap | Real-time API | Weather data (secondary) |
| NISR Rwanda | Administrative data | Location hierarchy |

---

## Author

**Diana Ruzindana** -- African Leadership University, Kigali, Rwanda

**Supervisor:** Muyonga Marvin Ogore -- African Leadership University

---

**Last updated**: April 2026
