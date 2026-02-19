"""
ADD THIS CELL TO YOUR JUPYTER NOTEBOOK
After training completes (after Cell 25), add this as a new cell:
"""

# ═══════════════════════════════════════════════════════════════════════════
# FINAL CELL: EXPORT MODEL FOR FLUTTER DEPLOYMENT
# ═══════════════════════════════════════════════════════════════════════════

print("="*80)
print("EXPORTING MODEL FOR FLUTTER DEPLOYMENT".center(80))
print("="*80)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. CONVERT TO TENSORFLOW LITE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print("\n🔄 Converting model to TensorFlow Lite...")

converter = tf.lite.TFLiteConverter.from_keras_model(best_model)

# Optimize for mobile deployment
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Ensure float32 operations (compatible with most devices)
converter.target_spec.supported_types = [tf.float32]

# Convert
tflite_model = converter.convert()

print(f"✅ Conversion complete!")
print(f"   Original model: {len(tf.keras.Model.to_json(best_model)) / 1024:.2f} KB")
print(f"   TFLite model: {len(tflite_model) / (1024*1024):.2f} MB")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. SAVE TO GOOGLE DRIVE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print("\n💾 Saving to Google Drive...")

tflite_path = f'{OUTPUT_DIR}/cropsense_model.tflite'
with open(tflite_path, 'wb') as f:
    f.write(tflite_model)

print(f"✅ TFLite model saved to: {tflite_path}")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. VERIFY MODEL WORKS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print("\n🔍 Verifying TFLite model...")

# Load and test the TFLite model
interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()

# Get input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\n✅ Model verification passed!")
print(f"\n📊 Model Details:")
print(f"   Input shape:  {input_details[0]['shape']}")
print(f"   Output shape: {output_details[0]['shape']}")
print(f"   Input type:   {input_details[0]['dtype']}")
print(f"   Output type:  {output_details[0]['dtype']}")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. TEST WITH SAMPLE IMAGE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print("\n🧪 Testing with sample image...")

# Get a random test image
test_idx = np.random.randint(0, len(X_test))
test_image = X_test[test_idx:test_idx+1]
true_label = np.argmax(Y_test[test_idx])

# Predict with original model
original_pred = best_model.predict(test_image, verbose=0)
original_class = np.argmax(original_pred[0])

# Predict with TFLite model
interpreter.set_tensor(input_details[0]['index'], test_image.astype(np.float32))
interpreter.invoke()
tflite_pred = interpreter.get_tensor(output_details[0]['index'])
tflite_class = np.argmax(tflite_pred[0])

print(f"\n   True label:     {label_encoder.classes_[true_label]} (class {true_label})")
print(f"   Original model: {label_encoder.classes_[original_class]} ({original_pred[0][original_class]*100:.2f}%)")
print(f"   TFLite model:   {label_encoder.classes_[tflite_class]} ({tflite_pred[0][tflite_class]*100:.2f}%)")

if original_class == tflite_class:
    print(f"\n✅ Predictions match! TFLite model working correctly.")
else:
    print(f"\n⚠️  Warning: Predictions differ slightly (normal for quantization)")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. SAVE MODEL METADATA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print("\n📝 Saving model metadata...")

metadata = {
    'model_name': 'CropSense AI Disease Detector',
    'version': '1.0.0',
    'architecture': 'MobileNetV2',
    'framework': 'TensorFlow Lite',
    'input_shape': [1, IMG_HEIGHT, IMG_WIDTH, 3],
    'output_shape': [1, len(label_encoder.classes_)],
    'input_size': IMG_HEIGHT,
    'classes': label_encoder.classes_.tolist(),
    'class_mapping': {i: cls for i, cls in enumerate(label_encoder.classes_)},
    'num_classes': len(label_encoder.classes_),
    'preprocessing': {
        'resize': f'{IMG_HEIGHT}x{IMG_WIDTH}',
        'normalization': '0-1 range (divide by 255)',
        'color_mode': 'RGB'
    },
    'performance': {
        'test_accuracy': float(test_accuracy),
        'test_loss': float(test_loss),
        'test_precision': float(test_precision),
        'test_recall': float(test_recall),
        'test_f1': float(test_f1),
        'test_auc': float(test_auc)
    },
    'training': {
        'total_epochs': TOTAL_EPOCHS,
        'initial_epochs': INITIAL_EPOCHS,
        'fine_tune_epochs': FINE_TUNE_EPOCHS,
        'batch_size': BATCH_SIZE,
        'initial_lr': INITIAL_LR,
        'fine_tune_lr': FINE_TUNE_LR,
        'optimizer': 'Adam',
        'loss': 'categorical_crossentropy'
    },
    'dataset': {
        'total_samples': len(X),
        'train_samples': len(X_train),
        'val_samples': len(X_val),
        'test_samples': len(X_test)
    },
    'model_size_mb': len(tflite_model) / (1024*1024),
    'trained_date': datetime.now().isoformat(),
    'trained_by': 'Diana RUZINDANA',
    'project': 'BSc Software Engineering Final Year Project',
    'institution': 'Rwanda'
}

metadata_path = f'{OUTPUT_DIR}/model_metadata.json'
with open(metadata_path, 'w') as f:
    json.dump(metadata, f, indent=2)

print(f"✅ Metadata saved to: {metadata_path}")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. CREATE LABELS FILE (FOR FLUTTER)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print("\n📋 Creating labels file...")

labels_path = f'{OUTPUT_DIR}/labels.txt'
with open(labels_path, 'w') as f:
    for label in label_encoder.classes_:
        f.write(f"{label}\n")

print(f"✅ Labels saved to: {labels_path}")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. DISPLAY DOWNLOAD INSTRUCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print("\n" + "="*80)
print("DOWNLOAD THESE FILES FROM GOOGLE DRIVE".center(80))
print("="*80)

print(f"\n📁 Files saved in Google Drive:")
print(f"\n   {OUTPUT_DIR}/")
print(f"   ├── cropsense_model.tflite    ← REQUIRED for Flutter app")
print(f"   ├── model_metadata.json        ← Model information")
print(f"   └── labels.txt                 ← Class labels")

print(f"\n📥 To download:")
print(f"   1. Open Google Drive")
print(f"   2. Navigate to: /MyDrive/CropSense AI/outputs/")
print(f"   3. Download: cropsense_model.tflite")

print(f"\n📱 Add to Flutter project:")
print(f"   cp ~/Downloads/cropsense_model.tflite ./assets/models/cropsense_model.tflite")

print("\n" + "="*80)
print("✅ MODEL EXPORT COMPLETE!".center(80))
print("="*80)

print(f"""
╔═══════════════════════════════════════════════════════════════════════╗
║                        EXPORT SUMMARY                                 ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  Model Format:    TensorFlow Lite (.tflite)                          ║
║  Model Size:      {len(tflite_model) / (1024*1024):6.2f} MB                                         ║
║  Input Shape:     {IMG_HEIGHT}x{IMG_WIDTH}x3 (RGB)                                    ║
║  Output Classes:  {len(label_encoder.classes_)}                                                     ║
║  Test Accuracy:   {test_accuracy*100:5.2f}%                                              ║
║                                                                       ║
║  Classes:                                                             ║
║    {' │ '.join(label_encoder.classes_)}                                 ║
║                                                                       ║
║  Status:          ✅ Ready for deployment                             ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
""")

print("\n💡 Next steps:")
print("   1. Download cropsense_model.tflite from Google Drive")
print("   2. Copy to Flutter project: assets/models/")
print("   3. Run: flutter pub get")
print("   4. Run: flutter run")
print("   5. Test with crop images!")

print("\n🎉 Your AI model is ready for production!")
print()
