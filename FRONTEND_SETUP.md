# CropSense AI - Frontend Setup (No Backend Required)

The app has been configured to run without backend dependencies. All data is mocked for visual demonstration.

## What Was Changed

1. **Removed Backend Dependencies**
   - Removed Supabase authentication and database connections
   - Removed TFLite model dependencies
   - Removed .env file requirement
   - Removed camera dependencies (using image picker only)

2. **Added Mock Data**
   - Mock authentication (automatically logs you in as "Mr. Uwimana")
   - Mock weather data
   - Mock disease detection results
   - Mock crop recommendations
   - Mock process tracking data

3. **Updated Dependencies**
   - Kept only essential UI dependencies
   - Removed all backend integration packages

## How to Run

1. **Install Dependencies**
   ```bash
   cd ~/Desktop/cropsenseai-mobile-app
   flutter pub get
   ```

2. **Enable Web Support (if not already done)**
   ```bash
   flutter create .
   ```

3. **Run on Chrome**
   ```bash
   flutter run -d chrome
   ```

4. **Run on Android**
   ```bash
   flutter run
   ```

## Features Available

All screens are now fully functional with mock data:

### 1. Home Screen
- Weather card showing current conditions
- Quick action buttons
- Alerts and recommendations
- Bottom navigation

### 2. Scanner Screen
- Pick images from gallery (camera won't work on web)
- Mock disease detection with realistic results
- Treatment recommendations
- Save detection feature

### 3. Recommendations Screen
- Crop recommendations based on season
- Confidence scores
- Yield predictions
- Duration and risk information

### 4. Process Screen
- Active farming processes
- Progress tracking
- Stage management
- Multiple crop types

### 5. Advisor Screen
- AI chat interface
- Mock responses to farming questions
- Real-time messaging UI

### 6. Profile Screen
- User information
- Farm statistics
- Settings menu
- Logout functionality

## Navigation

The app starts at the Home Screen automatically (no login required in demo mode).

Use the bottom navigation bar to access:
- Home
- Process
- Scanner
- Profile

Use the Quick Action buttons on Home to access:
- New Season → Recommendations
- Track Jobs → Process
- Crop Health → Scanner
- Get Advice → Advisor

## Notes

- All backend functionality has been replaced with realistic mock data
- The UI is fully interactive and demonstrates all planned features
- Image analysis shows random disease detection results
- No internet connection required
- No configuration files needed
