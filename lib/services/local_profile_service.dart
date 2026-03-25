import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalProfileService {
  static const _key = 'cropsense_local_profile_v1';

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return {
        'full_name': 'Guest',
        'phone': '',
        'location': '',
        'province': '',
        'district': '',
        'sector': '',
        'cell': '',
        'village': '',
        'land_size': null,
        'soil_type': '',
      };
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? location,
    String? province,
    String? district,
    String? sector,
    String? cell,
    String? village,
    double? landSize,
    String? soilType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getProfile();

    current['full_name'] = fullName;
    current['phone'] = phone ?? current['phone'] ?? '';
    current['location'] = location ?? current['location'] ?? '';
    current['province'] = province ?? current['province'] ?? '';
    current['district'] = district ?? current['district'] ?? '';
    current['sector'] = sector ?? current['sector'] ?? '';
    current['cell'] = cell ?? current['cell'] ?? '';
    current['village'] = village ?? current['village'] ?? '';
    current['land_size'] = landSize;
    current['soil_type'] = soilType ?? current['soil_type'] ?? '';

    await prefs.setString(_key, jsonEncode(current));
  }
}

