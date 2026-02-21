import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/providers/app_providers.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/models/task.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  // parse duration strings like "2 hours", "1.5h", "30 min" into hours
  double _parseDurationToHours(String raw) {
    final s = raw.toLowerCase();
    double hours = 0;

    // hours portion (e.g. "2h", "2 hours")
    final hMatch = RegExp(r"(\d+(?:\.\d+)?)\s*(?:h|hour)").firstMatch(s);
    if (hMatch != null) {
      hours += double.tryParse(hMatch.group(1)!) ?? 0;
    }

    // minutes portion (e.g. "30m", "30 min")
    final mMatch = RegExp(r"(\d+)\s*(?:m|min)").firstMatch(s);
    if (mMatch != null) {
      hours += (double.tryParse(mMatch.group(1)!) ?? 0) / 60.0;
    }

    return hours;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This listens to the live state of all courses
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
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
          // Here we handle Loading, Error, and Data states
          child: coursesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppConstants.primaryColor),
            ),
            error: (error, stack) => Center(
              child: Text('Failed to load analytics: $error', style: const TextStyle(color: Colors.white)),
            ),
            data: (courses) {
              // ---------------------------------------------------
              // 1. DATA CRUNCHING (The "PHP/JS Logic" section)
              // ---------------------------------------------------
              int totalTasks = 0;
              int completedTasks = 0;
              double totalHours = 0;
              
              // Lists to hold dynamic UI widgets for the Course Performance section
              List<Widget> courseProgressWidgets = [];

              for (var course in courses) {
                int courseTotalTasks = 0;
                int courseCompletedTasks = 0;

                for (var event in course.events) {
                  // Assuming your Event model has a list of tasks. 
                  // If tasks don't exist yet, you can track event completion instead.
                  for (var task in event.generatedTasks ?? []) {
                    totalTasks++;
                    courseTotalTasks++;
                    
                    if (task.isCompleted) {
                      completedTasks++;
                      courseCompletedTasks++;
                    }
                    
                    // Add up estimated time using your parsing function
                    if (task.duration != null) {
                       totalHours += _parseDurationToHours(task.duration!);
                    }
                  }
                }

                // Build a dynamic progress bar for each course
                double courseProgress = courseTotalTasks == 0 ? 0 : courseCompletedTasks / courseTotalTasks;
                courseProgressWidgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: _buildCourseProgress(
                      course.courseCode ?? 'Course', // Use courseCode or name
                      courseProgress, 
                      courseCompletedTasks, 
                      courseTotalTasks
                    ),
                  )
                );
              }

              // Calculate overall app percentages
              double completionRate = totalTasks == 0 ? 0 : completedTasks / totalTasks;
              int completionPercentage = (completionRate * 100).round();

              // ---------------------------------------------------
              // 2. THE UI (The "HTML" section)
              // ---------------------------------------------------
              return ListView(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                children: [
                  // --- COMPLETION RATE CARD ---
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Completion Rate', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Overall', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingL),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$completionPercentage', // INJECTED REAL DATA
                                style: const TextStyle(color: AppConstants.successColor, fontSize: 48, fontWeight: FontWeight.bold),
                              ),
                              const Text('%', style: TextStyle(color: AppConstants.successColor, fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          LinearProgressIndicator(
                            value: completionRate, // INJECTED REAL DATA
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: AppConstants.successColor,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            '$completedTasks of $totalTasks tasks completed', // INJECTED REAL DATA
                            style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),

                  // --- STUDY PATTERNS CARD ---
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Study Workload', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppConstants.spacingL),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Total Est. Hours', totalHours.toStringAsFixed(1), Icons.timer, AppConstants.primaryColor),
                              _buildStatCard('Total Tasks', totalTasks.toString(), Icons.assignment, AppConstants.accentColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),

                  // --- COURSE PERFORMANCE CARD ---
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Course Progress', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppConstants.spacingL),
                          
                          // If there are no courses, show a placeholder. Otherwise, inject our dynamic list!
                          if (courseProgressWidgets.isEmpty)
                            const Text('No courses loaded yet.', style: TextStyle(color: AppConstants.textSecondary)),
                          ...courseProgressWidgets,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildWeeklyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hours = [4.2, 3.5, 5.1, 2.8, 6.2, 1.5, 3.8];
    final maxHours = 6.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final height = (hours[index] / maxHours) * 100.0;
        return Column(
          children: [
            Text(
              '${hours[index]}h',
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: height,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCourseProgress(
    String name,
    double progress,
    int completed,
    int total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$completed/$total',
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.1),
          color: _getProgressColor(progress),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return AppConstants.successColor;
    if (progress >= 0.7) return AppConstants.accentColor;
    return Colors.orange;
  }

  Widget _buildAchievement(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.emoji_events, color: color, size: 32),
        ],
      ),
    );
  }
}
