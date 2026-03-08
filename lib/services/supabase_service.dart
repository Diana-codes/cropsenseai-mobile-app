import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://raougpdrbrywsrhbczab.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhb3VncGRyYnJ5d3NyaGJjemFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0Nzc4MjYsImV4cCI6MjA4NzA1MzgyNn0.DCaeei89AHywm6FsQHtjOFlgow2ipJw3z5GRpeuQXoQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}
