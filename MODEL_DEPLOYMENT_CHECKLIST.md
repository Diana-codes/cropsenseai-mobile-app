# 🚀 CropSense AI - Quick Start Checklist

## ⚠️ Critical: Add Your Trained Model

Your Flutter app is ready, but you need to add the trained TFLite model:

### Step 1: Export Model from Notebook

In your Jupyter notebook, add this cell after training completes:

```python
# ════════════════════════════════════════════════════════════════════
# FINAL CELL: EXPORT MODEL FOR FLUTTER
# ════════════════════════════════════════════════════════════════════

print("="*80)
print("EXPORTING MODEL FOR FLUTTER DEPLOYMENT".center(80))
print("="*80)

# Convert to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(best_model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save to Google Drive
tflite_path = f'{OUTPUT_DIR}/cropsense_model.tflite'
with open(tflite_path, 'wb') as f:
    f.write(tflite_model)

print(f"\n✅ TFLite model saved to: {tflite_path}")
print(f"   Model size: {len(tflite_model) / (1024*1024):.2f} MB")

# Verify model works
interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\n📊 Model Details:")
print(f"   Input shape: {input_details[0]['shape']}")
print(f"   Output shape: {output_details[0]['shape']}")
print(f"   Input type: {input_details[0]['dtype']}")
print(f"   Classes: {label_encoder.classes_.tolist()}")

# Save class labels
labels_path = f'{OUTPUT_DIR}/labels.json'
with open(labels_path, 'w') as f:
    json.dump({
        'classes': label_encoder.classes_.tolist(),
        'model_version': '1.0.0',
        'input_size': IMG_HEIGHT,
        'accuracy': float(test_accuracy),
        'trained_date': datetime.now().isoformat()
    }, f, indent=2)

print(f"\n✅ Labels saved to: {labels_path}")
print("\n" + "="*80)
print("DOWNLOAD THESE FILES FROM GOOGLE DRIVE:".center(80))
print("="*80)
print(f"\n1. {tflite_path}")
print(f"2. {labels_path}")
print(f"\nThen copy cropsense_model.tflite to your Flutter project:")
print(f"   → assets/models/cropsense_model.tflite")
print("\n" + "="*80)
```

### Step 2: Download Model

1. Run the cell above in your notebook
2. Go to Google Drive: `/MyDrive/CropSense AI/outputs/`
3. Download `cropsense_model.tflite`
4. Download `labels.json` (optional, for verification)

### Step 3: Add to Flutter Project

```bash
# Copy the model to your Flutter assets folder
cp ~/Downloads/cropsense_model.tflite ./assets/models/cropsense_model.tflite

# Verify it's there
ls -lh assets/models/cropsense_model.tflite
# Should show ~14MB file
```

---

## ✅ Quick Verification Checklist

### Backend (Supabase) ✅ DONE

- [x] Database tables created (crop_diseases, disease_detections, etc.)
- [x] Seed data loaded (3 diseases + recommendations)
- [x] Storage bucket created (disease-images)
- [x] RLS policies configured
- [x] Edge function deployed (save-detection)

### Flutter App ✅ DONE

- [x] Dependencies added (tflite_flutter, image)
- [x] Models created (Disease, DetectionResult, Recommendation)
- [x] Service created (DiseaseDetectionService)
- [x] Provider created (DiseaseDetectionProvider)
- [x] Scanner screen updated with AI integration
- [x] Main.dart updated with provider

### What YOU Need to Do ⚠️

- [ ] **Run the export cell** in your Jupyter notebook
- [ ] **Download** `cropsense_model.tflite` from Google Drive
- [ ] **Copy** model to `assets/models/cropsense_model.tflite`
- [ ] **Run** `flutter pub get`
- [ ] **Test** the app with real crop images

---

## 🧪 Testing Your Integration

### Test 1: Model Loading

```bash
flutter run
# Watch console for: "✅ Model loaded successfully"
```

### Test 2: Image Detection

1. Open app
2. Navigate to Scanner screen
3. Take photo of a leaf (or use gallery)
4. Should see:
   - "Analyzing image with AI..."
   - Results with confidence scores
   - Top 3 predictions

### Test 3: Save & Recommendations

1. After detection, click "Save & Get Recommendations"
2. Fill in location and crop type
3. Click Save
4. Should see treatment recommendations sheet

---

## 📊 Expected Model Behavior

### Input
- Image size: 224x224 pixels
- Format: RGB
- Normalization: 0-1 range

### Output
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

### Classes
1. **Healthy** - No disease detected
2. **Powdery** - Powdery Mildew (fungal)
3. **Rust** - Rust disease (fungal)

---

## 🐛 Common Issues

### "Model not found"
**Solution**: Verify file exists at `assets/models/cropsense_model.tflite`

### "Failed to load model"
**Solution**: Run `flutter clean && flutter pub get`

### Low confidence scores
**Solution**: Ensure images are well-lit, focused crop leaves

### "Failed to upload image"
**Solution**: Check internet connection and user is logged in

---

## 📱 App Flow

```
User opens Scanner
       ↓
Takes/selects photo
       ↓
AI analyzes image (on-device)
       ↓
Shows disease prediction + confidence
       ↓
User clicks "Save & Get Recommendations"
       ↓
Uploads to Supabase Storage
       ↓
Saves to database via Edge Function
       ↓
Shows treatment recommendations
```

---

## 📞 Need Help?

Check these files:
- `INTEGRATION_GUIDE.md` - Detailed technical guide
- `README.md` - Project overview
- `SETUP_GUIDE.md` - Initial setup instructions

---

## 🎉 You're Almost Done!

Just add your trained model and you'll have a fully functional AI-powered crop disease detection system running on Flutter with Supabase backend!

**Next Step**: Run that export cell in your notebook! 🚀
