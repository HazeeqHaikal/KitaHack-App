import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:due/models/course_info.dart';

/// Service for local data persistence using SharedPreferences
/// Stores courses and events data locally
class StorageService {
  static const String _coursesKey = 'saved_courses';

  /// Save a course to local storage
  Future<void> saveCourse(CourseInfo course) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final courses = await getAllCourses();

      // Check if course already exists (by courseCode or courseName)
      final existingIndex = courses.indexWhere(
        (c) =>
            c.courseCode == course.courseCode ||
            (c.courseCode.isEmpty &&
                c.courseName.toLowerCase() == course.courseName.toLowerCase()),
      );

      if (existingIndex != -1) {
        // Update existing course
        courses[existingIndex] = course;
        print('Updated existing course: ${course.courseName}');
      } else {
        // Add new course
        courses.add(course);
        print('Added new course: ${course.courseName}');
      }

      // Convert to JSON and save
      final coursesJson = courses.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_coursesKey, coursesJson);
      print('Successfully saved ${courses.length} courses to storage');
    } catch (e) {
      print('Error saving course: $e');
      rethrow;
    }
  }

  /// Get all saved courses
  Future<List<CourseInfo>> getAllCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coursesJson = prefs.getStringList(_coursesKey) ?? [];

      final courses = coursesJson.map((jsonStr) {
        final Map<String, dynamic> courseMap = json.decode(jsonStr);
        return CourseInfo.fromJson(courseMap);
      }).toList();

      print('Loaded ${courses.length} courses from storage');
      return courses;
    } catch (e) {
      print('Error loading courses: $e');
      return [];
    }
  }

  /// Get a specific course by ID or code
  Future<CourseInfo?> getCourse(String identifier) async {
    try {
      final courses = await getAllCourses();
      return courses.firstWhere(
        (c) => c.courseCode == identifier || c.courseName == identifier,
        orElse: () => throw Exception('Course not found'),
      );
    } catch (e) {
      print('Error getting course: $e');
      return null;
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String courseCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final courses = await getAllCourses();

      courses.removeWhere((c) => c.courseCode == courseCode);

      final coursesJson = courses.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_coursesKey, coursesJson);
      print('Deleted course: $courseCode');
    } catch (e) {
      print('Error deleting course: $e');
      rethrow;
    }
  }

  /// Clear all saved courses
  Future<void> clearAllCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_coursesKey);
      print('Cleared all courses from storage');
    } catch (e) {
      print('Error clearing courses: $e');
      rethrow;
    }
  }

  /// Get all upcoming events from all courses
  Future<List<Map<String, dynamic>>> getUpcomingEvents({int limit = 10}) async {
    try {
      final courses = await getAllCourses();
      final now = DateTime.now();

      // Collect all events with their course info
      final allEvents = <Map<String, dynamic>>[];

      for (final course in courses) {
        for (final event in course.events) {
          if (event.dueDate.isAfter(now)) {
            allEvents.add({
              'event': event,
              'courseName': course.courseName,
              'courseCode': course.courseCode,
            });
          }
        }
      }

      // Sort by due date
      allEvents.sort(
        (a, b) => a['event'].dueDate.compareTo(b['event'].dueDate),
      );

      // Return limited results
      return allEvents.take(limit).toList();
    } catch (e) {
      print('Error getting upcoming events: $e');
      return [];
    }
  }

  /// Get statistics for dashboard
  Future<Map<String, int>> getStatistics() async {
    try {
      final courses = await getAllCourses();
      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));

      int totalEvents = 0;
      int weeklyEvents = 0;
      int highPriorityEvents = 0;

      for (final course in courses) {
        for (final event in course.events) {
          if (event.dueDate.isAfter(now)) {
            totalEvents++;

            if (event.dueDate.isBefore(weekFromNow)) {
              weeklyEvents++;
            }

            if (event.priority.name == 'high') {
              highPriorityEvents++;
            }
          }
        }
      }

      return {
        'totalCourses': courses.length,
        'totalEvents': totalEvents,
        'weeklyEvents': weeklyEvents,
        'highPriorityEvents': highPriorityEvents,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalCourses': 0,
        'totalEvents': 0,
        'weeklyEvents': 0,
        'highPriorityEvents': 0,
      };
    }
  }
}
