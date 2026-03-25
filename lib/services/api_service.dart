import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Shared API service for CropSense backend.
const String _apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'https://cropsenseai-mobile-app.onrender.com');

class ApiService {
  static String get baseUrl => _apiBaseUrl;

  static bool _weatherHasValidFields(Map<String, dynamic>? weather) {
    if (weather == null) return false;

    bool isValid(dynamic v) {
      if (v == null) return false;
      if (v is num) return true;
      final s = v.toString().trim();
      if (s.isEmpty) return false;
      return s.toUpperCase() != 'N/A';
    }

    return isValid(weather['temperature']) &&
        isValid(weather['humidity']) &&
        isValid(weather['wind_speed']) &&
        isValid(weather['timestamp']);
  }

  static Future<Map<String, dynamic>?> _getWeatherOnce({
    required String location,
    required String province,
    required String district,
  }) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/weather').replace(
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

  /// Fetch weather for a location. Pass province/district for accurate coordinates.
  static Future<Map<String, dynamic>?> getWeather({
    String location = 'Rwanda',
    String province = '',
    String district = '',
  }) async {
    // Retry/fallback because Open-Meteo can occasionally return partial/placeholder data.
    final first = await _getWeatherOnce(
      location: location,
      province: province,
      district: district,
    );
    if (_weatherHasValidFields(first)) return first;

    // Fallback to server default (Rwanda coordinates) for better stability.
    await Future<void>.delayed(
      Duration(milliseconds: Random().nextInt(150)),
    );

    return _getWeatherOnce(
      location: 'Rwanda',
      province: '',
      district: '',
    );
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
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded == null) return null;

      // The advisor endpoint returns `weather`. If it's placeholder, refresh separately.
      final weather = decoded['weather'] as Map<String, dynamic>?;
      if (!_weatherHasValidFields(weather)) {
        final locationName = (district.isNotEmpty && province.isNotEmpty)
            ? '$district, $province'
            : province.isNotEmpty
                ? province
                : 'Rwanda';

        final refreshed = await getWeather(
          location: locationName,
          province: province,
          district: district,
        );
        if (refreshed != null) {
          decoded['weather'] = refreshed;
        }
      }

      return decoded;
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
