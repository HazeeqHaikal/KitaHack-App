import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class SmartNotificationsScreen extends StatefulWidget {
  const SmartNotificationsScreen({super.key});

  @override
  State<SmartNotificationsScreen> createState() =>
      _SmartNotificationsScreenState();
}

class _SmartNotificationsScreenState extends State<SmartNotificationsScreen> {
  bool _notificationsEnabled = true;
  bool _smartReminders = true;
  bool _progressUpdates = false;
  bool _motivationalMessages = true;
  String _reminderTiming = 'adaptive'; // adaptive, fixed, custom

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Smart Notifications'),
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
              // Mock Feature Banner
              GlassContainer(
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.construction,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🚧 Mock Feature (Phase 3)',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'UI complete - backend implementation pending',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Enable Notifications
              _buildSectionTitle('General'),
              _buildSwitchTile(
                title: 'Enable Notifications',
                subtitle: 'Receive reminders and updates',
                value: _notificationsEnabled,
                icon: Icons.notifications_active,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Smart Features
              _buildSectionTitle('Smart Features'),
              _buildSwitchTile(
                title: 'Adaptive Reminders',
                subtitle: 'AI adjusts reminder timing based on priority',
                value: _smartReminders,
                icon: Icons.psychology,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _smartReminders = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildSwitchTile(
                title: 'Progress Updates',
                subtitle: 'Get notified when tasks are completed',
                value: _progressUpdates,
                icon: Icons.trending_up,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _progressUpdates = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildSwitchTile(
                title: 'Motivational Messages',
                subtitle: 'Encouraging messages to keep you on track',
                value: _motivationalMessages,
                icon: Icons.emoji_emotions,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _motivationalMessages = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Reminder Timing
              _buildSectionTitle('Reminder Timing'),
              GlassContainer(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'Adaptive (Recommended)',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'AI decides best time based on event priority',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: 'adaptive',
                      groupValue: _reminderTiming,
                      activeColor: AppConstants.primaryColor,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _reminderTiming = value!;
                              });
                            }
                          : null,
                    ),
                    const Divider(color: AppConstants.textSecondary, height: 1),
                    RadioListTile<String>(
                      title: const Text(
                        'Fixed Schedule',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        '1 day, 3 days, 1 week before deadline',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: 'fixed',
                      groupValue: _reminderTiming,
                      activeColor: AppConstants.primaryColor,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _reminderTiming = value!;
                              });
                            }
                          : null,
                    ),
                    const Divider(color: AppConstants.textSecondary, height: 1),
                    RadioListTile<String>(
                      title: const Text(
                        'Custom',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Set your own reminder schedule',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: 'custom',
                      groupValue: _reminderTiming,
                      activeColor: AppConstants.primaryColor,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _reminderTiming = value!;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Example Notifications
              _buildSectionTitle('Example Notifications'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildExampleNotif(
                        icon: Icons.priority_high,
                        color: AppConstants.errorColor,
                        title: 'High Priority Reminder',
                        body: 'Final Exam in 3 days (40% of grade)',
                        time: '3 days before',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildExampleNotif(
                        icon: Icons.assignment_turned_in,
                        color: AppConstants.successColor,
                        title: 'Task Completed! 🎉',
                        body: 'You finished Assignment 2 ahead of schedule',
                        time: 'On completion',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildExampleNotif(
                        icon: Icons.psychology,
                        color: AppConstants.accentColor,
                        title: 'Study Session Reminder',
                        body: 'Time to study for Thermodynamics Quiz',
                        time: '1 hour before',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildExampleNotif(
                        icon: Icons.emoji_emotions,
                        color: Colors.amber,
                        title: 'Keep Going! 💪',
                        body: 'You\'re on track with 85% of tasks completed',
                        time: 'Weekly summary',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Test Notification Button
              ElevatedButton.icon(
                onPressed: _notificationsEnabled ? _sendTestNotification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.send),
                label: const Text(
                  'Send Test Notification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool)? onChanged,
  }) {
    return GlassContainer(
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: onChanged != null
                ? Colors.white
                : AppConstants.textSecondary,
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
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                (onChanged != null
                        ? AppConstants.primaryColor
                        : AppConstants.textSecondary)
                    .withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: onChanged != null
                ? AppConstants.primaryColor
                : AppConstants.textSecondary,
            size: 20,
          ),
        ),
        value: value,
        activeColor: AppConstants.primaryColor,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildExampleNotif({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 Test notification sent! (Mock)'),
        backgroundColor: AppConstants.successColor,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
