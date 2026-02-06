import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/models/course_info.dart';

class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No mock data - show empty state
    final courses = <CourseInfo>[];

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
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(context, course);
            },
          ),
        ),
      ),
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
            // Navigate to result screen with course data
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
}
