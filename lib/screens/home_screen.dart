import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/bottom_nav_bar.dart';
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
      // Sync from cloud first if signed in
      await _storageService.syncFromCloud();

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

  /// Calculate workload distribution for the next 6 weeks
  List<Map<String, dynamic>> _calculateWeeklyWorkload() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> weeklyData = [];

    // Get all events from all courses
    final allEvents = <AcademicEvent>[];
    for (var course in _courses) {
      allEvents.addAll(course.events);
    }

    // Calculate data for next 6 weeks
    for (int weekIndex = 0; weekIndex < 6; weekIndex++) {
      final weekStart = now.add(Duration(days: weekIndex * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Count events in this week
      final eventsInWeek = allEvents.where((event) {
        final dueDate = event.dueDate;
        return dueDate.isAfter(weekStart) && dueDate.isBefore(weekEnd);
      }).toList();

      // Calculate total workload weight (sum of weightages)
      double totalWeight = 0;
      int highPriorityCount = 0;

      for (var event in eventsInWeek) {
        // Parse weightage string (e.g., "20%" or "20") to double
        if (event.weightage != null) {
          final weight =
              double.tryParse(event.weightage!.replaceAll('%', '')) ?? 0;
          totalWeight += weight;
        }
        if (event.priority == EventPriority.high) {
          highPriorityCount++;
        }
      }

      // Determine intensity level
      String intensity;
      Color color;
      if (totalWeight >= 60 || eventsInWeek.length >= 5) {
        intensity = 'Heavy';
        color = AppConstants.errorColor;
      } else if (totalWeight >= 30 || eventsInWeek.length >= 3) {
        intensity = 'Medium';
        color = AppConstants.warningColor;
      } else if (eventsInWeek.isNotEmpty) {
        intensity = 'Light';
        color = AppConstants.successColor;
      } else {
        intensity = 'Free';
        color = AppConstants.textSecondary.withOpacity(0.3);
      }

      weeklyData.add({
        'weekNumber': weekIndex + 1,
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'eventCount': eventsInWeek.length,
        'highPriorityCount': highPriorityCount,
        'totalWeight': totalWeight,
        'intensity': intensity,
        'color': color,
        'events': eventsInWeek,
      });
    }

    return weeklyData;
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
                              // Workload Heat Map
                              _buildSectionHeader(
                                context,
                                'Workload Overview',
                                Icons.calendar_view_week,
                              ),
                              const SizedBox(height: AppConstants.spacingM),
                              _buildWorkloadHeatMap(context),
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
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
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

  Widget _buildWorkloadHeatMap(BuildContext context) {
    if (_courses.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: const Column(
          children: [
            Icon(
              Icons.calendar_view_week,
              size: 48,
              color: AppConstants.textSecondary,
            ),
            SizedBox(height: AppConstants.spacingM),
            Text(
              'No workload data yet',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingS),
            Text(
              'Upload a syllabus to see your workload distribution',
              style: TextStyle(color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final weeklyData = _calculateWeeklyWorkload();

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      hasShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                'Free',
                AppConstants.textSecondary.withOpacity(0.3),
              ),
              _buildLegendItem('Light', AppConstants.successColor),
              _buildLegendItem('Medium', AppConstants.warningColor),
              _buildLegendItem('Heavy', AppConstants.errorColor),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          const Divider(color: AppConstants.glassBorder, height: 1),
          const SizedBox(height: AppConstants.spacingM),
          // Heat map grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              childAspectRatio: 1.2,
            ),
            itemCount: weeklyData.length,
            itemBuilder: (context, index) {
              final weekData = weeklyData[index];
              return _buildWeekCell(context, weekData);
            },
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Summary text
          Text(
            'Next 6 weeks workload distribution',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppConstants.glassBorder, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCell(BuildContext context, Map<String, dynamic> weekData) {
    final weekStart = weekData['weekStart'] as DateTime;
    final eventCount = weekData['eventCount'] as int;
    final highPriorityCount = weekData['highPriorityCount'] as int;
    final intensity = weekData['intensity'] as String;
    final color = weekData['color'] as Color;
    final events = weekData['events'] as List<AcademicEvent>;

    return GestureDetector(
      onTap: () {
        if (eventCount > 0) {
          _showWeekDetailsDialog(context, weekData);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Week ${weekData['weekNumber']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.formatShortDate(weekStart),
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              if (eventCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$eventCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (highPriorityCount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 12,
                        color: AppConstants.errorColor,
                      ),
                      Text(
                        '$highPriorityCount',
                        style: TextStyle(
                          color: AppConstants.errorColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ] else
                Text(
                  intensity,
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeekDetailsDialog(
    BuildContext context,
    Map<String, dynamic> weekData,
  ) {
    final weekStart = weekData['weekStart'] as DateTime;
    final weekEnd = weekData['weekEnd'] as DateTime;
    final events = weekData['events'] as List<AcademicEvent>;
    final intensity = weekData['intensity'] as String;
    final totalWeight = weekData['totalWeight'] as double;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          hasShadow: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_view_week,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${weekData['weekNumber']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${DateFormatter.formatShortDate(weekStart)} - ${DateFormatter.formatShortDate(weekEnd)}',
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: (weekData['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusM,
                  ),
                  border: Border.all(
                    color: (weekData['color'] as Color).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          intensity,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Intensity',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppConstants.glassBorder,
                    ),
                    Column(
                      children: [
                        Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Events',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppConstants.glassBorder,
                    ),
                    Column(
                      children: [
                        Text(
                          '${totalWeight.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Weight',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              const Text(
                'Events this week:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final priorityColor = event.priority == EventPriority.high
                        ? AppConstants.errorColor
                        : event.priority == EventPriority.medium
                        ? AppConstants.warningColor
                        : AppConstants.successColor;

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingS,
                      ),
                      padding: const EdgeInsets.all(AppConstants.spacingS),
                      decoration: BoxDecoration(
                        color: AppConstants.glassSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusS,
                        ),
                        border: Border.all(
                          color: priorityColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 10,
                                      color: AppConstants.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormatter.formatDate(event.dueDate),
                                      style: const TextStyle(
                                        color: AppConstants.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppConstants.spacingS,
                                    ),
                                    if (event.weightage != null &&
                                        event.weightage!.isNotEmpty) ...[
                                      Icon(
                                        Icons.fitness_center,
                                        size: 10,
                                        color: AppConstants.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${event.weightage}%',
                                        style: const TextStyle(
                                          color: AppConstants.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getEventTypeColor(
                                event.type,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getEventTypeColor(event.type),
                              ),
                            ),
                            child: Text(
                              event.type
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: TextStyle(
                                color: _getEventTypeColor(event.type),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Study Allocator',
                icon: Icons.schedule,
                onPressed: () {
                  Navigator.pushNamed(context, '/study-allocator');
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: SecondaryButton(
                text: 'Task Breakdown',
                icon: Icons.assignment,
                onPressed: () {
                  Navigator.pushNamed(context, '/task-breakdown');
                },
              ),
            ),
          ],
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
