import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/bottom_nav_bar.dart';
import 'package:due/services/firebase_service.dart';
import 'package:due/services/storage_service.dart';
import 'package:due/services/calendar_service.dart';
import 'package:due/services/usage_tracking_service.dart';
import 'package:due/services/response_cache_service.dart';
import 'package:due/config/api_config.dart';
import 'package:due/providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  final _firebaseService = FirebaseService();
  final _calendarService = CalendarService();

  Map<String, dynamic>? _usageSummary;
  bool _isLoadingUsage = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    if (!ApiConfig.enableUsageTracking) {
      setState(() => _isLoadingUsage = false);
      return;
    }

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final usageTracking = UsageTrackingService.withPrefs(prefs);
      final summary = await usageTracking.getUsageSummary();
      setState(() {
        _usageSummary = summary;
        _isLoadingUsage = false;
      });
    } catch (e) {
      print('Error loading usage stats: $e');
      setState(() => _isLoadingUsage = false);
    }
  }

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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

              // API Usage Section
              _buildSectionTitle('API Usage & Development'),
              if (ApiConfig.devMode)
                Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
                  child: GlassContainer(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.science,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        '🧪 Development Mode',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Using mock data - no API charges',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_isLoadingUsage && _usageSummary != null)
                ..._buildUsageStats(),
              if (_isLoadingUsage)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.spacingL),
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              _buildSettingItem(
                context,
                icon: Icons.cleaning_services,
                title: 'Clear Response Cache',
                subtitle: 'Remove cached API responses to save space',
                onTap: () => _showClearCacheDialog(context),
              ),
              _buildSettingItem(
                context,
                icon: Icons.refresh,
                title: 'Reset Usage Statistics',
                subtitle: 'Clear API usage tracking data',
                onTap: () => _showResetUsageDialog(context),
              ),
              const SizedBox(height: AppConstants.spacingL),

              if (_isSignedIn) ...[
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
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
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
                final storageService = ref.read(storageServiceProvider);
                await storageService.clearAllCourses();

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

  List<Widget> _buildUsageStats() {
    if (_usageSummary == null) return [];

    final totalCost = _usageSummary!['totalCost'] as double;
    final todayCost = _usageSummary!['todayCost'] as double;
    final weekCost = _usageSummary!['weekCost'] as double;
    final totalCalls = _usageSummary!['totalCalls'] as int;
    final todayCalls = _usageSummary!['todayCalls'] as int;
    final syllabusCount = _usageSummary!['syllabusCount'] as int;
    final effortCount = _usageSummary!['effortCount'] as int;

    final costColor = _getCostColor(totalCost);
    final costEmoji = _getCostEmoji(totalCost);

    return [
      Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Cost',
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$costEmoji RM ${totalCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: costColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCostStat('Today', todayCost, todayCalls),
                    _buildCostStat('This Week', weekCost, null),
                    _buildCostStat('All Time', totalCost, totalCalls),
                  ],
                ),
                const Divider(
                  color: AppConstants.textSecondary,
                  height: AppConstants.spacingL,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCallTypeStat(
                      'Syllabus Analysis',
                      syllabusCount,
                      Icons.description,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppConstants.textSecondary,
                    ),
                    _buildCallTypeStat(
                      'Effort Estimates',
                      effortCount,
                      Icons.timer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildCostStat(String label, double cost, int? calls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RM ${cost.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (calls != null)
          Text(
            '$calls ${calls == 1 ? 'call' : 'calls'}',
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildCallTypeStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getCostColor(double cost) {
    if (cost < 1.0) return AppConstants.successColor;
    if (cost < 5.0) return Colors.orange;
    return AppConstants.errorColor;
  }

  String _getCostEmoji(double cost) {
    if (cost < 1.0) return '✅';
    if (cost < 5.0) return '⚠️';
    return '🚨';
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundEnd,
        title: const Text(
          'Clear Response Cache?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all cached API responses. You may see more API usage as repeated uploads will require new API calls.',
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
              try {
                final prefs = ref.read(sharedPreferencesProvider);
                final responseCache = ResponseCacheService.withPrefs(prefs);
                await responseCache.clearCache();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Response cache cleared'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to clear cache: $e'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Clear Cache',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetUsageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundEnd,
        title: const Text(
          'Reset Usage Statistics?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will clear all API usage tracking data. Your cost history will be permanently deleted.',
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
              try {
                final prefs = ref.read(sharedPreferencesProvider);
                final usageTracking = UsageTrackingService.withPrefs(prefs);
                await usageTracking.resetTracking();
                await _loadUsageStats();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Usage statistics reset'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reset usage: $e'),
                    backgroundColor: AppConstants.errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
