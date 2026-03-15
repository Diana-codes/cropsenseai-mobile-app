import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://tqpbxdwyebsfieztewyb.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxcGJ4ZHd5ZWJzZmllenRld3liIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0ODY1ODUsImV4cCI6MjA4OTA2MjU4NX0.UeXRWGRc_-Ed6DMsCd5m1vcl2kikm32hVvUHDLH31xw';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}
