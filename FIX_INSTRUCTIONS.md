# Quick Fix Instructions for CropSense AI

## Current Situation
The app **built successfully** ✓ but has installation issues with the emulator.

## Issues to Fix

### 1. Fix build.gradle.kts (SDK Version)

**Copy this file** from the project to your local directory:
```bash
cp android/app/build.gradle.kts ~/Desktop/cropsenseai-mobile-app/android/app/build.gradle.kts
```

Or **manually edit** `/home/diana/Desktop/cropsenseai-mobile-app/android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 36  // Change from 35 to 36
    ndkVersion = "27.0.12077973"  // Add this line or update

    defaultConfig {
        targetSdk = 36  // Change from 35 to 36
        // ... rest of config
    }
}
```

### 2. Create Missing Asset Folders

```bash
cd ~/Desktop/cropsenseai-mobile-app
mkdir -p assets/images
mkdir -p assets/icons
touch assets/images/.gitkeep
touch assets/icons/.gitkeep
```

### 3. Fix Emulator Issue

The error `cmd: Can't find service: package` means your emulator has issues. Try:

**Option A: Restart Emulator (Recommended)**
```bash
# Stop current emulator
adb devices
adb -s <device_name> emu kill

# Start fresh emulator from Android Studio
# Device Manager > Run your emulator
```

**Option B: Use a Physical Device**
- Connect your Android phone via USB
- Enable Developer Options & USB Debugging
- Run `flutter run` again

**Option C: Create New Emulator**
1. Open Android Studio
2. Device Manager > Create Device
3. Choose Pixel 5 or newer
4. System Image: API 34 (Android 14) or API 35
5. Finish and launch

### 4. Install Required SDK Components

Looking at your screenshot, you need:

**From Android Studio SDK Manager:**
1. Go to Settings > Languages & Frameworks > Android SDK
2. Check "Android SDK Platform-Tools" version 36.0.2 ✓ (you have this)
3. Check "Android Emulator" version 36.4.9 ✓ (you have this)

**Install from command line:**
```bash
sdkmanager "platforms;android-36"
sdkmanager "ndk;27.0.12077973"
sdkmanager "build-tools;34.0.0"
```

Or install via Android Studio as shown in your screenshot.

## Complete Fix Steps

Run these commands in order:

```bash
# 1. Navigate to project
cd ~/Desktop/cropsenseai-mobile-app

# 2. Copy the fixed build.gradle.kts
# (copy from this project or manually edit as shown above)

# 3. Create asset directories
mkdir -p assets/images assets/icons
touch assets/images/.gitkeep assets/icons/.gitkeep

# 4. Clean project
flutter clean

# 5. Get dependencies
flutter pub get

# 6. Check device connection
flutter devices

# 7. Kill and restart emulator
adb devices
adb kill-server
adb start-server

# 8. Start emulator (or use physical device)

# 9. Run app
flutter run
```

## If You Still Get Errors

### SDK 36 Not Installed

**Option 1: Install SDK 36** (Recommended)
```bash
sdkmanager "platforms;android-36"
```

**Option 2: Use SDK 35** (if SDK 36 unavailable)
Edit `android/app/build.gradle.kts`:
```kotlin
compileSdk = 35
targetSdk = 35
```

And update `pubspec.yaml` to use compatible camera version:
```yaml
camera: ^0.10.0  # older version compatible with SDK 35
```

### Emulator Not Working

**Use Physical Device:**
1. Enable Developer Options on your phone
2. Enable USB Debugging
3. Connect USB
4. Run `flutter run`

### NDK Issues

If you can't install NDK 27, comment out camera temporarily:

Edit `pubspec.yaml`:
```yaml
dependencies:
  # camera: ^0.10.5+5  # commented out
  # image_picker: ^1.0.4  # commented out
```

Then in `lib/screens/scanner/scanner_screen.dart`, add at the top:
```dart
// TODO: Implement camera when NDK 27 is available
```

## Verification

After fixes, you should see:
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing build/app/outputs/flutter-apk/app-debug.apk...
✓ App installed successfully
```

## Quick Test Without Camera

If you want to test the app quickly without camera:

1. Comment out camera dependencies in `pubspec.yaml`
2. Run `flutter pub get`
3. Navigate to scanner screen - it will show placeholder
4. Test all other features (login, home, recommendations, etc.)

## Your Current Status

Based on your terminal output:
- ✓ Flutter is working
- ✓ Build completed successfully
- ✓ APK was created
- ✗ Emulator installation failed (fixable)

The app is ready - just need to fix the emulator or use a physical device!
