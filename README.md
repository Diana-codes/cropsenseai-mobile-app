# CropSense AI 🌾

**AI-Driven Decision Support for Climate-Resilient Smallholder Farming in Rwanda**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📱 Overview

CropSense AI is a mobile application that helps smallholder farmers in Rwanda with **crop disease detection**, **crop selection and season planning** based on location and weather, and **Rwanda-specific seasonal guidance** (rainy and dry seasons). The app uses a Flutter frontend, a FastAPI backend with a TensorFlow/Keras disease model, and Supabase for authentication.

### Key Capabilities

- 🔍 **Crop Health Scanner** – Upload leaf images for AI-powered disease identification (Healthy, Powdery mildew, Rust) with confidence and weather-based advice
- 🌾 **Crop selection & AI Advisor** – Get personalized **crop recommendations** based on province, district, land type, and season (Rwanda long/short rainy and dry seasons)
- 📅 **Season Planning** – Multi-step wizard to plan a season and see best-match crops and alternatives
- 🌤️ **Weather** – Real-time weather (Open-Meteo) for the selected location
- 📍 **Rwanda locations** – Full hierarchy: Province → District → Sector → Cell → Village
- 📲 **My current plan** – Summary of recommended crop and location on the home screen

---

## 🎬 Demo Video

A **5-minute demo video** shows the app in action. The video focuses on **core functionalities** (Crop Health Scanner, Season Planning, crop selection via AI Advisor, Rwanda Seasons, Process screen).

- **Video link**: [https://drive.google.com/file/d/1uT95GxZMThcHiYPlwZMeJRoXhZBxjR-u/view?usp=sharing]
---

## 📲 Deployed Version / Installable Package

Use one of the following to try the app without building from source:

| Type | Link / File |
|------|-------------|
| **Android APK** | [Download app-release.apk (v1.0.0)](https://github.com/Diana-codes/cropsenseai-mobile-app/releases/download/v1.0.0/app-release.apk) |
| **Backend API (Render)** | `https://cropsenseai-mobile-app.onrender.com` |
| **API docs** | `https://cropsenseai-mobile-app.onrender.com/docs` |

*To build the APK locally:*  
`flutter build apk --release --dart-define=API_BASE_URL=https://cropsenseai-mobile-app.onrender.com`  
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🚀 Installation & Running (Step by Step)

### Prerequisites

- **Flutter SDK** 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Python** 3.12+ (for backend)
- **Git**  
- **Android**: Android Studio / SDK (for Android) or **iOS**: Xcode (macOS, for iOS)

### Step 1: Clone the repository

```bash
git clone https://github.com/Diana-codes/cropsenseai-mobile-app.git
cd cropsenseai-mobile-app
```

### Step 2: Backend setup

1. Create and activate a virtual environment:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate   # Windows: .venv\Scripts\activate
   ```

2. Install Python dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. (Optional) For production, the backend loads the disease model from **Hugging Face**. Set:
   - `HUGGINGFACE_MODEL_ID=Ruzindana/cropsense-mobilenetv2`
   - `HUGGINGFACE_HUB_TOKEN=<your-token>`

   For local runs, place `outputs/best_model.keras` and `outputs/model_metadata.json` in the project (or use Hugging Face as above).

4. Start the backend:

   ```bash
   ./start_backend.sh
   # or: uvicorn main:app --host 0.0.0.0 --port 8000
   ```

   Leave this terminal open. Confirm: `curl http://localhost:8000/` returns JSON with `"model_loaded": true` (or similar).

### Step 3: Flutter app setup

1. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

2. Run the app:

   - **Chrome (web):**  
     `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000`

   - **Android emulator:**  
     `flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8000`

   - **Physical Android device (same Wi‑Fi as your machine):**  
     Replace `YOUR_IP` with your computer’s IP (e.g. from `ipconfig getifaddr en0`).  
     `flutter run -d YOUR_DEVICE_ID --dart-define=API_BASE_URL=http://YOUR_IP:8000`

   - **Against deployed backend:**  
     `flutter run --dart-define=API_BASE_URL=https://cropsenseai-mobile-app.onrender.com`

### Step 4: Supabase (for login/profile)

1. Create a project at [Supabase](https://supabase.com).
2. In **Project Settings → API**, copy **Project URL** and **anon public** key.
3. In `lib/services/supabase_service.dart`, set:
   - `supabaseUrl`
   - `supabaseAnonKey`

Use your Supabase project URL and anon key in `lib/services/supabase_service.dart`.

---

## 📁 Related Files & Project Structure

### Documentation

| File | Description |
|------|-------------|
| `README.md` | This file – overview, install, run, demo, deployment |
| `training/README.md` | How to run the training script and notebook |
| `dataset/README.md` | Dataset layout (Healthy, Powdery, Rust) |

### Configuration

| File | Description |
|------|-------------|
| `pubspec.yaml` | Flutter dependencies and app config |
| `requirements.txt` | Python backend dependencies |
| `training/requirements-training.txt` | Extra deps for model training |

### Backend (Python)

| File | Description |
|------|-------------|
| `main.py` | FastAPI app: `/`, `/predict`, `/weather`, `/advisor`, `/crops`, `/advice` |
| `services.py` | WeatherService, RwandaAgronomistAdvisor, RwandaCropPlanner |
| `Rwanda_Crop_calendar_Data.csv` | Crop calendar used for crop selection and season planning |

### Frontend (Flutter)

| Path | Description |
|------|-------------|
| `lib/main.dart` | App entry, auth wrapper, bottom nav (Home, Process, Season, Account) |
| `lib/screens/home_screen.dart` | Home: weather, quick actions, My current plan, alerts |
| `lib/screens/crop_health_scanner_screen.dart` | Crop Health Scanner – capture/upload image, show prediction & advice |
| `lib/screens/ai_advisor_screen_enhanced.dart` | AI Advisor – location, season, land type → crop selection |
| `lib/screens/season_planning_screen.dart` | New Season Planning – 3 steps, crop selection result |
| `lib/screens/season_screen.dart` | Rwanda Seasons tab – rainy/dry seasons, current season, links |
| `lib/screens/process_screen.dart` | Season Process – generic season stages |
| `lib/screens/login_screen.dart`, `profile_screen.dart`, … | Auth and profile |
| `lib/services/api_service.dart` | HTTP calls to backend |
| `lib/services/supabase_service.dart` | Supabase URL and anon key |
| `lib/services/app_settings.dart` | In-app notification toggle |
| `lib/data/rwanda_locations.dart` | Provinces, districts, sectors, cells, villages |

### ML / Training

| Path | Description |
|------|-------------|
| `training/train_and_compare_models.py` | Trains 5 models, saves best as `outputs/best_model.keras` |
| `training/CropSense_Model_Training.ipynb` | Same workflow in a Jupyter notebook |
| `outputs/best_model.keras` | Deployed disease model (MobileNetV2) |
| `outputs/model_metadata.json` | Class names for the model |
| `dataset/Train/Healthy`, `Powdery`, `Rust` | Training images |

### Scripts

| File | Description |
|------|-------------|
| `start_backend.sh` | Starts the FastAPI backend (venv + uvicorn) |

---

## ✨ Features (incl. crop selection)

1. **Crop Health Scanner**  
   Upload a leaf image → backend runs the disease model → app shows predicted class (Healthy / Powdery / Rust), confidence, weather, and agronomic advice.

2. **Crop selection & AI Advisor**  
   User selects **location** (province, district, sector, etc.), **season** (e.g. Long rainy, Short rainy, Dry), and **land type** (Wetland, Hillside, Valley, Plateau). The backend returns a **best-match crop** and **alternatives** for that combination; the app shows “Location: … • Season: …” so it’s clear what the selection is based on.

3. **Season Planning**  
   Multi-step flow: (1) Location & season, (2) Land type & size, (3) Analyze → **crop selection** result with best match and alternatives, plus weather. “Done” closes the flow; the result can inform the home “My current plan.”

4. **Rwanda Seasons**  
   Explains long/short rainy and dry seasons (no winter/summer). Shows current season by month. Quick links to “Plan new season” and “Get AI advice.”

5. **My current plan (Home)**  
   Card under Quick Actions showing the latest **crop selection** (best crop) and location/season for the user.

6. **Season Process**  
   Generic, honest list of typical season stages (prepare land, plant, manage, harvest, post-harvest). No fake progress; future work will tie it to the user’s plan.

7. **Notifications (in-app)**  
   Toggle in Profile. When on, Home shows a season-reminder banner using the latest advisor result.

8. **Authentication & profile**  
   Supabase email/password; profile stores name, location (province, district), land size, etc., used as default for weather and recommendations.

---

## 🔌 API Endpoints (summary)

- `GET /` – Health check (`model_loaded`, etc.)
- `POST /predict` – Image → disease prediction, confidence, weather, advice
- `POST /advisor` – Body: province, district, sector, season, landType → crop selection (best match + alternatives) and weather
- `GET /weather` – Weather for a location
- `GET /crops` – List of supported crops
- `POST /advice` – Agronomic advice for a given crop and weather

Interactive docs: `http://localhost:8000/docs` (or your deployed URL + `/docs`).

---

## 📦 Build installable package (APK)

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://cropsenseai-mobile-app.onrender.com
```

APK path: `build/app/outputs/flutter-apk/app-release.apk`.  
Upload this to a GitHub Release or your chosen host and put the link in the “Deployed Version / Installable Package” section above.

---

## 📄 License

This project uses the MIT license (or as specified in the repository). The Hugging Face model `Ruzindana/cropsense-mobilenetv2` is used under its stated license.

---

## 👤 Author

**Diana RUZINDANA** – CropSense AI (BSc. Software Engineering / Smart farming for Rwanda)

- GitHub: [Diana-codes/cropsenseai-mobile-app](https://github.com/Diana-codes/cropsenseai-mobile-app)
- Demo video: [https://drive.google.com/file/d/1uT95GxZMThcHiYPlwZMeJRoXhZBxjR-u/view?usp=sharing]
- Deployed API: (https://cropsenseai-mobile-app.onrender.com)

---

**Last updated**: March 2025 · **Version**: 1.0.0
