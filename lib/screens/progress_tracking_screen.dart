import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class ProgressTrackingScreen extends StatelessWidget {
  const ProgressTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Progress Tracking'),
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
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.purple,
                        size: 24,
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🧠 Advanced AI Feature (Phase 4)',
                              style: TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'UI complete - AI implementation pending',
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

              // Overall Progress
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    children: [
                      const Text(
                        'Overall Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CircularProgressIndicator(
                                value: 0.73,
                                strokeWidth: 16,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '73%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Complete',
                                  style: TextStyle(
                                    color: AppConstants.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProgressStat(
                            '42',
                            'Completed',
                            AppConstants.successColor,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppConstants.textSecondary,
                          ),
                          _buildProgressStat(
                            '15',
                            'In Progress',
                            AppConstants.accentColor,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: AppConstants.textSecondary,
                          ),
                          _buildProgressStat('8', 'Pending', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Milestones
              _buildSectionTitle('Milestones'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    children: [
                      _buildMilestone(
                        'Week 1-4',
                        'Foundation',
                        1.0,
                        true,
                        '100% • All tasks completed',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildMilestone(
                        'Week 5-8',
                        'Mid-Term Prep',
                        0.85,
                        false,
                        '85% • 2 tasks remaining',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildMilestone(
                        'Week 9-12',
                        'Advanced Topics',
                        0.45,
                        false,
                        '45% • In progress',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildMilestone(
                        'Week 13-16',
                        'Final Exams',
                        0.0,
                        false,
                        'Not started',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Course Progress
              _buildSectionTitle('Course Progress'),
              _buildCourseCard('Thermodynamics', 0.92, '11/12 tasks', [
                MilestoneData('Assignment 1', true),
                MilestoneData('Assignment 2', true),
                MilestoneData('Midterm', true),
                MilestoneData('Assignment 3', false),
                MilestoneData('Final Exam', false),
              ]),
              const SizedBox(height: AppConstants.spacingM),
              _buildCourseCard('Data Structures', 0.67, '8/12 tasks', [
                MilestoneData('Lab 1-3', true),
                MilestoneData('Assignment 1', true),
                MilestoneData('Quiz 1', false),
                MilestoneData('Assignment 2', false),
                MilestoneData('Final Project', false),
              ]),
              const SizedBox(height: AppConstants.spacingM),
              _buildCourseCard('Linear Algebra', 0.58, '7/12 tasks', [
                MilestoneData('Problem Set 1-2', true),
                MilestoneData('Quiz 1', true),
                MilestoneData('Problem Set 3', false),
                MilestoneData('Midterm', false),
                MilestoneData('Final Exam', false),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.spacingS,
        bottom: AppConstants.spacingS,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppConstants.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildProgressStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
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

  Widget _buildMilestone(
    String period,
    String title,
    double progress,
    bool completed,
    String status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (completed)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppConstants.successColor,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.1),
          color: completed
              ? AppConstants.successColor
              : AppConstants.primaryColor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(
    String courseName,
    double progress,
    String status,
    List<MilestoneData> milestones,
  ) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: _getProgressColor(progress),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              color: _getProgressColor(progress),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: milestones.map((m) => _buildMilestoneChip(m)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneChip(MilestoneData milestone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: milestone.completed
            ? AppConstants.successColor.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: milestone.completed
              ? AppConstants.successColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (milestone.completed)
            const Icon(
              Icons.check_circle,
              color: AppConstants.successColor,
              size: 12,
            ),
          if (milestone.completed) const SizedBox(width: 4),
          Text(
            milestone.name,
            style: TextStyle(
              color: milestone.completed
                  ? Colors.white
                  : AppConstants.textSecondary,
              fontSize: 11,
              fontWeight: milestone.completed
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return AppConstants.successColor;
    if (progress >= 0.7) return AppConstants.accentColor;
    if (progress >= 0.5) return Colors.orange;
    return AppConstants.errorColor;
  }
}

class MilestoneData {
  final String name;
  final bool completed;

  MilestoneData(this.name, this.completed);
}
