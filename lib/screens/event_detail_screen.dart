import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/utils/date_formatter.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/custom_buttons.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Uint8List? _resourceBytes;
  String? _resourceFileName;
  String? _resourceExtension;

  Future<void> _pickResourceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not read file. Please try again.'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
          return;
        }
        final maxSize = 10 * 1024 * 1024;
        if (file.size > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File too large. Maximum size is 10 MB.'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
          return;
        }
        setState(() {
          _resourceBytes = bytes;
          _resourceFileName = file.name;
          _resourceExtension = file.extension ?? 'pdf';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📄 Resource attached: ${file.name}'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _removeResourceFile() {
    setState(() {
      _resourceBytes = null;
      _resourceFileName = null;
      _resourceExtension = null;
    });
  }

  /// Build the map of arguments passed to each Phase screen.
  /// Includes the event plus optional resource bytes.
  Map<String, dynamic> _phaseArgs(AcademicEvent event) => {
    'event': event,
    'contextBytes': _resourceBytes,
    'contextExtension': _resourceExtension,
    'contextFileName': _resourceFileName,
  };

  static const _skipWarningKey = 'skip_no_resource_warning';

  /// Navigate to a phase screen. If no resource is attached and the user
  /// hasn't dismissed the warning permanently, show a warning dialog first.
  Future<void> _navigateToPhase(
    BuildContext context,
    AcademicEvent event,
    String route,
  ) async {
    if (_resourceBytes != null) {
      // Resource attached — go straight through.
      Navigator.pushNamed(context, route, arguments: _phaseArgs(event));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_skipWarningKey) ?? false;
    if (skip) {
      if (mounted) {
        Navigator.pushNamed(context, route, arguments: _phaseArgs(event));
      }
      return;
    }

    // Show warning dialog.
    if (!mounted) return;
    bool dontShowAgain = false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF1E2340),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'No Resource Attached',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You haven\'t attached an additional resource (e.g. assignment brief, rubric, or notes). '
                'Adding one gives the AI more context and improves all three phases.',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setLocal(() => dontShowAgain = !dontShowAgain),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: dontShowAgain,
                        onChanged: (v) =>
                            setLocal(() => dontShowAgain = v ?? false),
                        activeColor: AppConstants.primaryColor,
                        side: const BorderSide(
                          color: AppConstants.textSecondary,
                          width: 1.5,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Don't show again",
                      style: TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Add Resource',
                style: TextStyle(color: AppConstants.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      ),
    );

    if (proceed == true) {
      if (dontShowAgain) {
        await prefs.setBool(_skipWarningKey, true);
      }
      if (mounted) {
        Navigator.pushNamed(context, route, arguments: _phaseArgs(event));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as AcademicEvent?;

    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit feature - Coming soon!')),
              );
            },
          ),
        ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEventHeader(context, event),
                const SizedBox(height: AppConstants.spacingXL),
                _buildEventInfo(context, event),
                const SizedBox(height: AppConstants.spacingXL),
                _buildResourceSection(context),
                const SizedBox(height: AppConstants.spacingXL),
                _buildSmartFeatures(context, event),
                const SizedBox(height: AppConstants.spacingXL),
                _buildActionButtons(context, event),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader(BuildContext context, AcademicEvent event) {
    final urgencyColor = event.daysUntilDue <= 3
        ? AppConstants.errorColor
        : event.daysUntilDue <= 7
        ? AppConstants.warningColor
        : AppConstants.successColor;

    return GlassContainer(
      hasShadow: true,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEventTypeIcon(event.type),
                      color: _getEventTypeColor(event.type),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.type.displayName,
                      style: TextStyle(
                        color: _getEventTypeColor(event.type),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (event.weightage != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.weightage!,
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Row(
            children: [
              Icon(Icons.calendar_today, color: urgencyColor, size: 16),
              const SizedBox(width: 8),
              Text(
                DateFormatter.formatDate(event.dueDate),
                style: TextStyle(
                  color: urgencyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.daysUntilDue == 0
                      ? 'Due today!'
                      : event.daysUntilDue == 1
                      ? 'Due tomorrow'
                      : '${event.daysUntilDue} days left',
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📎 Additional Resource',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.textSecondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Optional',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GlassContainer(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload a file (assignment brief, lecture notes, rubric…) to make all AI phases more accurate.',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              if (_resourceBytes == null)
                OutlinedButton.icon(
                  onPressed: _pickResourceFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.secondaryColor,
                    side: const BorderSide(color: AppConstants.secondaryColor),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.successColor.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        color: AppConstants.successColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resourceFileName ?? 'Attached file',
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        color: AppConstants.textSecondary,
                        onPressed: _removeResourceFile,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo(BuildContext context, AcademicEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        GlassContainer(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Text(
            event.description,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        if (event.location != null) ...[
          const SizedBox(height: AppConstants.spacingM),
          GlassContainer(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    event.location!,
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmartFeatures(BuildContext context, AcademicEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚀 Smart Features',
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_resourceBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppConstants.secondaryColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Enhanced with your resource',
                  style: TextStyle(
                    color: AppConstants.secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppConstants.spacingM),
        _buildFeatureCard(
          context,
          icon: Icons.checklist,
          title: 'Break Into Tasks',
          subtitle: 'AI-powered task breakdown to beat procrastination',
          color: AppConstants.primaryColor,
          badge: 'Phase 1',
          onTap: () => _navigateToPhase(context, event, '/task-breakdown'),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildFeatureCard(
          context,
          icon: Icons.event_available,
          title: 'Auto-Schedule Study',
          subtitle: 'Find free time & book study sessions automatically',
          color: AppConstants.secondaryColor,
          badge: 'Phase 2',
          onTap: () => _navigateToPhase(context, event, '/study-allocator'),
        ),
        const SizedBox(height: AppConstants.spacingM),
        _buildFeatureCard(
          context,
          icon: Icons.video_library,
          title: 'Find Resources',
          subtitle: 'Get top study videos & materials instantly',
          color: AppConstants.successColor,
          badge: 'Phase 3',
          onTap: () => _navigateToPhase(context, event, '/resource-finder'),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      hasShadow: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppConstants.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AcademicEvent event) {
    final bool isSynced = event.calendarEventId != null;

    return Column(
      children: [
        // Calendar sync button - show different UI based on sync status
        if (isSynced)
          // Already synced - show status button
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingL,
              vertical: AppConstants.spacingM,
            ),
            decoration: BoxDecoration(
              color: AppConstants.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              border: Border.all(
                color: AppConstants.successColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppConstants.successColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingS),
                const Text(
                  'Synced to Calendar',
                  style: TextStyle(
                    color: AppConstants.successColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          // Not synced yet - show add button
          PrimaryButton(
            text: 'Add to Calendar',
            icon: Icons.calendar_today,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/calendar-sync',
                arguments: {
                  'events': [event],
                },
              );
            },
          ),
        const SizedBox(height: AppConstants.spacingM),
        SecondaryButton(
          text: 'Set Reminder',
          icon: Icons.notifications,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder feature - Coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.exam:
        return AppConstants.errorColor;
      case EventType.assignment:
        return AppConstants.primaryColor;
      case EventType.quiz:
        return AppConstants.warningColor;
      case EventType.project:
        return AppConstants.secondaryColor;
      case EventType.presentation:
        return const Color(0xFFFF6B9D);
      case EventType.lab:
        return AppConstants.successColor;
      case EventType.other:
        return AppConstants.textSecondary;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.exam:
        return Icons.school;
      case EventType.assignment:
        return Icons.assignment;
      case EventType.quiz:
        return Icons.quiz;
      case EventType.project:
        return Icons.work;
      case EventType.presentation:
        return Icons.present_to_all;
      case EventType.lab:
        return Icons.science;
      case EventType.other:
        return Icons.event;
    }
  }
}
