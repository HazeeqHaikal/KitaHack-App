import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:due/models/course_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:due/services/firebase_service.dart';

/// Helper function for isolate-based JSON parsing (large course lists)
List<CourseInfo> _parseCoursesJson(List<String> coursesJson) {
  return coursesJson.map((jsonStr) {
    final Map<String, dynamic> courseMap = json.decode(jsonStr);
    return CourseInfo.fromJson(courseMap);
  }).toList();
}

/// Service for local and cloud data persistence
/// Stores courses locally (SharedPreferences) and syncs to cloud (Firestore)
class StorageService {
  static const String _coursesKey = 'saved_courses';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final SharedPreferences? _cachedPrefs;

  /// Default constructor - fetches SharedPreferences on demand (legacy)
  StorageService() : _cachedPrefs = null;

  /// Constructor with cached SharedPreferences - eliminates repeated getInstance() calls
  StorageService.withPrefs(SharedPreferences prefs) : _cachedPrefs = prefs;

  /// Get SharedPreferences instance - uses cached if available
  Future<SharedPreferences> _getPrefs() async {
    if (_cachedPrefs != null) {
      return _cachedPrefs!;
    }
    return await SharedPreferences.getInstance();
  }

  /// Save a course to local storage
  Future<void> saveCourse(CourseInfo course) async {
    try {
      final prefs = await _getPrefs();
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

      // Convert to JSON and save locally
      final coursesJson = courses.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_coursesKey, coursesJson);
      print('Successfully saved ${courses.length} courses to local storage');

      // Sync to Firestore if user is signed in
      await _syncCourseToCloud(course);
    } catch (e) {
      print('Error saving course: $e');
      rethrow;
    }
  }

  /// Get all saved courses
  Future<List<CourseInfo>> getAllCourses() async {
    try {
      final prefs = await _getPrefs();
      final coursesJson = prefs.getStringList(_coursesKey) ?? [];

      // Use compute() for large lists (>10 courses) to avoid UI jank
      final List<CourseInfo> courses;
      if (coursesJson.length > 10) {
        courses = await compute(_parseCoursesJson, coursesJson);
      } else {
        courses = coursesJson.map((jsonStr) {
          final Map<String, dynamic> courseMap = json.decode(jsonStr);
          return CourseInfo.fromJson(courseMap);
        }).toList();
      }

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
      final prefs = await _getPrefs();
      final courses = await getAllCourses();

      // Find the course to be deleted to check for associated file
      final courseToDelete = courses.firstWhere(
        (c) => c.courseCode == courseCode,
        orElse: () => CourseInfo(
          courseName: '',
          courseCode: '',
          events: [],
        ), // detailed dummy
      );

      // If course has a source file, delete it from storage
      if (courseToDelete.sourceFileUrl != null &&
          courseToDelete.sourceFileUrl!.isNotEmpty) {
        try {
          await _firebaseService.deleteFile(courseToDelete.sourceFileUrl!);
          print('Deleted associated source file');
        } catch (e) {
          print('Error deleting source file: $e');
          // Continue with course deletion even if file deletion fails
        }
      }

      courses.removeWhere((c) => c.courseCode == courseCode);

      final coursesJson = courses.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_coursesKey, coursesJson);
      print('Deleted course from local: $courseCode');

      // Delete from cloud if user is signed in
      await _deleteCourseFromCloud(courseCode);
    } catch (e) {
      print('Error deleting course: $e');
      rethrow;
    }
  }

  /// Delete cloud data only (Firestore and Storage)
  Future<void> deleteCloudData() async {
    try {
      // 1. Delete all files in storage
      await _firebaseService.deleteAllUserFiles();

      // 2. Delete all courses in Firestore
      await _clearCoursesFromCloud();

      print('Successfully deleted all cloud data');
    } catch (e) {
      print('Error deleting cloud data: $e');
      rethrow;
    }
  }

  /// Clear all saved courses from local and cloud storage
  Future<void> clearAllCourses() async {
    try {
      // Clear cloud data first (more robust)
      await deleteCloudData();

      // Clear local storage
      final prefs = await _getPrefs();
      await prefs.remove(_coursesKey);
      print('Cleared all courses from local storage');
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

  // ============== CLOUD SYNC METHODS ==============

  /// Sync a single course to Firestore
  Future<void> _syncCourseToCloud(CourseInfo course) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        print('Not signed in - skipping cloud sync');
        return;
      }

      final userId = user.uid;
      final courseId = course.courseCode.isEmpty
          ? course.courseName.toLowerCase().replaceAll(' ', '_')
          : course.courseCode;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseId)
          .set(course.toJson(), SetOptions(merge: true));

      print('Synced course to cloud: ${course.courseName}');
    } catch (e) {
      print('Error syncing course to cloud: $e');
      // Don't rethrow - cloud sync is optional
    }
  }

  /// Sync all courses from Firestore to local storage
  Future<void> syncFromCloud() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        print('Not signed in - cannot sync from cloud');
        return;
      }

      final userId = user.uid;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .orderBy('courseName')
          .limit(100) // Limit to 100 courses for performance
          .get();

      if (snapshot.docs.isEmpty) {
        print('No courses found in cloud');
        return;
      }

      // Get current local courses
      final localCourses = await getAllCourses();
      final localCourseCodes = localCourses.map((c) => c.courseCode).toSet();

      // Add cloud courses that don't exist locally
      int syncedCount = 0;
      for (final doc in snapshot.docs) {
        try {
          final course = CourseInfo.fromJson(doc.data());

          // Only add if not already in local storage
          if (!localCourseCodes.contains(course.courseCode)) {
            localCourses.add(course);
            syncedCount++;
          }
        } catch (e) {
          print('Error parsing cloud course ${doc.id}: $e');
        }
      }

      if (syncedCount > 0) {
        // Save merged courses to local storage
        final prefs = await _getPrefs();
        final coursesJson = localCourses
            .map((c) => json.encode(c.toJson()))
            .toList();
        await prefs.setStringList(_coursesKey, coursesJson);
        print('Synced $syncedCount courses from cloud to local');
      } else {
        print('All cloud courses already exist locally');
      }
    } catch (e) {
      print('Error syncing from cloud: $e');
      // Don't rethrow - cloud sync is optional
    }
  }

  /// Delete a course from Firestore
  Future<void> _deleteCourseFromCloud(String courseCode) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final userId = user.uid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .doc(courseCode)
          .delete();

      print('Deleted course from cloud: $courseCode');
    } catch (e) {
      print('Error deleting course from cloud: $e');
      // Don't rethrow - cloud sync is optional
    }
  }

  /// Clear all courses from Firestore
  Future<void> _clearCoursesFromCloud() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courses')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('Cleared all courses from cloud');
    } catch (e) {
      print('Error clearing courses from cloud: $e');
      // Don't rethrow - cloud sync is optional
    }
  }
}
