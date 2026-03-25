import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'local_profile_service.dart';

class AuthService {
  static const _tokenKey = 'cropsense_auth_token_v1';
  final _profileService = LocalProfileService();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? province,
    String? district,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/auth/register');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'full_name': fullName,
            'phone': phone ?? '',
            'province': province ?? '',
            'district': district ?? '',
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = _extractError(res.body) ?? 'Registration failed';
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveToken((data['access_token'] ?? '').toString());
    final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};

    // Cache to local profile for UI usage.
    await _profileService.updateProfile(
      fullName: (profile['full_name'] ?? fullName).toString(),
      phone: (profile['phone'] ?? phone ?? '').toString(),
      province: (profile['province'] ?? province ?? '').toString(),
      district: (profile['district'] ?? district ?? '').toString(),
      location: '',
      landSize: (profile['land_size'] is num) ? (profile['land_size'] as num).toDouble() : null,
      soilType: (profile['soil_type'] ?? '').toString(),
    );

    return profile;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/auth/login');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = _extractError(res.body) ?? 'Login failed';
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _saveToken((data['access_token'] ?? '').toString());
    final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};

    await _profileService.updateProfile(
      fullName: (profile['full_name'] ?? 'User').toString(),
      phone: (profile['phone'] ?? '').toString(),
      province: (profile['province'] ?? '').toString(),
      district: (profile['district'] ?? '').toString(),
      location: '',
      landSize: (profile['land_size'] is num) ? (profile['land_size'] as num).toDouble() : null,
      soilType: (profile['soil_type'] ?? '').toString(),
    );

    return profile;
  }

  Future<Map<String, dynamic>?> fetchMe() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    final uri = Uri.parse('${ApiService.baseUrl}/auth/me');
    final res = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['profile'] as Map?)?.cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> updates) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    final uri = Uri.parse('${ApiService.baseUrl}/auth/profile');
    final res = await http
        .put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(updates),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final profile = (data['profile'] as Map?)?.cast<String, dynamic>();
    if (profile != null) {
      await _profileService.updateProfile(
        fullName: (profile['full_name'] ?? 'User').toString(),
        phone: (profile['phone'] ?? '').toString(),
        province: (profile['province'] ?? '').toString(),
        district: (profile['district'] ?? '').toString(),
        location: (profile['location'] ?? '').toString(),
        landSize: (profile['land_size'] is num) ? (profile['land_size'] as num).toDouble() : null,
        soilType: (profile['soil_type'] ?? '').toString(),
      );
    }
    return profile;
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) return decoded['detail'].toString();
    } catch (_) {}
    return null;
  }
}

