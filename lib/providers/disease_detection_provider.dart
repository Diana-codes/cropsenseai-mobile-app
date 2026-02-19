import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/disease.dart';

class DiseaseDetectionProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isModelLoaded = true;
  String? _error;
  Map<String, dynamic>? _currentDetection;
  List<DetectionResult> _detectionHistory = [];
  List<Recommendation> _recommendations = [];

  bool get isLoading => _isLoading;
  bool get isModelLoaded => _isModelLoaded;
  String? get error => _error;
  Map<String, dynamic>? get currentDetection => _currentDetection;
  List<DetectionResult> get detectionHistory => _detectionHistory;
  List<Recommendation> get recommendations => _recommendations;

  final List<String> _diseases = [
    'Healthy',
    'Leaf Blight',
    'Brown Spot',
    'Powdery Mildew',
    'Rust Disease',
    'Bacterial Leaf Streak',
  ];

  Future<void> initializeModel() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isModelLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> detectDisease(File imageFile) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final topDisease = _diseases[random.nextInt(_diseases.length)];
    final confidence = 0.7 + random.nextDouble() * 0.25;

    final predictions = _diseases.map((disease) {
      return {
        'disease': disease,
        'confidence': disease == topDisease ? confidence : random.nextDouble() * 0.3,
      };
    }).toList()
      ..sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

    _currentDetection = {
      'top_disease': topDisease,
      'confidence': confidence,
      'top_predictions': predictions.take(3).toList(),
    };

    _isLoading = false;
    notifyListeners();

    return _currentDetection;
  }

  Future<Map<String, dynamic>?> saveDetection({
    required File imageFile,
    required Map<String, dynamic> detectionResult,
    String? location,
    String? cropType,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _recommendations = [
      Recommendation(
        id: '1',
        diseaseId: 'mock-disease-1',
        recommendationType: 'treatment',
        title: 'Apply Fungicide Treatment',
        description: 'Use a copper-based fungicide to treat the infected areas',
        steps: [
          'Mix fungicide according to package instructions',
          'Apply evenly to affected leaves',
          'Repeat treatment after 7 days',
        ],
        products: [],
        organicOptions: ['Neem oil', 'Copper sulfate solution'],
        effectivenessRating: 4,
        costEstimate: 5000,
        priority: 1,
      ),
      Recommendation(
        id: '2',
        diseaseId: 'mock-disease-1',
        recommendationType: 'prevention',
        title: 'Improve Air Circulation',
        description: 'Prune nearby vegetation to increase airflow',
        steps: [
          'Remove overcrowded plants',
          'Trim dense foliage',
          'Space plants appropriately',
        ],
        products: [],
        organicOptions: [],
        effectivenessRating: 3,
        costEstimate: 0,
        priority: 2,
      ),
      Recommendation(
        id: '3',
        diseaseId: 'mock-disease-1',
        recommendationType: 'management',
        title: 'Remove Infected Leaves',
        description: 'Manually remove and destroy infected plant material',
        steps: [
          'Identify severely infected leaves',
          'Cut leaves at the base',
          'Dispose of infected material away from crops',
        ],
        products: [],
        organicOptions: [],
        effectivenessRating: 3,
        costEstimate: 0,
        priority: 2,
      ),
    ];

    await loadDetectionHistory();

    _isLoading = false;
    notifyListeners();

    return {
      'success': true,
      'recommendations': _recommendations,
    };
  }

  Future<void> loadDetectionHistory() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _detectionHistory = [
      DetectionResult(
        id: '1',
        userId: 'mock-user-123',
        diseaseId: 'disease-1',
        imageUrl: 'https://example.com/image1.jpg',
        confidenceScore: 0.92,
        topPredictions: [
          PredictionScore(disease: 'Leaf Blight', confidence: 0.92),
          PredictionScore(disease: 'Brown Spot', confidence: 0.05),
          PredictionScore(disease: 'Healthy', confidence: 0.03),
        ],
        location: 'Bugesera District',
        cropType: 'Rice',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DetectionResult(
        id: '2',
        userId: 'mock-user-123',
        imageUrl: 'https://example.com/image2.jpg',
        confidenceScore: 0.98,
        topPredictions: [
          PredictionScore(disease: 'Healthy', confidence: 0.98),
          PredictionScore(disease: 'Leaf Blight', confidence: 0.01),
          PredictionScore(disease: 'Brown Spot', confidence: 0.01),
        ],
        location: 'Kigali',
        cropType: 'Beans',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecommendations(String diseaseId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentDetection() {
    _currentDetection = null;
    notifyListeners();
  }
}
