/// Model representing a subtask within an academic event
class Task {
  final String id;
  final String title;
  final String duration;
  final String? description;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.duration,
    this.description,
    this.isCompleted = false,
  });

  /// Create from JSON (for Gemini API response parsing)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Task',
      duration: json['duration'] ?? 'Unknown',
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  /// Convert to JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  /// Create a copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? duration,
    String? description,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
