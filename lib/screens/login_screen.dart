import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/services/firebase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final firebaseService = FirebaseService();

      // Check if auth is available
      if (!firebaseService.isAuthAvailable) {
        throw Exception(
          'Authentication service is not ready. Please restart the app.',
        );
      }

      await firebaseService.signInWithGoogle();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Sign-in failed';
        bool showRetry = false;

        if (e.toString().contains('canceled')) {
          errorMessage = 'Sign-in was canceled';
        } else if (e.toString().contains('not initialized') ||
            e.toString().contains('not ready')) {
          errorMessage = 'App is still starting. Please wait and try again.';
          showRetry = true;
        } else if (e.toString().contains('network') ||
            e.toString().contains('internet') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection.';
          showRetry = true;
        } else if (e.toString().contains('api-not-enabled')) {
          errorMessage =
              'Google Sign-In is not properly configured. Please contact support.';
        } else {
          errorMessage = e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('Error: ', '');
          // Show retry for most errors
          showRetry = !e.toString().contains('canceled');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 5),
            action: showRetry
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: _loginWithGoogle,
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo/Icon
                  const Icon(
                    Icons.calendar_today,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // App Title
                  Text(
                    'DUE',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Academic Timeline, Automated',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConstants.textSecondary,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  // Login Container
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppConstants.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            'Sign in with your Google account to continue',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppConstants.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.spacingXL),

                          // Google Sign In Button
                          if (_isLoading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppConstants.primaryColor,
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _loginWithGoogle,
                              icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                              label: const Text(
                                'Continue with Google',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadiusM,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: AppConstants.spacingM),

                          // Info text
                          Text(
                            'Google Calendar access will be requested to sync your academic events',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppConstants.textSecondary,
                                  fontSize: 12,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
