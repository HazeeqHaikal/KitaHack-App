import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            children: [
              // Mock Feature Banner
              GlassContainer(
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.construction,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🚧 Mock Feature (Phase 3)',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'UI complete - backend implementation pending',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Completion Rate
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Completion Rate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'This Month',
                            style: TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '87',
                            style: TextStyle(
                              color: AppConstants.successColor,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '%',
                            style: TextStyle(
                              color: AppConstants.successColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.successColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '↑ 12%',
                              style: TextStyle(
                                color: AppConstants.successColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      LinearProgressIndicator(
                        value: 0.87,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        color: AppConstants.successColor,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      const Text(
                        '20 of 23 tasks completed',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Study Patterns
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study Patterns',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Total Hours',
                            '42.5',
                            Icons.timer,
                            AppConstants.primaryColor,
                          ),
                          _buildStatCard(
                            'Avg/Day',
                            '3.2h',
                            Icons.today,
                            AppConstants.accentColor,
                          ),
                          _buildStatCard(
                            'Peak Time',
                            '2-5 PM',
                            Icons.trending_up,
                            Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      const Text(
                        'Weekly Breakdown',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildWeeklyChart(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Course Performance
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Course Performance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      _buildCourseProgress('Thermodynamics', 0.92, 12, 13),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildCourseProgress('Data Structures', 0.85, 11, 13),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildCourseProgress('Linear Algebra', 0.78, 7, 9),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildCourseProgress('Programming', 0.95, 19, 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Streaks & Achievements
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Streaks & Achievements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      _buildAchievement(
                        '🔥 Study Streak',
                        '12 days in a row',
                        'Keep going!',
                        Colors.orange,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildAchievement(
                        '🎯 Perfect Week',
                        'Completed all tasks',
                        'Last week',
                        AppConstants.successColor,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildAchievement(
                        '⚡ Early Bird',
                        '8 tasks finished early',
                        'This month',
                        AppConstants.accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
