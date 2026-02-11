import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:due/services/storage_service.dart';
import 'package:due/services/firebase_service.dart';
import 'package:due/services/calendar_service.dart';
import 'package:due/models/course_info.dart';

/// SharedPreferences singleton - cached once on app startup
/// Eliminates 14+ repeated getInstance() calls throughout the app
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden at app startup',
  );
});

/// Storage service - depends on cached SharedPreferences
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService.withPrefs(prefs);
});

/// Firebase service singleton
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Calendar service singleton
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

/// Courses data provider - single source of truth for course list
/// Eliminates repeated storage reads and provides reactive updates
final coursesProvider =
    StateNotifierProvider<CoursesNotifier, AsyncValue<List<CourseInfo>>>((ref) {
      return CoursesNotifier(ref.watch(storageServiceProvider));
    });

class CoursesNotifier extends StateNotifier<AsyncValue<List<CourseInfo>>> {
  final StorageService _storageService;

  CoursesNotifier(this._storageService) : super(const AsyncValue.loading()) {
    loadCourses();
  }

  Future<void> loadCourses() async {
    try {
      state = const AsyncValue.loading();
      // Sync from Firestore first (if user is signed in)
      await _storageService.syncFromCloud();
      // Then load all courses (including synced ones)
      final courses = await _storageService.getAllCourses();
      state = AsyncValue.data(courses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadCourses();
  }

  Future<void> addCourse(CourseInfo course) async {
    await _storageService.saveCourse(course);
    await loadCourses();
  }

  Future<void> updateCourse(CourseInfo course) async {
    await _storageService.saveCourse(course);
    await loadCourses();
  }

  Future<void> deleteCourse(String courseId) async {
    await _storageService.deleteCourse(courseId);
    await loadCourses();
  }
}

/// Derived statistics from courses - cached and only recalculated when courses change
final coursesStatsProvider = Provider<CoursesStats>((ref) {
  final coursesAsync = ref.watch(coursesProvider);

  return coursesAsync.when(
    data: (courses) => _calculateStats(courses),
    loading: () => CoursesStats.empty(),
    error: (_, __) => CoursesStats.empty(),
  );
});

CoursesStats _calculateStats(List<CourseInfo> courses) {
  int totalCompleted = 0;
  int upcomingEvents = 0;
  double totalProgress = 0;

  final now = DateTime.now();

  for (var course in courses) {
    int completedInCourse = 0;
    for (var event in course.events) {
      final eventDate = event.dueDate;

      // Count as completed if it's in the past (rough estimation)
      if (eventDate.isBefore(now)) {
        totalCompleted++;
        completedInCourse++;
      }

      if (eventDate.isAfter(now)) {
        upcomingEvents++;
      }
    }

    // Calculate progress as percentage of events in the past
    if (course.events.isNotEmpty) {
      final courseProgress = (completedInCourse / course.events.length) * 100;
      totalProgress += courseProgress;
    }
  }

  double averageProgress = courses.isEmpty ? 0 : totalProgress / courses.length;

  return CoursesStats(
    totalCourses: courses.length,
    totalCompleted: totalCompleted,
    upcomingEvents: upcomingEvents,
    averageProgress: averageProgress,
  );
}

class CoursesStats {
  final int totalCourses;
  final int totalCompleted;
  final int upcomingEvents;
  final double averageProgress;

  CoursesStats({
    required this.totalCourses,
    required this.totalCompleted,
    required this.upcomingEvents,
    required this.averageProgress,
  });

  factory CoursesStats.empty() {
    return CoursesStats(
      totalCourses: 0,
      totalCompleted: 0,
      upcomingEvents: 0,
      averageProgress: 0.0,
    );
  }
}

/// Workload calculation provider - cached and only recalculates when courses change
/// Moves expensive 6-week nested loop calculation out of HomeScreen build method
final workloadHeatmapProvider = Provider<Map<DateTime, double>>((ref) {
  final coursesAsync = ref.watch(coursesProvider);

  return coursesAsync.when(
    data: (courses) => _calculateWeeklyWorkload(courses),
    loading: () => {},
    error: (_, __) => {},
  );
});

Map<DateTime, double> _calculateWeeklyWorkload(List<CourseInfo> courses) {
  Map<DateTime, double> weeklyWorkload = {};

  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

  // Calculate for 6 weeks ahead
  for (int week = 0; week < 6; week++) {
    DateTime weekStart = startOfWeek.add(Duration(days: week * 7));
    DateTime weekEnd = weekStart.add(const Duration(days: 7));

    // Normalize to start of day for consistent keys
    DateTime weekKey = DateTime(weekStart.year, weekStart.month, weekStart.day);

    double totalWorkload = 0.0;

    for (var course in courses) {
      for (var event in course.events) {
        final eventDate = event.dueDate;

        // Check if event falls within this week
        if (eventDate.isAfter(weekStart) && eventDate.isBefore(weekEnd)) {
          // Parse weight (default to 1.0 if parsing fails)
          double weight = 1.0;
          if (event.weightage != null && event.weightage!.isNotEmpty) {
            final parsedWeight = double.tryParse(
              event.weightage!.replaceAll('%', ''),
            );
            if (parsedWeight != null) {
              weight = parsedWeight;
            }
          }

          totalWorkload += weight;
        }
      }
    }

    weeklyWorkload[weekKey] = totalWorkload;
  }

  return weeklyWorkload;
}
