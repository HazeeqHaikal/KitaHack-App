import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/models/course_info.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/date_formatter.dart';
import 'package:due/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<CourseInfo> _courses = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  Map<String, int> _statistics = {
    'totalCourses': 0,
    'totalEvents': 0,
    'weeklyEvents': 0,
    'highPriorityEvents': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courses = await _storageService.getAllCourses();
      final upcomingEvents = await _storageService.getUpcomingEvents(limit: 5);
      final statistics = await _storageService.getStatistics();

      setState(() {
        _courses = courses;
        _upcomingEvents = upcomingEvents;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusM,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryColor.withOpacity(
                                  0.4,
                                ),
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
                    // Glass Icon Button
                    GlassContainer(
                      padding: const EdgeInsets.all(8),
                      borderRadius: 12,
                      width: 44,
                      height: 44,
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      child: const Center(
                        child: Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppConstants.secondaryColor,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppConstants.secondaryColor,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppConstants.spacingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Stats overview
                              _buildStatsGrid(context),
                              const SizedBox(height: AppConstants.spacingXL),
                              // Upcoming deadlines section
                              _buildSectionHeader(
                                context,
                                'Upcoming Deadlines',
                                Icons.event,
                              ),
                              const SizedBox(height: AppConstants.spacingM),
                              _buildUpcomingEvents(context),
                              const SizedBox(height: AppConstants.spacingXL),
                              // Your courses section
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      _loadData();
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
                              _buildCoursesList(context),
                              const SizedBox(height: AppConstants.spacingXL),
                              // Quick actions
                              _buildActionButtons(context),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppConstants.spacingM,
      crossAxisSpacing: AppConstants.spacingM,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          context,
          icon: Icons.library_books,
          label: 'Active Courses',
          value: _statistics['totalCourses'].toString(),
          color: AppConstants.primaryColor,
        ),
        _buildStatCard(
          context,
          icon: Icons.event_note,
          label: 'Total Events',
          value: _statistics['totalEvents'].toString(),
          color: AppConstants.secondaryColor,
        ),
        _buildStatCard(
          context,
          icon: Icons.alarm,
          label: 'This Week',
          value: _statistics['weeklyEvents'].toString(),
          color: AppConstants.warningColor,
        ),
        _buildStatCard(
          context,
          icon: Icons.priority_high,
          label: 'High Priority',
          value: _statistics['highPriorityEvents'].toString(),
          color: AppConstants.errorColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassContainer(
      hasShadow: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  Widget _buildUpcomingEvents(BuildContext context) {
    if (_upcomingEvents.isEmpty) {
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
      children: _upcomingEvents
          .map(
            (eventData) => _buildEventItem(
              context,
              eventData['event'] as AcademicEvent,
              eventData['courseName'] as String,
            ),
          )
          .toList(),
    );
  }

  Widget _buildEventItem(
    BuildContext context,
    AcademicEvent event,
    String courseName,
  ) {
    final daysUntil = event.daysUntilDue;
    final urgencyColor = daysUntil <= 3
        ? AppConstants.errorColor
        : daysUntil <= 7
        ? AppConstants.warningColor
        : AppConstants.successColor;

    return Container(
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

  Widget _buildCoursesList(BuildContext context) {
    if (_courses.isEmpty) {
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
      children: _courses
          .map((course) => _buildCourseCard(context, course))
          .toList(),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseInfo course) {
    final upcomingCount = course.upcomingEvents.length;
    final highPriorityCount = course.highPriorityEvents.length;

    return Container(
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
        PrimaryButton(
          text: 'Upload New Syllabus',
          icon: Icons.upload_file,
          onPressed: () {
            Navigator.pushNamed(context, '/upload');
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
