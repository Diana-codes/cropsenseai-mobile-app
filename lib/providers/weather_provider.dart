import 'package:flutter/material.dart';

class WeatherProvider extends ChangeNotifier {
  Map<String, dynamic> _currentWeather = {
    'temperature': 24,
    'condition': 'Sunny',
    'humidity': 65,
    'rainfall': 0,
  };

  bool _isLoading = false;

  Map<String, dynamic> get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;

  Future<void> fetchWeather(String location) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _currentWeather = {
      'temperature': 24,
      'condition': 'Sunny',
      'humidity': 65,
      'rainfall': 0,
      'forecast': [
        {'day': 'Mon', 'temp': 25, 'condition': 'Sunny'},
        {'day': 'Tue', 'temp': 23, 'condition': 'Cloudy'},
        {'day': 'Wed', 'temp': 22, 'condition': 'Rainy'},
        {'day': 'Thu', 'temp': 24, 'condition': 'Sunny'},
        {'day': 'Fri', 'temp': 26, 'condition': 'Sunny'},
      ],
    };

    _isLoading = false;
    notifyListeners();
  }
}
