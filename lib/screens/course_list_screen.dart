import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/bottom_nav_bar.dart';
import 'package:due/models/course_info.dart';
import 'package:due/providers/app_providers.dart';

class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Select Course'),
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
          child: coursesAsync.when(
            data: (courses) => courses.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingL),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return _buildCourseCard(context, course);
                    },
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppConstants.secondaryColor,
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppConstants.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    'Error loading courses',
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    error.toString(),
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_outlined,
                size: 80,
                color: AppConstants.textSecondary,
              ),
              const SizedBox(height: AppConstants.spacingL),
              const Text(
                'No Courses Yet',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              const Text(
                'Start by uploading a course syllabus to automatically extract deadlines and events.',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Syllabus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL * 2,
                    vertical: AppConstants.spacingM,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseInfo course) {
    final upcomingCount = course.upcomingEvents.length;
    final highPriorityCount = course.highPriorityEvents.length;

    return Dismissible(
      key: Key(course.courseCode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteConfirmation(context, course),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: AppConstants.errorColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacingL),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        child: GlassContainer(
          hasShadow: true,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/result',
                arguments: {'courseCode': course.courseCode},
              );
            },
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingS),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseCode,
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              course.courseName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppConstants.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.instructor ?? 'N/A',
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      const Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.semester ?? 'N/A',
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  const Divider(color: AppConstants.glassBorder, height: 1),
                  const SizedBox(height: AppConstants.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCourseStatItem(
                        icon: Icons.event,
                        label: 'Total',
                        value: course.totalEvents.toString(),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppConstants.glassBorder,
                      ),
                      _buildCourseStatItem(
                        icon: Icons.upcoming,
                        label: 'Upcoming',
                        value: upcomingCount.toString(),
                        color: AppConstants.successColor,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppConstants.glassBorder,
                      ),
                      _buildCourseStatItem(
                        icon: Icons.priority_high,
                        label: 'Priority',
                        value: highPriorityCount.toString(),
                        color: AppConstants.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppConstants.textSecondary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    CourseInfo course,
  ) async {
    final syncedCount = course.events
        .where((e) => e.calendarEventId != null)
        .length;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundEnd,
        title: const Text(
          'Delete Course?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete "${course.courseCode}" and all its events.',
              style: const TextStyle(color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 12),
            if (syncedCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppConstants.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$syncedCount synced event${syncedCount > 1 ? 's' : ''} will be removed from Google Calendar',
                        style: const TextStyle(
                          color: AppConstants.warningColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await _deleteCourse(course);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(CourseInfo course) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppConstants.primaryColor),
            SizedBox(height: 16),
            Text('Deleting course...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      // Delete synced events from Google Calendar
      final syncedEvents = course.events
          .where((e) => e.calendarEventId != null)
          .toList();

      if (syncedEvents.isNotEmpty) {
        final calendarService = ref.read(calendarServiceProvider);

        // Sign in if needed
        if (!calendarService.isAuthenticated) {
          try {
            await calendarService.signIn();
          } catch (e) {
            print('Calendar sign-in failed: $e');
            // Continue with local deletion even if calendar deletion fails
          }
        }

        // Delete from calendar if authenticated
        if (calendarService.isAuthenticated) {
          try {
            final calendars = await calendarService.getCalendars();
            final primaryCalendar = calendars.firstWhere(
              (cal) => cal.primary == true,
              orElse: () => calendars.first,
            );

            await calendarService.deleteEventsFromCalendar(
              syncedEvents,
              primaryCalendar.id!,
            );
          } catch (e) {
            print('Failed to delete calendar events: $e');
            // Continue with local deletion even if calendar deletion fails
          }
        }
      }

      // Delete course from local storage via provider
      await ref.read(coursesProvider.notifier).deleteCourse(course.courseCode);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (!mounted) return;
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Course deleted successfully'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      print('Error deleting course: $e');

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete course: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
}
