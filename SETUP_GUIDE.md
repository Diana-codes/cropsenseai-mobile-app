# CropSense AI - Setup Guide

## Fixing Android SDK Version Issues

Based on the error you encountered, here are the steps to resolve the Android SDK compatibility issues:

### Issue Summary
- The camera_android plugin requires Android SDK 36
- Multiple plugins require Android NDK 27.0.12077973
- Your current configuration uses older versions

### Solution

I've updated the Android configuration files to use:
- **compileSdk**: 36
- **targetSdkVersion**: 36
- **ndkVersion**: "27.0.12077973"

### Steps to Run the App

1. **Install Required SDK Components**

   Open Android Studio SDK Manager and install:
   - Android SDK Platform 36 (Android 14)
   - Android SDK Build-Tools 34.0.0 or higher
   - Android NDK 27.0.12077973

   Or use command line:
   ```bash
   sdkmanager "platforms;android-36"
   sdkmanager "build-tools;34.0.0"
   sdkmanager "ndk;27.0.12077973"
   ```

2. **Clean and Get Dependencies**
   ```bash
   cd ~/Desktop/cropsenseai-mobile-app
   flutter clean
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

### If You Still Have Issues

If the Android directory is incomplete or missing files, regenerate it:

```bash
# Remove existing android directory
rm -rf android

# Recreate it
flutter create --platforms=android .

# Then copy the updated build.gradle from this project
```

### Alternative: Using Lower SDK Versions

If you cannot install SDK 36, you can modify the camera plugin requirement or use an alternative approach:

1. **Update pubspec.yaml** to use older camera plugin version:
   ```yaml
   camera: ^0.10.0  # or earlier version that supports SDK 35
   ```

2. **Or remove camera temporarily**:
   Comment out camera-related dependencies in `pubspec.yaml` and related imports in `scanner_screen.dart`

### Environment Configuration

Make sure your `.env` file exists with:
```
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Permissions

The app requires these permissions (already configured in AndroidManifest.xml):
- INTERNET
- CAMERA
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE

### Testing Without Camera

If you want to test the app without camera functionality:
1. Comment out camera imports in `lib/screens/scanner/scanner_screen.dart`
2. Comment out `camera` and `image_picker` in `pubspec.yaml`
3. Run `flutter pub get`
4. Run `flutter run`

## Quick Start Commands

```bash
# Navigate to project
cd ~/Desktop/cropsenseai-mobile-app

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Check for issues
flutter doctor

# Run on connected device
flutter run

# Run in debug mode
flutter run --debug

# Run in release mode
flutter run --release
```

## Troubleshooting

### Gradle Issues
```bash
cd android
./gradlew clean
cd ..
flutter clean
```

### SDK License Issues
```bash
flutter doctor --android-licenses
```

### Plugin Issues
```bash
flutter pub cache repair
flutter pub get
```

## Contact

For issues specific to this project, refer to the research documentation or contact the project supervisor.
