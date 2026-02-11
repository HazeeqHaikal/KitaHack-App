import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class AdaptiveLearningScreen extends StatefulWidget {
  const AdaptiveLearningScreen({super.key});

  @override
  State<AdaptiveLearningScreen> createState() => _AdaptiveLearningScreenState();
}

class _AdaptiveLearningScreenState extends State<AdaptiveLearningScreen> {
  bool _enableAdaptive = true;
  bool _autoAdjustDuration = true;
  bool _difficultyScaling = true;
  bool _performanceTracking = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Adaptive Learning'),
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

              // Overview
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.psychology,
                            color: AppConstants.primaryColor,
                            size: 28,
                          ),
                          SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: Text(
                              'What is Adaptive Learning?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      const Text(
                        'Due\'s AI automatically adjusts study session lengths, difficulty, and pace based on your performance and learning patterns. The more you use it, the smarter it gets!',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Settings
              _buildSectionTitle('Adaptive Features'),
              _buildSwitchTile(
                title: 'Enable Adaptive Learning',
                subtitle: 'Let AI optimize your study experience',
                value: _enableAdaptive,
                icon: Icons.auto_fix_high,
                onChanged: (value) {
                  setState(() {
                    _enableAdaptive = value;
                  });
                },
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildSwitchTile(
                title: 'Auto-Adjust Duration',
                subtitle: 'Change session length based on topic difficulty',
                value: _autoAdjustDuration,
                icon: Icons.access_time,
                onChanged: _enableAdaptive
                    ? (value) {
                        setState(() {
                          _autoAdjustDuration = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildSwitchTile(
                title: 'Difficulty Scaling',
                subtitle: 'Allocate more time for challenging subjects',
                value: _difficultyScaling,
                icon: Icons.school,
                onChanged: _enableAdaptive
                    ? (value) {
                        setState(() {
                          _difficultyScaling = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildSwitchTile(
                title: 'Performance Tracking',
                subtitle: 'Learn from past completion rates',
                value: _performanceTracking,
                icon: Icons.trending_up,
                onChanged: _enableAdaptive
                    ? (value) {
                        setState(() {
                          _performanceTracking = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: AppConstants.spacingL),

              // AI Insights
              _buildSectionTitle('Recent AI Adjustments'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInsight(
                        'Session Extended',
                        'Added 15 min to Thermodynamics study due to quiz difficulty',
                        Icons.add_circle,
                        AppConstants.accentColor,
                        '2 days ago',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildInsight(
                        'Break Time Reduced',
                        'You completed Data Structures tasks faster than expected',
                        Icons.fast_forward,
                        AppConstants.successColor,
                        '3 days ago',
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildInsight(
                        'Early Start Recommended',
                        'Final Exam prep moved 2 days earlier based on workload',
                        Icons.calendar_today,
                        Colors.orange,
                        '1 week ago',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Performance Impact
              _buildSectionTitle('Performance Impact'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    children: [
                      const Text(
                        'Since enabling Adaptive Learning',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildImpactStat(
                            '+15%',
                            'Completion Rate',
                            Icons.check_circle,
                            AppConstants.successColor,
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: AppConstants.textSecondary,
                          ),
                          _buildImpactStat(
                            '-22%',
                            'Missed Deadlines',
                            Icons.event_busy,
                            AppConstants.primaryColor,
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: AppConstants.textSecondary,
                          ),
                          _buildImpactStat(
                            '+8.5h',
                            'Study Time Saved',
                            Icons.timer,
                            AppConstants.accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // How It Works
              _buildSectionTitle('How It Works'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStep(
                        '1',
                        'Data Collection',
                        'AI tracks your study sessions, completion rates, and task difficulty',
                        Icons.analytics,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildStep(
                        '2',
                        'Pattern Analysis',
                        'Identifies your learning patterns and productivity trends',
                        Icons.insights,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildStep(
                        '3',
                        'Smart Adjustments',
                        'Automatically optimizes session duration and scheduling',
                        Icons.tune,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildStep(
                        '4',
                        'Continuous Learning',
                        'Gets better over time as you use the app more',
                        Icons.auto_awesome,
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool)? onChanged,
  }) {
    return GlassContainer(
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: onChanged != null
                ? Colors.white
                : AppConstants.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 12,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                (onChanged != null
                        ? AppConstants.primaryColor
                        : AppConstants.textSecondary)
                    .withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: onChanged != null
                ? AppConstants.primaryColor
                : AppConstants.textSecondary,
            size: 20,
          ),
        ),
        value: value,
        activeColor: AppConstants.primaryColor,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInsight(
    String title,
    String description,
    IconData icon,
    Color color,
    String time,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
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
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppConstants.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppConstants.primaryColor, width: 2),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppConstants.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
