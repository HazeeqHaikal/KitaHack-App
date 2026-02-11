import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:due/screens/onboarding_screen.dart';
import 'package:due/screens/login_screen.dart';
import 'package:due/screens/home_screen.dart';
import 'package:due/screens/upload_screen.dart';
import 'package:due/screens/result_screen.dart';
import 'package:due/screens/calendar_sync_screen.dart';
import 'package:due/screens/calendar_view_screen.dart';
import 'package:due/screens/course_list_screen.dart';
import 'package:due/screens/settings_screen.dart';
import 'package:due/screens/event_detail_screen.dart';
import 'package:due/screens/task_breakdown_screen.dart';
import 'package:due/screens/study_allocator_screen.dart';
import 'package:due/screens/resource_finder_screen.dart';
import 'package:due/screens/group_sync_screen.dart';
import 'package:due/screens/smart_notifications_screen.dart';
import 'package:due/screens/analytics_dashboard_screen.dart';
import 'package:due/screens/personalized_study_screen.dart';
import 'package:due/screens/progress_tracking_screen.dart';
import 'package:due/screens/adaptive_learning_screen.dart';
import 'package:due/utils/constants.dart';
import 'package:due/utils/route_transitions.dart';
import 'package:due/services/firebase_service.dart';
import 'package:due/services/calendar_service.dart';
import 'package:due/providers/app_providers.dart';
import 'package:due/widgets/auth_state_wrapper.dart';

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

  // Initialize SharedPreferences once - cached for entire app lifecycle
  final prefs = await SharedPreferences.getInstance();
  print('SharedPreferences initialized and cached');

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

  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with the cached instance
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DueApp(),
    ),
  );
}

class DueApp extends StatelessWidget {
  const DueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Due - Your Academic Timeline, Automated',
      debugShowCheckedModeBanner: false,
      // Enable performance overlay in debug mode (can be toggled)
      // showPerformanceOverlay: false,
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
        // Enable smooth animations
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
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
      // Use onGenerateRoute for custom page transitions
      onGenerateRoute: (settings) {
        // Get the page widget based on route name
        Widget page;
        switch (settings.name) {
          case '/onboarding':
            page = const OnboardingScreen();
            break;
          case '/login':
            page = const LoginScreen();
            break;
          case '/':
          case '/home':
            page = const AuthStateWrapper(child: HomeScreen());
            break;
          case '/upload':
            page = const UploadScreen();
            break;
          case '/courses':
            page = const CourseListScreen();
            break;
          case '/result':
            page = const ResultScreen();
            break;
          case '/calendar':
            page = const CalendarViewScreen();
            break;
          case '/calendar-sync':
            page = const CalendarSyncScreen();
            break;
          case '/settings':
            page = const SettingsScreen();
            break;
          case '/event-detail':
            page = const EventDetailScreen();
            break;
          case '/task-breakdown':
            page = const TaskBreakdownScreen();
            break;
          case '/study-allocator':
            page = const StudyAllocatorScreen();
            break;
          case '/resource-finder':
            page = const ResourceFinderScreen();
            break;
          case '/group-sync':
            page = const GroupSyncScreen();
            break;
          case '/smart-notifications':
            page = const SmartNotificationsScreen();
            break;
          case '/analytics-dashboard':
            page = const AnalyticsDashboardScreen();
            break;
          case '/personalized-study':
            page = const PersonalizedStudyScreen();
            break;
          case '/progress-tracking':
            page = const ProgressTrackingScreen();
            break;
          case '/adaptive-learning':
            page = const AdaptiveLearningScreen();
            break;
          default:
            page = const AuthStateWrapper(child: HomeScreen());
        }

        // Return custom fade transition for all routes
        return RouteTransitions.fadeTransition(page: page, settings: settings);
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
  bool _isInitializing = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAndRoute();
  }

  Future<void> _initializeAndRoute() async {
    try {
      // Ensure Firebase is initialized before checking auth state
      final firebaseService = FirebaseService();

      setState(() {
        _statusMessage = 'Checking authentication...';
      });

      // Wait a bit longer for Firebase to fully initialize (especially on first launch)
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

      if (isFirstLaunch) {
        // First time opening the app - show onboarding
        await prefs.setBool('isFirstLaunch', false);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // Check if user is already signed in (Firebase persists auth state)
        final isSignedIn = firebaseService.isSignedIn;

        if (!mounted) return;

        setState(() {
          _statusMessage = isSignedIn ? 'Welcome back!' : 'Loading...';
        });

        // Small delay for smooth UX
        await Future.delayed(const Duration(milliseconds: 300));

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
      print('Error during initialization: $e');
      // Fallback to login on error
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 80,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'DUE',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              if (_isInitializing)
                const CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
