import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    // Retry because Open-Meteo can occasionally return partial data. Never drop
    // province/district on the first retries — clearing them forced Kigali coords
    // for everyone and made Rwamagana vs Kigali look identical.
    Future<void> shortDelay() => Future<void>.delayed(
          Duration(milliseconds: Random().nextInt(150)),
        );

    final first = await _getWeatherOnce(
      location: location,
      province: province,
      district: district,
    );
    if (_weatherHasValidFields(first)) return first;

    await shortDelay();
    final second = await _getWeatherOnce(
      location: location,
      province: province,
      district: district,
    );
    if (_weatherHasValidFields(second)) return second;

    // Province-level only (still distinct from other provinces)
    if (province.isNotEmpty) {
      await shortDelay();
      final third = await _getWeatherOnce(
        location: province,
        province: province,
        district: '',
      );
      if (_weatherHasValidFields(third)) return third;
    }

    // Last resort: national default on the server (Kigali-area default coords)
    await shortDelay();
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

  static Map<String, String> _authJsonHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Active season plan from server (requires login). Null if none or error.
  static Future<Map<String, dynamic>?> getActiveSeasonPlan(String? token) async {
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http
          .get(
            Uri.parse('$_apiBaseUrl/season-plans/active'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final plan = decoded['plan'];
      if (plan is Map<String, dynamic>) return plan;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save a new active season plan (replaces previous active plan on server).
  static Future<Map<String, dynamic>?> createSeasonPlan({
    required String token,
    required String province,
    required String district,
    required String sector,
    required String cell,
    required String village,
    required String season,
    required String landType,
    required String landSize,
    Map<String, dynamic>? advisor,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_apiBaseUrl/season-plans'),
            headers: _authJsonHeaders(token),
            body: jsonEncode({
              'province': province,
              'district': district,
              'sector': sector,
              'cell': cell,
              'village': village,
              'season': season,
              'land_type': landType,
              'land_size': landSize,
              if (advisor != null) 'advisor': advisor,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final plan = decoded['plan'];
      if (plan is Map<String, dynamic>) return plan;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Advisor cache ─────────────────────────────────────────────────────────

  static const _advisorCacheKey = 'cropsense_advisor_cache_v1';
  static const _advisorCacheTtlMinutes = 360; // 6 hours

  static Future<Map<String, dynamic>?> getCachedAdvisor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_advisorCacheKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['_savedAt'] as String? ?? '');
      if (savedAt == null) return null;
      final age = DateTime.now().difference(savedAt).inMinutes;
      if (age > _advisorCacheTtlMinutes) return null;
      return Map<String, dynamic>.from(decoded)..remove('_savedAt');
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAdvisorCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = Map<String, dynamic>.from(data)
        ..['_savedAt'] = DateTime.now().toIso8601String();
      await prefs.setString(_advisorCacheKey, jsonEncode(toSave));
    } catch (_) {}
  }

  // ── Weather cache ──────────────────────────────────────────────────────────

  static const _weatherCacheKey = 'cropsense_weather_cache_v1';
  static const _weatherCacheTtlMinutes = 120; // 2 hours

  /// Returns the last cached weather if still fresh, otherwise null.
  static Future<Map<String, dynamic>?> getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_weatherCacheKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['_savedAt'] as String? ?? '');
      if (savedAt == null) return null;
      final age = DateTime.now().difference(savedAt).inMinutes;
      if (age > _weatherCacheTtlMinutes) return null;
      return Map<String, dynamic>.from(decoded)..remove('_savedAt');
    } catch (_) {
      return null;
    }
  }

  /// Persists weather data to local cache with a timestamp.
  static Future<void> saveWeatherCache(Map<String, dynamic> weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = Map<String, dynamic>.from(weather)
        ..['_savedAt'] = DateTime.now().toIso8601String();
      await prefs.setString(_weatherCacheKey, jsonEncode(toSave));
    } catch (_) {}
  }

  // ── Season plan helpers ────────────────────────────────────────────────────

  /// Update one or more stages (e.g. `{key, done}`). Returns updated plan.
  static Future<Map<String, dynamic>?> updateSeasonPlanStages({
    required String token,
    required int planId,
    required List<Map<String, dynamic>> stages,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$_apiBaseUrl/season-plans/$planId/stages'),
            headers: _authJsonHeaders(token),
            body: jsonEncode({'stages': stages}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final plan = decoded['plan'];
      if (plan is Map<String, dynamic>) return plan;
      return null;
    } catch (_) {
      return null;
    }
  }
}
