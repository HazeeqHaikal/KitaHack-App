import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService().signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseService().signInWithGoogle();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseService().signInAnonymously();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to continue as guest: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Logo/Title
                Text(
                  'Due',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Academic Timeline, Automated',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Login Form
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppConstants.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.spacingL),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingM),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingS),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                );
                              },
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingM),

                          // Login Button
                          PrimaryButton(
                            text: 'Login',
                            onPressed: _isLoading ? null : _login,
                            isLoading: _isLoading,
                            icon: Icons.login,
                          ),
                          const SizedBox(height: AppConstants.spacingL),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppConstants.textSecondary.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingM,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppConstants.textSecondary.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingL),

                          // Google Sign In
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 32),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppConstants.glassBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusM,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingM),

                          // Continue as Guest
                          TextButton(
                            onPressed: _isLoading ? null : _continueAsGuest,
                            child: const Text('Continue as Guest'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppConstants.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
