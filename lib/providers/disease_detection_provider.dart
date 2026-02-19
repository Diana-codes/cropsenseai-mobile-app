import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/disease_detection_service.dart';
import '../models/disease.dart';

class DiseaseDetectionProvider with ChangeNotifier {
  final DiseaseDetectionService _service = DiseaseDetectionService();

  bool _isLoading = false;
  bool _isModelLoaded = false;
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

  Future<void> initializeModel() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _service.loadModel();

      _isModelLoaded = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isModelLoaded = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> detectDisease(File imageFile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _service.detectDisease(imageFile);
      _currentDetection = result;

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> saveDetection({
    required File imageFile,
    required Map<String, dynamic> detectionResult,
    String? location,
    String? cropType,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _service.saveDetection(
        imageFile: imageFile,
        detectionResult: detectionResult,
        location: location,
        cropType: cropType,
        notes: notes,
      );

      await loadDetectionHistory();

      if (response['recommendations'] != null) {
        _recommendations = (response['recommendations'] as List)
            .map((json) => Recommendation.fromJson(json))
            .toList();
      }

      _isLoading = false;
      notifyListeners();

      return response;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadDetectionHistory() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _detectionHistory = await _service.getUserDetections();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendations(String diseaseId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recommendations = await _service.getRecommendations(diseaseId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentDetection() {
    _currentDetection = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
