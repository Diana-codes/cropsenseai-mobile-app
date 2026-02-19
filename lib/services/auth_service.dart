import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService().client;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? district,
    String? province,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'district': district,
        'province': province,
      },
    );

    if (response.user != null) {
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
        'phone': phone ?? '',
        'district': district ?? '',
        'province': province ?? '',
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();

    return response;
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? location,
    String? district,
    String? province,
    double? landSize,
    String? soilType,
  }) async {
    if (currentUser == null) return;

    await _supabase.from('profiles').update({
      'full_name': fullName,
      'phone': phone,
      'location': location,
      'district': district,
      'province': province,
      'land_size': landSize,
      'soil_type': soilType,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', currentUser!.id);
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
