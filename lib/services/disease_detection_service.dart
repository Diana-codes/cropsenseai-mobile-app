import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/disease.dart';

class DiseaseDetectionService {
  static const String modelPath = 'assets/models/cropsense_model.tflite';
  static const int inputSize = 224;
  static const List<String> labels = ['Healthy', 'Powdery', 'Rust'];

  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'detections/${_supabase.auth.currentUser?.id}/$fileName';

      await _supabase.storage.from('disease-images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage
          .from('disease-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<Map<String, dynamic>> saveDetection({
    required File imageFile,
    required Map<String, dynamic> detectionResult,
    String? location,
    String? cropType,
    String? notes,
  }) async {
    try {
      final imageUrl = await uploadImage(imageFile);

      final diseaseId = await _getDiseaseId(
        detectionResult['top_disease'] as String,
      );

      final response = await _supabase.functions.invoke(
        'save-detection',
        body: {
          'disease_id': diseaseId,
          'image_url': imageUrl,
          'confidence_score': detectionResult['confidence'],
          'top_predictions': detectionResult['top_predictions'],
          'location': location,
          'crop_type': cropType,
          'notes': notes,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to save detection: ${response.data}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error saving detection: $e');
      throw Exception('Failed to save detection: $e');
    }
  }

  Future<String?> _getDiseaseId(String diseaseName) async {
    try {
      final response = await _supabase
          .from('crop_diseases')
          .select('id')
          .eq('name', diseaseName)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      print('❌ Error getting disease ID: $e');
      return null;
    }
  }

  Future<List<DetectionResult>> getUserDetections() async {
    try {
      final response = await _supabase
          .from('disease_detections')
          .select('''
            *,
            disease:crop_diseases(
              id,
              name,
              description,
              symptoms,
              severity_level,
              affected_crops
            )
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DetectionResult.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching detections: $e');
      throw Exception('Failed to fetch detections: $e');
    }
  }

  Future<List<Recommendation>> getRecommendations(String diseaseId) async {
    try {
      final response = await _supabase
          .from('recommendations')
          .select('*')
          .eq('disease_id', diseaseId)
          .order('priority', ascending: true);

      return (response as List)
          .map((json) => Recommendation.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching recommendations: $e');
      throw Exception('Failed to fetch recommendations: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
