# CropSense AI - Model Integration Guide

This guide explains how to integrate your trained disease detection model with the CropSense AI Flutter frontend.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Database Setup](#database-setup)
3. [Model Deployment](#model-deployment)
4. [Storage Configuration](#storage-configuration)
5. [Flutter Integration](#flutter-integration)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

The CropSense AI system uses a MobileNetV2-based model trained on crop disease images. The integration involves:

- **Backend**: Supabase database + Edge Functions
- **Model**: TensorFlow Lite model running on-device
- **Frontend**: Flutter app with image capture and AI inference

## 📊 Database Setup

### ✅ Already Completed

The database schema has been created with the following tables:

1. **crop_diseases** - Disease information (Healthy, Powdery, Rust)
2. **disease_detections** - User scan history
3. **recommendations** - Treatment recommendations
4. **crop_calendar** - Rwanda crop calendar data
5. **user_farms** - User farm profiles

### Seed Data

The database includes:
- 3 disease types (Healthy, Powdery Mildew, Rust)
- Treatment and prevention recommendations
- Complete with RLS policies for data security

---

## 🤖 Model Deployment

### Step 1: Convert Model to TFLite

From your Jupyter notebook (Cell 25+), you should have generated:

```python
# Cell 25: Export TFLite Model
converter = tf.lite.TFLiteConverter.from_keras_model(best_model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save model
with open('cropsense_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

### Step 2: Add Model to Flutter Project

1. **Download the TFLite model** from your Google Colab output:
   ```
   /content/drive/MyDrive/CropSense AI/outputs/cropsense_model.tflite
   ```

2. **Copy to Flutter project**:
   ```bash
   cp cropsense_model.tflite ./assets/models/cropsense_model.tflite
   ```

3. **Verify file size**:
   - Expected size: ~14 MB (MobileNetV2)
   - File should be in `assets/models/` directory

### Step 3: Model Metadata

Create `assets/models/model_info.json`:

```json
{
  "model_name": "CropSense AI Disease Detector",
  "version": "1.0.0",
  "architecture": "MobileNetV2",
  "input_size": 224,
  "classes": ["Healthy", "Powdery", "Rust"],
  "training_date": "2026-01",
  "accuracy": 0.95,
  "labels": {
    "0": "Healthy",
    "1": "Powdery",
    "2": "Rust"
  }
}
```

---

## 💾 Storage Configuration

### Create Storage Bucket

Run this in Supabase SQL Editor or use the Dashboard:

```sql
-- Create storage bucket for disease images
INSERT INTO storage.buckets (id, name, public)
VALUES ('disease-images', 'disease-images', true)
ON CONFLICT DO NOTHING;

-- Set up storage policies
CREATE POLICY "Users can upload own images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'disease-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view own images"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'disease-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Public can view images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'disease-images');
```

### Via Supabase Dashboard:

1. Go to **Storage** section
2. Click **Create Bucket**
3. Name: `disease-images`
4. Public: **Yes** ✅
5. File size limit: 5 MB
6. Allowed MIME types: `image/jpeg, image/png`

---

## 📱 Flutter Integration

### Step 1: Install Dependencies

The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
  tflite_flutter: ^0.10.4     # TensorFlow Lite
  image: ^4.1.3                # Image processing
  image_picker: ^1.0.4         # Camera/gallery
  supabase_flutter: ^2.0.0     # Backend
  provider: ^6.1.1             # State management
```

Run:
```bash
flutter pub get
```

### Step 2: Verify File Structure

Your project should have:

```
lib/
├── models/
│   └── disease.dart                          ✅ Created
├── services/
│   └── disease_detection_service.dart        ✅ Created
├── providers/
│   └── disease_detection_provider.dart       ✅ Created
├── screens/
│   └── scanner/
│       └── scanner_screen.dart               ✅ Updated
└── main.dart                                 ✅ Updated

assets/
└── models/
    ├── cropsense_model.tflite               ⚠️ YOU NEED TO ADD THIS
    └── model_info.json                       ℹ️ Optional

supabase/
└── functions/
    └── save-detection/
        └── index.ts                          ✅ Deployed
```

### Step 3: Edge Function

The `save-detection` Edge Function is **already deployed** ✅

It handles:
- Saving detection results
- Fetching disease information
- Retrieving recommendations

---

## 🧪 Testing

### 1. Test Model Loading

```dart
// In your app's initialization
final provider = context.read<DiseaseDetectionProvider>();
await provider.initializeModel();

if (provider.isModelLoaded) {
  print('✅ Model loaded successfully');
} else {
  print('❌ Model failed to load: ${provider.error}');
}
```

### 2. Test Image Detection

```dart
// After taking/selecting an image
File imageFile = /* your image file */;
final result = await provider.detectDisease(imageFile);

print('Top disease: ${result['top_disease']}');
print('Confidence: ${result['confidence']}');
print('All predictions: ${result['top_predictions']}');
```

### 3. Test Data Saving

```dart
// Save detection to database
final response = await provider.saveDetection(
  imageFile: imageFile,
  detectionResult: result,
  location: 'Kigali, Rwanda',
  cropType: 'Beans',
);

print('Detection ID: ${response['detection']['id']}');
print('Recommendations: ${response['recommendations'].length}');
```

### 4. Expected Output

```json
{
  "top_disease": "Powdery",
  "confidence": 0.92,
  "top_predictions": [
    {"disease": "Powdery", "confidence": 0.92},
    {"disease": "Rust", "confidence": 0.06},
    {"disease": "Healthy", "confidence": 0.02}
  ]
}
```

---

## 🔧 Troubleshooting

### Model Not Loading

**Issue**: `Failed to load disease detection model`

**Solutions**:
1. Verify model file exists: `assets/models/cropsense_model.tflite`
2. Check `pubspec.yaml` includes model assets
3. Run `flutter clean && flutter pub get`
4. Rebuild app completely

### Low Prediction Accuracy

**Issue**: Model gives incorrect predictions

**Solutions**:
1. Verify image preprocessing matches training (224x224, RGB, normalized 0-1)
2. Check label order matches training: `['Healthy', 'Powdery', 'Rust']`
3. Ensure TFLite conversion preserved model accuracy
4. Test with images similar to training data

### Image Upload Fails

**Issue**: `Failed to upload image`

**Solutions**:
1. Check storage bucket `disease-images` exists
2. Verify user is authenticated
3. Check RLS policies allow user uploads
4. Ensure file size < 5MB

### Edge Function Error

**Issue**: `Failed to save detection`

**Solutions**:
1. Verify edge function is deployed: `supabase functions list`
2. Check user authentication token is valid
3. Verify disease_id exists in `crop_diseases` table
4. Check edge function logs in Supabase Dashboard

### Database Errors

**Issue**: RLS policy violations

**Solutions**:
1. Verify user is authenticated
2. Check `auth.uid()` matches `user_id` in query
3. Review RLS policies in Supabase Dashboard
4. Check foreign key references are valid

---

## 📈 Model Performance

Based on your notebook's final metrics:

| Metric | Value |
|--------|-------|
| Test Accuracy | ~95% |
| Model Size | ~14 MB |
| Input Size | 224x224 RGB |
| Classes | 3 (Healthy, Powdery, Rust) |
| Inference Time | <500ms on device |

---

## 🚀 Next Steps

### 1. Add More Diseases

To expand the model:

```sql
-- Add new disease
INSERT INTO crop_diseases (name, description, severity_level, affected_crops)
VALUES (
  'Leaf Spot',
  'Fungal disease causing dark spots on leaves',
  'medium',
  ARRAY['Beans', 'Tomatoes']
);

-- Add recommendations
INSERT INTO recommendations (disease_id, recommendation_type, title, ...)
SELECT id, 'treatment', 'Leaf Spot Treatment', ...
FROM crop_diseases WHERE name = 'Leaf Spot';
```

Then retrain model with new disease class.

### 2. Improve Model

- Collect more training data from Rwanda
- Use data augmentation (already implemented)
- Fine-tune with local crop varieties
- Add confidence threshold filtering

### 3. Add Features

- **Offline mode**: Cache model predictions
- **History**: View past scans
- **Analytics**: Track disease trends
- **Alerts**: Notify about disease outbreaks
- **Multi-language**: Add Kinyarwanda support

---

## 📞 Support

If you encounter issues:

1. Check Supabase logs: Dashboard → Logs
2. Check Flutter logs: `flutter logs`
3. Verify database: Query tables directly
4. Test edge functions: Use Supabase Dashboard → Functions

---

## ✅ Checklist

Before going live:

- [ ] TFLite model added to `assets/models/`
- [ ] Model loads successfully in app
- [ ] Storage bucket `disease-images` created
- [ ] Edge function `save-detection` deployed
- [ ] RLS policies tested with real users
- [ ] Test detection with various crop images
- [ ] Verify recommendations display correctly
- [ ] Test offline behavior (no internet)
- [ ] Check error handling for edge cases

---

## 📝 Notes

- Model expects **normalized RGB images** (0-1 range)
- Disease labels must match exactly: `Healthy`, `Powdery`, `Rust`
- Images are stored in: `detections/{user_id}/{timestamp}.jpg`
- All times are in UTC
- Costs estimated in Rwandan Francs (RWF)

Good luck with your deployment! 🌱
