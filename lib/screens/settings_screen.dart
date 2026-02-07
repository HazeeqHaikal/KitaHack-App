import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebaseService = FirebaseService();

  String get _userEmail {
    final user = _firebaseService.currentUser;
    if (user?.email != null) {
      return user!.email!;
    }
    return 'Not signed in';
  }

  bool get _isSignedIn => _firebaseService.isSignedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.backgroundStart, AppConstants.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            children: [
              if (_isSignedIn) ...[
                _buildSectionTitle('Account'),
                _buildSettingItem(
                  context,
                  icon: Icons.account_circle,
                  title: 'Account',
                  subtitle: _userEmail,
                  onTap: null,
                ),
                const SizedBox(height: AppConstants.spacingL),
              ],
              _buildSectionTitle('About'),
              _buildSettingItem(
                context,
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0 (Beta)',
                onTap: null,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              if (_isSignedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.errorColor.withOpacity(0.2),
                      foregroundColor: AppConstants.errorColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.spacingM,
                        horizontal: AppConstants.spacingL,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: AppConstants.errorColor,
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingS,
        bottom: AppConstants.spacingS,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppConstants.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: GlassContainer(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  color: AppConstants.textSecondary,
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundEnd,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              if (!context.mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                ),
              );

              try {
                // Sign out using Firebase service
                await _firebaseService.signOut();

                // Navigate to onboarding
                if (!context.mounted) return;
                Navigator.pop(context); // Dismiss loading
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/onboarding',
                  (route) => false,
                );
              } catch (e) {
                // Dismiss loading
                if (!context.mounted) return;
                Navigator.pop(context);

                // Show error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sign out failed: $e'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
