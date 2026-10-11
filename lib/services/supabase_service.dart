import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Google OAuth Client IDs loaded securely from environment (.env)
  static String get androidClientId =>
      dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID') ??
      '1059542113241-eq20pbe5jfh601b1m7lmukc3do4nlq5d.apps.googleusercontent.com';

  static String get webClientId =>
      dotenv.maybeGet('GOOGLE_ANDROID_CLIENT_ID') ??
      '1059542113241-94gcrro2ha2j52s8bvi1uc4b9obfcjll.apps.googleusercontent.com';

  // Supabase Project Credentials (public publishable/anon key loaded securely from .env)
  static String get supabaseUrl =>
      dotenv.maybeGet('SUPABASE_URL') ??
      'https://sktroapcocscdtldulwq.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNrdHJvYXBjb2NzY2R0bGR1bHdxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2NTAxMjksImV4cCI6MjEwNjIyNjEyOX0.henewmkM1nmyLavjnwOh3B7aJs5YIWHrwV_3OO6xsx4';

  static SupabaseClient? _client;
  static bool _isConfigured = false;

  static SupabaseClient? get client => _client;
  static bool get isConfigured => _isConfigured;

  /// Initializes Supabase client with public anon key from environment
  static Future<void> initialize() async {
    try {
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: ".env");
      }
    } catch (e) {
      debugPrint("[Supabase] Info loading .env: $e");
    }

    final url = supabaseUrl;
    final anonKey = supabaseAnonKey;

    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _client = Supabase.instance.client;
      _isConfigured = true;
      debugPrint("[Supabase] Initialized client successfully for $url");
    } catch (e) {
      debugPrint("[Supabase] Initialization note: $e");
      try {
        _client = Supabase.instance.client;
        _isConfigured = true;
      } catch (_) {
        _isConfigured = false;
      }
    }
  }

  static User? get currentUser => _client?.auth.currentUser;
  static String get currentUserId => _client?.auth.currentUser?.id ?? 'user_me';
  static Session? get currentSession => _client?.auth.currentSession;
  static bool get isAuthenticated => _client?.auth.currentSession != null;
}
