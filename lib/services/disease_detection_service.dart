import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/disease.dart';

class DiseaseDetectionService {
  static const String modelPath = 'assets/models/cropsense_model.tflite';
  static const int inputSize = 224;
  static const List<String> labels = ['Healthy', 'Powdery', 'Rust'];

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isModelLoaded = true;
      print('✅ Model loaded successfully');
    } catch (e) {
      print('❌ Error loading model: $e');
      throw Exception('Failed to load disease detection model: $e');
    }
  }

  Future<Map<String, dynamic>> detectDisease(File imageFile) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    final preprocessed = await _preprocessImage(imageFile);
    final predictions = _runInference(preprocessed);
    final result = _parseResults(predictions);

    return result;
  }

  Future<Uint8List> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);

        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input.buffer.asUint8List();
  }

  List<double> _runInference(Uint8List input) {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }

    final inputBuffer = input.buffer.asFloat32List();
    final inputTensor = inputBuffer.reshape([1, inputSize, inputSize, 3]);

    final outputTensor = List.filled(1 * labels.length, 0.0).reshape([1, labels.length]);

    _interpreter!.run(inputTensor, outputTensor);

    return List<double>.from(outputTensor[0]);
  }

  Map<String, dynamic> _parseResults(List<double> predictions) {
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < labels.length; i++) {
      results.add({
        'disease': labels[i],
        'confidence': predictions[i],
      });
    }

    results.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

    final topPrediction = results[0];
    final topThree = results.take(3).toList();

    return {
      'top_disease': topPrediction['disease'],
      'confidence': topPrediction['confidence'],
      'top_predictions': topThree,
      'all_predictions': results,
    };
  }


  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
