import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:due/models/course_info.dart';
import 'package:due/services/firebase_service.dart';

/// Model representing a shared course group code
class GroupCourseEntry {
  final String code;
  final String courseName;
  final String courseCode;
  final String createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int joinCount;
  final bool isActive;

  const GroupCourseEntry({
    required this.code,
    required this.courseName,
    required this.courseCode,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.expiresAt,
    required this.joinCount,
    required this.isActive,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;

  /// Days remaining before expiry
  int get daysRemaining => expiresAt.difference(DateTime.now()).inDays;

  factory GroupCourseEntry.fromFirestore(
    String code,
    Map<String, dynamic> data,
  ) {
    return GroupCourseEntry(
      code: code,
      courseName: data['courseName'] ?? 'Unknown Course',
      courseCode: data['courseCode'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      joinCount: data['joinCount'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}

/// Service for Group Sync functionality
/// Stores shared courses in Firestore under `group_courses/{code}`
class GroupSyncService {
  static final GroupSyncService _instance = GroupSyncService._internal();
  factory GroupSyncService() => _instance;
  GroupSyncService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  static const String _groupCoursesCollection = 'group_courses';
  static const int _codeExpiryDays = 30;
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  FirebaseFirestore? get _firestore {
    if (!_firebaseService.isAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      print('Firestore not available: $e');
      return null;
    }
  }

  bool get isAvailable => _firebaseService.isAvailable;

  // ── Code Generation ──────────────────────────────────────────────────────

  /// Generate a unique 6-character alphanumeric code
  Future<String> _generateUniqueCode() async {
    final firestore = _firestore;
    const maxAttempts = 10;

    for (var i = 0; i < maxAttempts; i++) {
      final code = _generateCode();
      if (firestore == null) return code; // Offline – just return a code

      final doc = await firestore
          .collection(_groupCoursesCollection)
          .doc(code)
          .get();
      if (!doc.exists) return code; // Code is free
    }

    throw Exception(
      'Failed to generate unique code after $maxAttempts attempts',
    );
  }

  String _generateCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => _chars[rng.nextInt(_chars.length)]).join();
  }

  // ── Create ───────────────────────────────────────────────────────────────

  /// Share a course by generating a group code.
  ///
  /// Stores the full course JSON in Firestore so classmates can retrieve it.
  /// Returns the 6-character code on success.
  Future<String> createGroupCode(CourseInfo course) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception(
        'Firebase is not available. Please sign in and try again.',
      );
    }

    final user = _firebaseService.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to create a group code.');
    }

    final code = await _generateUniqueCode();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: _codeExpiryDays));

    await firestore.collection(_groupCoursesCollection).doc(code).set({
      // Metadata for listing / display
      'courseName': course.courseName,
      'courseCode': course.courseCode,
      'createdBy': user.uid,
      'createdByName': user.displayName ?? user.email ?? 'Unknown',
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'joinCount': 0,
      'isActive': true,
      // Full course payload
      'courseData': course.toJson(),
    });

    print('Created group code $code for course: ${course.courseName}');
    return code;
  }

  // ── Join ─────────────────────────────────────────────────────────────────

  /// Look up a group code and return the associated [CourseInfo].
  ///
  /// Also increments the join counter atomically.
  Future<CourseInfo> joinWithCode(String code) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception(
        'Firebase is not available. Please sign in and try again.',
      );
    }

    final trimmed = code.trim().toUpperCase();
    if (trimmed.length != 6) {
      throw Exception('Course code must be exactly 6 characters.');
    }

    final ref = firestore.collection(_groupCoursesCollection).doc(trimmed);
    final doc = await ref.get();

    if (!doc.exists) {
      throw Exception('Code "$trimmed" not found. Please check and try again.');
    }

    final data = doc.data()!;
    final entry = GroupCourseEntry.fromFirestore(trimmed, data);

    if (!entry.isActive) {
      throw Exception('This code has been deactivated by its creator.');
    }
    if (entry.isExpired) {
      throw Exception('This code expired on ${_formatDate(entry.expiresAt)}.');
    }

    // Parse course data
    final courseDataRaw = data['courseData'];
    if (courseDataRaw == null || courseDataRaw is! Map<String, dynamic>) {
      throw Exception('The course data for this code is corrupted.');
    }

    final course = CourseInfo.fromJson(courseDataRaw);

    // Increment join counter (fire-and-forget – don't block the user)
    ref
        .update({'joinCount': FieldValue.increment(1)})
        .catchError((e) => print('joinCount increment failed: $e'));

    print('Joined course "${course.courseName}" via code $trimmed');
    return course;
  }

  // ── List user's codes ─────────────────────────────────────────────────────

  /// Returns all group codes created by the current user, newest first.
  Future<List<GroupCourseEntry>> getMyCreatedCodes() async {
    final firestore = _firestore;
    if (firestore == null) return [];

    final user = _firebaseService.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await firestore
          .collection(_groupCoursesCollection)
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => GroupCourseEntry.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error loading created codes: $e');
      return [];
    }
  }

  // ── Deactivate ────────────────────────────────────────────────────────────

  /// Deactivate a code so it can no longer be used to join.
  Future<void> deactivateCode(String code) async {
    final firestore = _firestore;
    if (firestore == null) {
      throw Exception('Firebase is not available.');
    }

    final user = _firebaseService.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to deactivate a code.');
    }

    final ref = firestore
        .collection(_groupCoursesCollection)
        .doc(code.toUpperCase());
    final doc = await ref.get();

    if (!doc.exists) throw Exception('Code not found.');

    if (doc.data()!['createdBy'] != user.uid) {
      throw Exception('You can only deactivate codes that you created.');
    }

    await ref.update({'isActive': false});
    print('Deactivated group code: $code');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
