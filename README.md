# CropSense AI

AI-Driven Decision Support for Climate-Resilient Smallholder Farming in Rwanda

## Project Overview

CropSense AI is a mobile application designed to provide climate-informed crop and seed selection recommendations for smallholder farmers in Rwanda. The system integrates weather data, agronomic knowledge, and AI-driven analysis to support pre-planting and early-season agricultural decision-making.

## Features

- **User Authentication**: Secure login and registration using Supabase Auth
- **Weather Dashboard**: Real-time weather information for Bugesera District
- **Crop Recommendations**: AI-powered crop and seed variety suggestions based on local conditions
- **Process Tracking**: Monitor cultivation processes and track farming stages
- **AI Crop Advisor**: Interactive chatbot for farming guidance
- **Disease Detection**: Image-based crop disease identification and treatment recommendations
- **User Profile**: Manage personal information and farming statistics

## Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **UI Components**: Material Design 3

### Backend & Services
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Weather API**: OpenWeatherMap (planned)
- **ML Model**: TensorFlow Lite (for disease detection - planned)

### Development Tools
- VS Code
- Git & GitHub
- Flutter SDK
- Android SDK

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── crop_provider.dart
│   └── weather_provider.dart
├── screens/                 # UI screens
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── recommendations/
│   │   └── recommendation_screen.dart
│   ├── process/
│   │   └── process_screen.dart
│   ├── advisor/
│   │   └── advisor_screen.dart
│   ├── scanner/
│   │   └── scanner_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/                 # Reusable widgets
│   ├── weather_card.dart
│   ├── action_button.dart
│   ├── alert_card.dart
│   └── recommendation_card.dart
└── utils/                   # Utilities
    └── theme.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Android SDK
- Supabase account

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd cropsense_ai
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create a `.env` file in the project root and add your Supabase credentials:
```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Run the application:
```bash
flutter run
```

## Research Context

This application is part of a BSc. Software Engineering research project by Diana RUZINDANA, supervised by Marvin Muyonga Ogore (January 2026).

### Research Objectives

1. Conduct systematic literature review of agricultural advisory systems
2. Design and develop a localized crop and seed decision support system
3. Evaluate system effectiveness and user adoption potential

### Target Users

Smallholder farmers in Bugesera District, Rwanda (pilot study with 15-20 farmers)

## Development Status

### Completed Features
- Authentication system (login/register)
- Home dashboard with weather information
- Quick action buttons
- Crop recommendation screen
- Process tracking screen
- AI advisor chatbot interface
- Crop health scanner (image-based)
- Profile management

### Planned Features
- Weather API integration
- Machine learning model for disease detection
- Rule-based expert system for crop recommendations
- Multi-language support (English & Kinyarwanda)
- Offline functionality
- Push notifications for alerts

## License

This project is part of academic research at the institution.

## Contact

Diana RUZINDANA
BSc. Software Engineering Student
