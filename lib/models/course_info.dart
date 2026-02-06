import 'package:due/models/academic_event.dart';

/// Model representing course information extracted from syllabus
class CourseInfo {
  final String courseName;
  final String courseCode;
  final String? instructor;
  final String? semester;
  final List<AcademicEvent> events;

  CourseInfo({
    required this.courseName,
    required this.courseCode,
    this.instructor,
    this.semester,
    required this.events,
  });

  /// Create from JSON (for Gemini API response)
  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      courseName: json['courseName'] ?? 'Unknown Course',
      courseCode: json['courseCode'] ?? '',
      instructor: json['instructor'],
      semester: json['semester'],
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => AcademicEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'courseCode': courseCode,
      'instructor': instructor,
      'semester': semester,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  /// Get total number of events
  int get totalEvents => events.length;

  /// Get selected events count
  int get selectedEventsCount =>
      events.where((event) => event.isSelected).length;

  /// Get events by type
  List<AcademicEvent> getEventsByType(EventType type) {
    return events.where((event) => event.type == type).toList();
  }

  /// Get upcoming events (not overdue)
  List<AcademicEvent> get upcomingEvents {
    return events.where((event) => !event.isOverdue).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Get high priority events
  List<AcademicEvent> get highPriorityEvents {
    return events
        .where((event) => event.priority == EventPriority.high)
        .toList();
  }
}
