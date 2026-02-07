import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration Manager
/// Handles all API keys and configuration from environment variables
class ApiConfig {
  // Gemini API Configuration
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String geminiModel =
      'gemini-2.5-pro'; // Most capable model for document analysis
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com';

  // Google OAuth Configuration
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get googleClientSecret =>
      dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';

  // API Configuration
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 30);
  static const int maxFileSizeMB = 10;

  // Google Calendar API Scopes
  static const List<String> calendarScopes = [
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/calendar.events',
  ];

  // Firebase Storage paths
  static const String syllabusStoragePath = 'syllabi';

  /// Validate that all required API keys are configured
  static bool validateConfig() {
    if (geminiApiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not configured in .env file');
    }
    return true;
  }

  /// Check if configuration is ready for production
  static bool isConfigured() {
    return geminiApiKey.isNotEmpty;
  }
}
