import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:due/screens/onboarding_screen.dart';
import 'package:due/screens/login_screen.dart';
import 'package:due/screens/home_screen.dart';
import 'package:due/screens/upload_screen.dart';
import 'package:due/screens/result_screen.dart';
import 'package:due/screens/calendar_sync_screen.dart';
import 'package:due/screens/course_list_screen.dart';
import 'package:due/screens/settings_screen.dart';
import 'package:due/screens/event_detail_screen.dart';
import 'package:due/screens/task_breakdown_screen.dart';
import 'package:due/screens/study_allocator_screen.dart';
import 'package:due/screens/resource_finder_screen.dart';
import 'package:due/utils/constants.dart';
import 'package:due/services/firebase_service.dart';
import 'package:due/services/calendar_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    print(
      'App will continue but API features may not work without configuration',
    );
  }

  // Initialize Firebase (optional - app works without it)
  try {
    await FirebaseService().initialize();
  } catch (e) {
    print('Warning: Firebase initialization failed: $e');
    print('App will continue without Firebase storage');
  }

  // Initialize Calendar Service
  CalendarService().initialize();

  // Ensure status bar is transparent for full immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Light icons for dark bg
      systemNavigationBarColor: AppConstants.backgroundEnd,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DueApp());
}

class DueApp extends StatelessWidget {
  const DueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Due - Your Academic Timeline, Automated',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConstants.backgroundStart,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          surface: AppConstants.glassSurface,
          error: AppConstants.errorColor,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Or preferred font
        // Text Theme Overrides for Dark Mode
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppConstants.textSecondary),
          bodyMedium: TextStyle(color: AppConstants.textSecondary),
          bodySmall: TextStyle(color: AppConstants.textSecondary),
        ),

        // App Bar Theme
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppConstants.textPrimary,
        ),

        // Card Theme (Glass style defaults)
        cardTheme: CardThemeData(
          elevation: 0, // No shadow by default for glass
          color: AppConstants.glassSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            side: const BorderSide(color: AppConstants.glassBorder, width: 1),
          ),
        ),

        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConstants.glassSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            borderSide: const BorderSide(color: AppConstants.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            borderSide: const BorderSide(color: AppConstants.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            borderSide: const BorderSide(color: AppConstants.primaryColor),
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),

        // SnackBar Theme for proper dark mode contrast
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppConstants.glassSurface,
          contentTextStyle: TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppConstants.borderRadiusM),
            ),
          ),
        ),
      ),
      // Start with splash screen that determines initial route
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),
        '/courses': (context) => const CourseListScreen(),
        '/result': (context) => const ResultScreen(),
        '/calendar-sync': (context) => const CalendarSyncScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/event-detail': (context) => const EventDetailScreen(),
        '/task-breakdown': (context) => const TaskBreakdownScreen(),
        '/study-allocator': (context) => const StudyAllocatorScreen(),
        '/resource-finder': (context) => const ResourceFinderScreen(),
      },
    );
  }
}

/// Splash screen that determines initial route based on first launch and auth state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    // Add a small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

      if (isFirstLaunch) {
        // First time opening the app - show onboarding
        await prefs.setBool('isFirstLaunch', false);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // Check if user is already signed in
        final firebaseService = FirebaseService();
        final isSignedIn = firebaseService.isSignedIn;

        if (!mounted) return;

        if (isSignedIn) {
          // User is signed in - go to home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // User not signed in - go to login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error determining initial route: $e');
      // Fallback to onboarding on error
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.backgroundStart, AppConstants.backgroundEnd],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 80,
                color: AppConstants.primaryColor,
              ),
              SizedBox(height: 24),
              Text(
                'DUE',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your Academic Timeline, Automated',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: AppConstants.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
