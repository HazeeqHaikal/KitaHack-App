import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/services/firebase_service.dart';
import 'package:due/services/storage_service.dart';
import 'package:due/services/calendar_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebaseService = FirebaseService();
  final _storageService = StorageService();
  final _calendarService = CalendarService();

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
                _buildSectionTitle('Data Management'),
                _buildSettingItem(
                  context,
                  icon: Icons.delete_sweep,
                  title: 'Clear All Courses',
                  subtitle: 'Remove all saved courses from this device',
                  onTap: () => _showClearDataDialog(context),
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.event_busy,
                  title: 'Clean Up Calendar',
                  subtitle: 'Delete old Due events from Google Calendar',
                  onTap: () => _showCleanupCalendarDialog(context),
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

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundEnd,
        title: const Text(
          'Clear All Courses?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all saved courses and events from this device. This action cannot be undone.',
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
                await _storageService.clearAllCourses();

                if (!context.mounted) return;
                Navigator.pop(context); // Dismiss loading

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ All courses cleared successfully'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );

                // Go back to home
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Dismiss loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to clear data: $e'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showCleanupCalendarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundEnd,
        title: const Text(
          'Clean Up Google Calendar?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will search for and delete all events created by Due from your Google Calendar (including old untracked events). This is useful for cleaning up events uploaded before the storage fix.',
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

              // Check if authenticated
              if (!_calendarService.isAuthenticated) {
                try {
                  await _calendarService.signIn();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign in: $e'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                  return;
                }
              }

              // Show loading indicator
              if (!context.mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Searching for Due events...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );

              try {
                // Get user's calendars and use primary
                final calendars = await _calendarService.getCalendars();
                final primaryCalendar = calendars.firstWhere(
                  (cal) => cal.primary == true,
                  orElse: () => calendars.first,
                );

                final deleteCount = await _calendarService.deleteAllDueEvents(
                  primaryCalendar.id!,
                );

                if (!context.mounted) return;
                Navigator.pop(context); // Dismiss loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Deleted $deleteCount events from Google Calendar',
                    ),
                    backgroundColor: AppConstants.successColor,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Dismiss loading

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to clean up calendar: $e'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Clean Up',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
