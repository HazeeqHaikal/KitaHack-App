import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/bottom_nav_bar.dart';
import 'package:due/models/course_info.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/date_formatter.dart';
import 'package:due/providers/app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Sync from cloud and refresh courses
      final storageService = ref.read(storageServiceProvider);
      await storageService.syncFromCloud();
      await ref.read(coursesProvider.notifier).refresh();
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Watch providers for reactive updates
    final coursesAsync = ref.watch(coursesProvider);
    final stats = ref.watch(coursesStatsProvider);

    return Scaffold(
      // Ensure the background gradient covers the entire scaffold
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.backgroundStart, AppConstants.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Simple header
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Row(
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
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusM,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingM),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: coursesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.secondaryColor,
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading data: $error',
                          style: const TextStyle(
                            color: AppConstants.errorColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleRefresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (courses) => RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppConstants.secondaryColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Key stats
                          _buildSimpleStats(context, stats),
                          const SizedBox(height: AppConstants.spacingXL),
                          // Upcoming deadlines section
                          _buildSectionHeader(
                            context,
                            'Upcoming Deadlines',
                            Icons.event,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          _buildUpcomingEvents(context, courses),
                          const SizedBox(height: AppConstants.spacingXL),
                          // Your courses section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader(
                                context,
                                'Your Courses',
                                Icons.school,
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/courses',
                                  );
                                  // Reload data when returning
                                  _handleRefresh();
                                },
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: AppConstants.primaryColor,
                                ),
                                label: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          _buildCoursesList(context, courses),
                          const SizedBox(height: AppConstants.spacingXL),
                          // Quick actions
                          _buildActionButtons(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSimpleStats(BuildContext context, CoursesStats stats) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      hasShadow: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.school_rounded,
            label: 'Courses',
            value: stats.totalCourses.toString(),
            color: AppConstants.primaryColor,
          ),
          Container(width: 1, height: 40, color: AppConstants.glassBorder),
          _buildStatItem(
            icon: Icons.event_outlined,
            label: 'Upcoming',
            value: stats.upcomingEvents.toString(),
            color: AppConstants.warningColor,
          ),
          Container(width: 1, height: 40, color: AppConstants.glassBorder),
          _buildStatItem(
            icon: Icons.check_circle_outline,
            label: 'Completed',
            value: stats.totalCompleted.toString(),
            color: AppConstants.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 24),
        const SizedBox(width: AppConstants.spacingS),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, List<CourseInfo> courses) {
    // Collect upcoming events from all courses
    final now = DateTime.now();
    final upcomingEvents = <Map<String, dynamic>>[];

    for (var course in courses) {
      for (var event in course.events) {
        final eventDate = event.dueDate;
        if (eventDate.isAfter(now) && !event.isOverdue) {
          upcomingEvents.add({
            'event': event,
            'courseName': course.courseName,
            'dueDate': eventDate,
          });
        }
      }
    }

    // Sort by due date
    upcomingEvents.sort(
      (a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime),
    );

    // Take only first 5
    final displayEvents = upcomingEvents.take(5).toList();

    if (displayEvents.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: const Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AppConstants.textSecondary,
            ),
            SizedBox(height: AppConstants.spacingM),
            Text(
              'No upcoming events',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingS),
            Text(
              'Upload a syllabus to get started',
              style: TextStyle(color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: displayEvents.asMap().entries.map((entry) {
        final eventData = entry.value;
        final event = eventData['event'] as AcademicEvent;
        final courseName = eventData['courseName'] as String;
        return _buildEventItem(
          context,
          event,
          courseName,
          key: ValueKey(
            '${courseName}_${event.title}_${event.dueDate.toIso8601String()}',
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    AcademicEvent event,
    String courseName, {
    Key? key,
  }) {
    final daysUntil = event.daysUntilDue;
    final urgencyColor = daysUntil <= 3
        ? AppConstants.errorColor
        : daysUntil <= 7
        ? AppConstants.warningColor
        : AppConstants.successColor;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            // Date indicator
            Container(
              width: 60,
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                border: Border.all(color: urgencyColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    event.dueDate.day.toString(),
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormatter.getMonthAbbreviation(event.dueDate.month),
                    style: TextStyle(color: urgencyColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getEventTypeColor(
                            event.type,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.type.displayName,
                          style: TextStyle(
                            color: _getEventTypeColor(event.type),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (event.calendarEventId != null) ...[
                        const SizedBox(width: AppConstants.spacingXS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.successColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppConstants.successColor.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 9,
                                color: AppConstants.successColor,
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'Synced',
                                style: TextStyle(
                                  color: AppConstants.successColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (event.weightage != null) ...[
                        const SizedBox(width: AppConstants.spacingXS),
                        Text(
                          event.weightage!,
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        courseName,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                      Text(
                        daysUntil == 0
                            ? 'Due today!'
                            : daysUntil == 1
                            ? 'Due tomorrow'
                            : 'Due in $daysUntil days',
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context, List<CourseInfo> courses) {
    if (courses.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            const Icon(
              Icons.school_outlined,
              size: 48,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'No courses yet',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            const Text(
              'Upload your first syllabus to begin',
              style: TextStyle(color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/upload');
              },
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload Syllabus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: courses.map((course) {
        return _buildCourseCard(
          context,
          course,
          key: ValueKey(course.courseCode),
        );
      }).toList(),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseInfo course, {Key? key}) {
    final upcomingCount = course.upcomingEvents.length;
    final highPriorityCount = course.highPriorityEvents.length;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassContainer(
        hasShadow: true,
        child: InkWell(
          onTap: () {
            // Navigate to result screen with course code
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
                    Icon(
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
                    Icon(
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
                Divider(color: AppConstants.glassBorder, height: 1),
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
        return const Color(0xFFFF6B9D); // Pink
      case EventType.lab:
        return AppConstants.successColor;
      case EventType.other:
        return AppConstants.textSecondary;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SecondaryButton(
          text: 'Sync to Calendar',
          icon: Icons.sync,
          onPressed: () {
            Navigator.pushNamed(context, '/calendar-sync');
          },
        ),
        const SizedBox(height: AppConstants.spacingM),
        SecondaryButton(
          text: 'Join Course Code',
          icon: Icons.group_add,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group sync feature - Coming soon!'),
                backgroundColor: AppConstants.warningColor,
              ),
            );
          },
        ),
      ],
    );
  }
}
