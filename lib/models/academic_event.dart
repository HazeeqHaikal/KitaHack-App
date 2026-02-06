/// Model representing an academic event extracted from a syllabus
class AcademicEvent {
  final String id;
  final String title;
  final DateTime dueDate;
  final String description;
  final String? weightage;
  final EventType type;
  final String? location;
  bool isSelected;

  AcademicEvent({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.description,
    this.weightage,
    required this.type,
    this.location,
    this.isSelected = true,
  });

  /// Create from JSON (for Gemini API response parsing)
  factory AcademicEvent.fromJson(Map<String, dynamic> json) {
    return AcademicEvent(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Event',
      dueDate: DateTime.parse(json['dueDate']),
      description: json['description'] ?? '',
      weightage: json['weightage'],
      type: _parseEventType(json['type']),
      location: json['location'],
      isSelected: json['isSelected'] ?? true,
    );
  }

  /// Convert to JSON (for Google Calendar API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'description': description,
      'weightage': weightage,
      'type': type.toString().split('.').last,
      'location': location,
      'isSelected': isSelected,
    };
  }

  /// Helper to parse event type from string
  static EventType _parseEventType(String? type) {
    switch (type?.toLowerCase()) {
      case 'assignment':
        return EventType.assignment;
      case 'exam':
      case 'midterm':
      case 'final':
        return EventType.exam;
      case 'quiz':
        return EventType.quiz;
      case 'project':
        return EventType.project;
      case 'presentation':
        return EventType.presentation;
      case 'lab':
        return EventType.lab;
      default:
        return EventType.other;
    }
  }

  /// Get priority level based on weightage
  EventPriority get priority {
    if (weightage == null) return EventPriority.medium;

    final weight = double.tryParse(weightage!.replaceAll('%', '')) ?? 0;
    if (weight >= 40) return EventPriority.high;
    if (weight >= 20) return EventPriority.medium;
    return EventPriority.low;
  }

  /// Get days until due date
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  /// Check if event is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate);
  }

  /// Check if event is coming soon (within 7 days)
  bool get isComingSoon {
    return daysUntilDue <= 7 && daysUntilDue >= 0;
  }
}

/// Enum for different types of academic events
enum EventType { assignment, exam, quiz, project, presentation, lab, other }

/// Enum for event priority levels
enum EventPriority { low, medium, high }

/// Extension to get display names for event types
extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.assignment:
        return 'Assignment';
      case EventType.exam:
        return 'Exam';
      case EventType.quiz:
        return 'Quiz';
      case EventType.project:
        return 'Project';
      case EventType.presentation:
        return 'Presentation';
      case EventType.lab:
        return 'Lab';
      case EventType.other:
        return 'Other';
    }
  }
}
