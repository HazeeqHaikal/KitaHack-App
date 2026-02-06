import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              _buildSectionTitle('Account'),
              _buildSettingItem(
                context,
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Manage your profile information',
                onTap: () {
                  _showComingSoon(context, 'Profile management');
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.account_circle,
                title: 'Google Account',
                subtitle: 'Connected to student@university.edu',
                onTap: () {
                  _showComingSoon(context, 'Google account management');
                },
              ),
              const SizedBox(height: AppConstants.spacingL),
              _buildSectionTitle('Calendar'),
              _buildSettingItem(
                context,
                icon: Icons.calendar_today,
                title: 'Default Calendar',
                subtitle: 'Personal',
                onTap: () {
                  _showComingSoon(context, 'Calendar selection');
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: 'Reminders',
                subtitle: '1 day before due date',
                onTap: () {
                  _showComingSoon(context, 'Reminder settings');
                },
              ),
              const SizedBox(height: AppConstants.spacingL),
              _buildSectionTitle('Preferences'),
              _buildSettingItem(
                context,
                icon: Icons.dark_mode,
                title: 'Theme',
                subtitle: 'Dark mode',
                onTap: () {
                  _showComingSoon(context, 'Theme selection');
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  _showComingSoon(context, 'Language selection');
                },
              ),
              const SizedBox(height: AppConstants.spacingL),
              _buildSectionTitle('Data'),
              _buildSettingItem(
                context,
                icon: Icons.sync,
                title: 'Sync Status',
                subtitle: 'All courses synced',
                onTap: () {
                  _showComingSoon(context, 'Sync management');
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.storage,
                title: 'Storage',
                subtitle: '4 syllabi uploaded',
                onTap: () {
                  _showComingSoon(context, 'Storage management');
                },
              ),
              const SizedBox(height: AppConstants.spacingL),
              _buildSectionTitle('About'),
              _buildSettingItem(
                context,
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0 (Beta)',
                onTap: () {},
              ),
              _buildSettingItem(
                context,
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () {
                  _showComingSoon(context, 'Privacy policy');
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.description,
                title: 'Terms of Service',
                subtitle: 'View terms and conditions',
                onTap: () {
                  _showComingSoon(context, 'Terms of service');
                },
              ),
              const SizedBox(height: AppConstants.spacingXL),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                ),
                child: TextButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: AppConstants.errorColor,
                  ),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppConstants.errorColor,
                      fontWeight: FontWeight.w600,
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        backgroundColor: AppConstants.warningColor,
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/onboarding',
                (route) => false,
              );
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
