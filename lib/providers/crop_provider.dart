import 'package:flutter/material.dart';

class CropProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, dynamic>? _currentSeason;
  bool _isLoading = false;

  List<Map<String, dynamic>> get recommendations => _recommendations;
  Map<String, dynamic>? get currentSeason => _currentSeason;
  bool get isLoading => _isLoading;

  void setRecommendations(List<Map<String, dynamic>> recommendations) {
    _recommendations = recommendations;
    notifyListeners();
  }

  void setCurrentSeason(Map<String, dynamic> season) {
    _currentSeason = season;
    notifyListeners();
  }

  Future<void> fetchRecommendations(String location, String season) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _recommendations = [
      {
        'name': 'Rice (DMIS variety)',
        'suitability': 'Excellent',
        'yield_potential': 'High',
        'duration': '120-140 days',
        'risk_level': 'Low',
        'confidence': 95,
      },
      {
        'name': 'Maize Hybrid variety',
        'suitability': 'Good',
        'yield_potential': 'Medium',
        'duration': '90-110 days',
        'risk_level': 'Medium',
        'confidence': 87,
      },
    ];

    _isLoading = false;
    notifyListeners();
  }
}
