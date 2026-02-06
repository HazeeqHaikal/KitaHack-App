import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/services/firebase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService().sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      setState(() => _emailSent = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
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
                const SizedBox(height: 40),

                // Icon
                Icon(
                  _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                  size: 80,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  _emailSent ? 'Check Your Email' : 'Forgot Password?',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  _emailSent
                      ? 'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions.'
                      : 'Don\'t worry! Enter your email address below and we\'ll send you a link to reset your password.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                if (!_emailSent) ...[
                  // Email Form
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            const SizedBox(height: AppConstants.spacingL),

                            // Send Button
                            PrimaryButton(
                              text: 'Send Reset Link',
                              onPressed: _isLoading ? null : _sendResetEmail,
                              isLoading: _isLoading,
                              icon: Icons.send,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Actions after email sent
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        children: [
                          Text(
                            'Didn\'t receive the email?',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppConstants.textSecondary),
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          TextButton(
                            onPressed: () {
                              setState(() => _emailSent = false);
                            },
                            child: const Text('Try Again'),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            'or',
                            style: TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text('Back to Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.spacingL),

                // Back to Login (if not email sent)
                if (!_emailSent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your password? ',
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
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
