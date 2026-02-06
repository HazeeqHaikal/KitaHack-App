import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService().registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
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

  Future<void> _registerWithGoogle() async {
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
                const SizedBox(height: 20),
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),

                // App Logo/Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Due to automate your academic timeline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Register Form
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'Enter your name',
                              prefixIcon: Icon(Icons.person_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingM),

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
                              hintText: 'Create a password',
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
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingM),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppConstants.spacingL),

                          // Register Button
                          PrimaryButton(
                            text: 'Sign Up',
                            onPressed: _isLoading ? null : _register,
                            isLoading: _isLoading,
                            icon: Icons.person_add,
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
                            onPressed: _isLoading ? null : _registerWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 32),
                            label: const Text('Sign up with Google'),
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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppConstants.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text('Login'),
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
