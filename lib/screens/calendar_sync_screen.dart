import 'package:flutter/material.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/info_banner.dart';
import 'package:due/widgets/glass_container.dart';

class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  String _selectedCalendar = 'primary';
  bool _addReminders = true;
  int _reminderDays = 1;
  bool _isSyncing = false;
  bool _isAuthenticated = false;

  // Sample calendars (will be fetched from Google Calendar API)
  final List<Map<String, dynamic>> _calendars = [
    {
      'id': 'primary',
      'name': 'Personal',
      'color': Colors.blue,
      'icon': Icons.person,
    },
    {
      'id': 'school',
      'name': 'School',
      'color': Colors.green,
      'icon': Icons.school,
    },
    {'id': 'work', 'name': 'Work', 'color': Colors.orange, 'icon': Icons.work},
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() {
    // TODO: Check if user is authenticated with Google
    // For now, simulate authentication check
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAuthenticated =
            false; // Change to true when Google Sign-In is implemented
      });
    });
  }

  void _signInWithGoogle() async {
    // TODO: Implement Google Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In will be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );

    // Simulate sign-in
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _syncEvents() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final events = args?['events'] as List<AcademicEvent>?;

    if (events == null || events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No events to sync'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    // TODO: Implement actual Google Calendar API sync
    // Simulate sync process
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });

      // Show success dialog
      _showSuccessDialog(events.length);
    }
  }

  void _showSuccessDialog(int eventCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundStart,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          side: const BorderSide(color: AppConstants.glassBorder),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.successColor.withOpacity(0.2),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: AppConstants.successColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Success!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              '$eventCount events have been synced to your Google Calendar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppConstants.spacingL),
            PrimaryButton(
              text: 'Done',
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // Go to home
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final events = args?['events'] as List<AcademicEvent>? ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Calendar Sync'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
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
          child: !_isAuthenticated
              ? _buildAuthenticationView()
              : _buildSyncConfigurationView(events),
        ),
      ),
    );
  }

  Widget _buildAuthenticationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppConstants.spacingXL),
          // Google logo/icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingXL),
              decoration: BoxDecoration(
                color: AppConstants.glassSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppConstants.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 80,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXL),
          Text(
            'Connect Your Calendar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Sign in with Google to sync your academic events to Google Calendar',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppConstants.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXL),
          // Benefits
          _buildBenefitItem(
            icon: Icons.sync,
            title: 'Automatic Sync',
            description: 'Events are instantly added to your calendar',
          ),
          _buildBenefitItem(
            icon: Icons.notifications_active,
            title: 'Smart Reminders',
            description: 'Get notified before important deadlines',
          ),
          _buildBenefitItem(
            icon: Icons.security,
            title: 'Secure & Private',
            description: 'Your data is protected with Google security',
          ),
          const SizedBox(height: AppConstants.spacingXL),
          // Sign in button
          _buildGoogleSignInButton(),
        ],
      ),
    );
  }

  Widget _buildSyncConfigurationView(List<AcademicEvent> events) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          _buildSummaryCard(events),
          const SizedBox(height: AppConstants.spacingL),
          // Info banner
          const InfoBanner(
            message:
                'Configure how events will be synced to your Google Calendar',
          ),
          const SizedBox(height: AppConstants.spacingL),
          // Calendar selection
          _buildCalendarSelection(),
          const SizedBox(height: AppConstants.spacingL),
          // Reminder settings
          _buildReminderSettings(),
          const SizedBox(height: AppConstants.spacingL),
          // Preview section
          _buildPreviewSection(events),
          const SizedBox(height: AppConstants.spacingXL),
          // Sync button
          PrimaryButton(
            text: 'Sync ${events.length} Events',
            icon: Icons.sync,
            onPressed: _isSyncing ? null : _syncEvents,
            isLoading: _isSyncing,
            backgroundColor: AppConstants.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      borderColor: Colors.transparent,
      color: Colors.transparent,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 24),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXS),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _signInWithGoogle,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google icon (placeholder - use actual Google logo in production)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.g_mobiledata,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              const Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87, // Google button is usually light
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<AcademicEvent> events) {
    final highPriority = events
        .where((e) => e.priority == EventPriority.high)
        .length;
    final comingSoon = events.where((e) => e.isComingSoon).length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Events', events.length.toString()),
              _buildSummaryItem('High Priority', highPriority.toString()),
              _buildSummaryItem('Coming Soon', comingSoon.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCalendarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Calendar',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        ..._calendars.map((calendar) => _buildCalendarOption(calendar)),
      ],
    );
  }

  Widget _buildCalendarOption(Map<String, dynamic> calendar) {
    final isSelected = _selectedCalendar == calendar['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: GlassContainer(
        onTap: () {
          setState(() {
            _selectedCalendar = calendar['id'];
          });
        },
        padding: const EdgeInsets.all(AppConstants.spacingM),
        color: isSelected
            ? AppConstants.primaryColor.withOpacity(0.1)
            : AppConstants.glassSurface,
        borderColor: isSelected
            ? AppConstants.primaryColor
            : AppConstants.glassBorder,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: (calendar['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                border: Border.all(
                  color: (calendar['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Icon(calendar['icon'], color: calendar['color'], size: 24),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Text(
                calendar['name'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppConstants.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        GlassContainer(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            title: const Text(
              'Add reminders',
              style: TextStyle(color: AppConstants.textPrimary),
            ),
            subtitle: const Text(
              'Get notified before events',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            value: _addReminders,
            onChanged: (value) {
              setState(() {
                _addReminders = value;
              });
            },
            activeColor: AppConstants.primaryColor,
            secondary: Icon(
              Icons.alarm,
              color: _addReminders
                  ? AppConstants.primaryColor
                  : AppConstants.textSecondary,
            ),
          ),
        ),
        if (_addReminders) ...[
          const SizedBox(height: AppConstants.spacingM),
          Text('Remind me', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppConstants.spacingS),
          Wrap(
            spacing: AppConstants.spacingS,
            children: [1, 2, 3, 7].map((days) {
              final isSelected = _reminderDays == days;
              return FilterChip(
                label: Text('$days ${days == 1 ? 'day' : 'days'} before'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _reminderDays = days;
                  });
                },
                backgroundColor: AppConstants.glassSurface,
                selectedColor: AppConstants.primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppConstants.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : AppConstants.glassBorder,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewSection(List<AcademicEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview (First 3 Events)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        ...events.take(3).map((event) => _buildPreviewEventItem(event)),
      ],
    );
  }

  Widget _buildPreviewEventItem(AcademicEvent event) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          const Icon(Icons.event, color: AppConstants.primaryColor, size: 20),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppConstants.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  event.dueDate.toString().split(' ')[0],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
