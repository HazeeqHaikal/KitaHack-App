import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Due';
  static const String appTagline = 'Your Academic Timeline, Automated';
  static const String appVersion = '1.0.0';

  // --- Night Owl + Glass OS Palette ---

  // Backgrounds (Deep, rich darks for contrast with glass)
  static const Color backgroundStart = Color(0xFF0F172A); // Deep Slate Blue
  static const Color backgroundEnd = Color(0xFF020617); // Almost Black

  // Primary Accents (Bright, Neon-like for visibility on dark)
  static const Color primaryColor = Color(0xFF3B82F6); // Electric Blue
  static const Color secondaryColor = Color(0xFF8B5CF6); // Electric Violet
  static const Color accentColor = Color(0xFFF43F5E); // Neon Rose

  // Glass Surface Colors (White with very low opacity)
  static const Color glassSurface = Color(0x1FFFFFFF); // 12% White
  static const Color glassBorder = Color(
    0x33FFFFFF,
  ); // 20% White (for thin borders)
  static const Color textPrimary = Color(0xFFF1F5F9); // Off-white for reading
  static const Color textSecondary = Color(0xFF94A3B8); // Muted grey

  // Status Colors (Slightly desaturated to not be blinding in dark mode)
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Event Type Colors (Bright/Neon variants)
  static const Map<String, Color> eventTypeColors = {
    'assignment': Color(0xFF60A5FA), // Light Blue
    'exam': Color(0xFFF87171), // Soft Red
    'quiz': Color(0xFFC084FC), // Purple
    'project': Color(0xFF34D399), // Emerald
    'presentation': Color(0xFFFBBF24), // Amber
    'lab': Color(0xFF22D3EE), // Cyan
    'other': Color(0xFF9CA3AF), // Grey
  };

  // Priority Colors
  static const Map<String, Color> priorityColors = {
    'high': Color(0xFFEF4444), // Red
    'medium': Color(0xFFF59E0B), // Amber
    'low': Color(0xFF10B981), // Emerald
  };

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Border Radius (Slightly larger for that modern iOS feel)
  static const double borderRadiusS = 12.0;
  static const double borderRadiusM = 16.0;
  static const double borderRadiusL = 24.0;

  // Animation Durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // File Upload
  static const List<String> supportedFileTypes = ['pdf', 'jpg', 'jpeg', 'png'];
  static const int maxFileSizeMB = 10;

  // Sample Data
  static const List<String> onboardingTitles = [
    'Welcome to Due',
    'Upload Your Syllabus',
    'AI-Powered Extraction',
    'Sync to Calendar',
  ];

  static const List<String> onboardingDescriptions = [
    'Your intelligent academic scheduling assistant that helps you stay on top of deadlines',
    'Simply upload your course outline as a PDF or image file',
    'Our AI automatically extracts assignments, exams, and important dates',
    'Review and sync events directly to your Google Calendar with one tap',
  ];

  static const List<IconData> onboardingIcons = [
    Icons.school,
    Icons.upload_file,
    Icons.auto_awesome,
    Icons.event_available,
  ];
}
