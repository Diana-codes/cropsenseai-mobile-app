import 'dart:convert';
import 'package:http/http.dart' as http;

/// Shared API service for CropSense backend.
const String _apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

class ApiService {
  static String get baseUrl => _apiBaseUrl;

  /// Fetch weather for a location. Pass province/district for accurate coordinates.
  static Future<Map<String, dynamic>?> getWeather({
    String location = 'Rwanda',
    String province = '',
    String district = '',
  }) async {
    try {
      var uri = Uri.parse('$_apiBaseUrl/weather').replace(
        queryParameters: {
          'location': location,
          if (province.isNotEmpty) 'province': province,
          if (district.isNotEmpty) 'district': district,
        },
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Weather request timed out'),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Fetch crop recommendations from advisor API.
  static Future<Map<String, dynamic>?> getAdvisorRecommendations({
    required String province,
    required String district,
    required String season,
    required String landType,
    String sector = '',
    String cell = '',
    String village = '',
  }) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/advisor');
      final payload = {
        'province': province,
        'district': district,
        'sector': sector,
        'cell': cell,
        'village': village,
        'season': season,
        'landType': _normalizeLandType(landType),
      };
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Advisor request timed out'),
      );
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Normalize display land type to backend format (wetland, hillside, valley, plateau).
  static String _normalizeLandType(String display) {
    final t = display.toLowerCase();
    if (t.contains('wetland') || t.contains('marsh')) return 'wetland';
    if (t.contains('hillside')) return 'hillside';
    if (t.contains('valley')) return 'valley';
    if (t.contains('plateau')) return 'plateau';
    return t;
  }

  /// Same as above, but public for use in screens.
  static String normalizeLandType(String display) => _normalizeLandType(display);
}
