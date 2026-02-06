import 'package:flutter/material.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/utils/date_formatter.dart';
import 'package:due/widgets/glass_container.dart';

/// Widget to display an academic event card using Glassmorphism
class EventCard extends StatelessWidget {
  final AcademicEvent event;
  final bool showCheckbox;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.showCheckbox = false,
    this.onSelectionChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getEventColor(event.type);
    final priorityColor = _getPriorityColor(event.priority);

    // Dynamic border color based on status
    Color? borderColor;
    if (event.isOverdue) {
      borderColor = AppConstants.errorColor.withOpacity(0.6);
    } else if (event.isComingSoon) {
      borderColor = AppConstants.warningColor.withOpacity(0.6);
    } else {
      borderColor = AppConstants.glassBorder;
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      borderColor: borderColor,
      onTap: onTap,
      // Add a slight glowing shadow if high priority or urgent
      hasShadow: event.priority == EventPriority.high || event.isComingSoon,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheckbox)
            Theme(
              data: ThemeData(
                unselectedWidgetColor: AppConstants.textSecondary,
              ),
              child: Checkbox(
                value: event.isSelected,
                onChanged: onSelectionChanged,
                activeColor: AppConstants.primaryColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

          // Left color indicator (Glow strip)
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),

          // Event content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and type badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTypeBadge(context, event.type, color),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),

                // Date and countdown
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppConstants.textSecondary,
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(
                      DateFormatter.formatDate(event.dueDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingS,
                        vertical: AppConstants.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: event.isOverdue
                            ? AppConstants.errorColor.withOpacity(0.2)
                            : event.isComingSoon
                            ? AppConstants.warningColor.withOpacity(0.2)
                            : AppConstants.glassSurface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusS,
                        ),
                        border: Border.all(
                          color: event.isOverdue
                              ? AppConstants.errorColor.withOpacity(0.4)
                              : event.isComingSoon
                              ? AppConstants.warningColor.withOpacity(0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        DateFormatter.getCountdown(event.dueDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: event.isOverdue
                              ? AppConstants.errorColor
                              : event.isComingSoon
                              ? AppConstants.warningColor
                              : AppConstants.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Weightage and priority
                if (event.weightage != null) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 14,
                        color: priorityColor,
                      ),
                      const SizedBox(width: AppConstants.spacingXS),
                      Text(
                        'Weight: ${event.weightage}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusS,
                          ),
                          border: Border.all(
                            color: priorityColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          event.priority.name.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, EventType type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Text(
        type.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.assignment:
        return AppConstants.eventTypeColors['assignment']!;
      case EventType.exam:
        return AppConstants.eventTypeColors['exam']!;
      case EventType.quiz:
        return AppConstants.eventTypeColors['quiz']!;
      case EventType.project:
        return AppConstants.eventTypeColors['project']!;
      case EventType.presentation:
        return AppConstants.eventTypeColors['presentation']!;
      case EventType.lab:
        return AppConstants.eventTypeColors['lab']!;
      default:
        return AppConstants.eventTypeColors['other']!;
    }
  }

  Color _getPriorityColor(EventPriority priority) {
    switch (priority) {
      case EventPriority.high:
        return AppConstants.priorityColors['high']!;
      case EventPriority.medium:
        return AppConstants.priorityColors['medium']!;
      case EventPriority.low:
        return AppConstants.priorityColors['low']!;
    }
  }
}
