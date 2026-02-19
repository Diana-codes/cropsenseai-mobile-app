# CropSense AI

AI-Driven Decision Support for Climate-Resilient Smallholder Farming in Rwanda

## Overview

CropSense AI is a mobile application designed to help smallholder farmers in Rwanda make informed decisions about crop selection, planting times, and farm management. The app provides AI-powered recommendations based on climate data, soil conditions, and historical farming data.

## Features

### Current Implementation

1. **Home Dashboard**
   - Real-time weather information
   - Quick action buttons for common tasks
   - Alerts and recommendations
   - Personalized crop suggestions

2. **Process Management**
   - Track cultivation stages
   - View detailed process information
   - Stage-by-stage guidance
   - Progress tracking

3. **Season Tracking**
   - Current season overview
   - Performance statistics
   - Historical data
   - Farmer achievements

4. **User Profile**
   - Farmer information management
   - Settings and preferences
   - Contact information

5. **AI Crop Advisor**
   - Personalized crop recommendations
   - Location-based suggestions
   - Soil type consideration
   - Season-specific advice

6. **Crop Health Scanner**
   - Disease detection guidance
   - Photo upload functionality
   - Common disease information
   - Treatment recommendations

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **UI**: Material Design 3
- **Fonts**: Google Fonts (Inter)
- **State Management**: StatefulWidget (can be upgraded to Provider/Riverpod later)

## Project Structure

```
lib/
├── main.dart                 # App entry point and navigation
├── screens/                  # All screen widgets
│   ├── home_screen.dart
│   ├── process_screen.dart
│   ├── season_screen.dart
│   ├── profile_screen.dart
│   ├── ai_advisor_screen.dart
│   └── crop_health_scanner_screen.dart
├── widgets/                  # Reusable widget components
│   ├── weather_card.dart
│   ├── quick_action_button.dart
│   ├── alert_card.dart
│   └── recommendation_card.dart
└── utils/                    # Utilities and constants
    └── colors.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK / iOS SDK (depending on target platform)

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Running on Different Platforms

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

**Web:**
```bash
flutter run -d chrome
```

## Next Steps (Backend Integration)

The current implementation uses static data. To integrate with a backend:

1. **API Integration**
   - Set up HTTP client (dio/http package)
   - Create API service layer
   - Implement data models

2. **State Management**
   - Implement Provider/Riverpod/Bloc
   - Handle loading/error states
   - Cache management

3. **Authentication**
   - User login/registration
   - Token management
   - Secure storage

4. **Real-time Weather Data**
   - Integrate weather APIs
   - Location services
   - Periodic updates

5. **AI Model Integration**
   - Connect to recommendation engine
   - Image processing for disease detection
   - TensorFlow Lite integration

6. **Database**
   - Local storage (SQLite/Hive)
   - Offline mode support
   - Data synchronization

## Design System

### Colors
- Primary: `#00C853` (Green)
- Primary Dark: `#00A843`
- Background: `#F5F7FA`
- Text Primary: `#1A1A1A`
- Text Secondary: `#757575`

### Typography
- Font Family: Inter (via Google Fonts)
- Heading: Bold, 18-24px
- Body: Regular, 14-16px
- Caption: Regular, 12-13px

## Contributing

This project is part of a BSc. Software Engineering thesis project by Diana RUZINDANA.

## License

All rights reserved.

## Contact

For questions or support, please contact the development team.
