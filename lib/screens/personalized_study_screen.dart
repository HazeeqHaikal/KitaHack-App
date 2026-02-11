import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';

class PersonalizedStudyScreen extends StatefulWidget {
  const PersonalizedStudyScreen({super.key});

  @override
  State<PersonalizedStudyScreen> createState() =>
      _PersonalizedStudyScreenState();
}

class _PersonalizedStudyScreenState extends State<PersonalizedStudyScreen> {
  String _studyStyle = 'visual'; // visual, auditory, reading, kinesthetic
  String _productivityTime = 'morning'; // morning, afternoon, evening, night
  int _sessionDuration = 45; // minutes
  int _breakDuration = 15; // minutes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Personalized Study Plans'),
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

              // Learning Style
              _buildSectionTitle('Your Learning Style'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How do you learn best?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildLearningStyleOption(
                        'Visual',
                        'Diagrams, charts, and images',
                        Icons.visibility,
                        'visual',
                      ),
                      _buildLearningStyleOption(
                        'Auditory',
                        'Lectures, discussions, and audio',
                        Icons.hearing,
                        'auditory',
                      ),
                      _buildLearningStyleOption(
                        'Reading/Writing',
                        'Reading texts and taking notes',
                        Icons.menu_book,
                        'reading',
                      ),
                      _buildLearningStyleOption(
                        'Kinesthetic',
                        'Hands-on practice and experiments',
                        Icons.touch_app,
                        'kinesthetic',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Productivity Time
              _buildSectionTitle('Peak Productivity Time'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'When are you most productive?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeChip(
                              'Morning',
                              '6-11 AM',
                              'morning',
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: _buildTimeChip(
                              'Afternoon',
                              '12-5 PM',
                              'afternoon',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeChip(
                              'Evening',
                              '6-9 PM',
                              'evening',
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: _buildTimeChip(
                              'Night',
                              '10 PM-1 AM',
                              'night',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Study Session Settings
              _buildSectionTitle('Study Session Settings'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Duration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _sessionDuration.toDouble(),
                              min: 15,
                              max: 120,
                              divisions: 21,
                              activeColor: AppConstants.primaryColor,
                              inactiveColor: Colors.white.withOpacity(0.2),
                              onChanged: (value) {
                                setState(() {
                                  _sessionDuration = value.toInt();
                                });
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_sessionDuration min',
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      const Text(
                        'Break Duration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _breakDuration.toDouble(),
                              min: 5,
                              max: 30,
                              divisions: 5,
                              activeColor: AppConstants.accentColor,
                              inactiveColor: Colors.white.withOpacity(0.2),
                              onChanged: (value) {
                                setState(() {
                                  _breakDuration = value.toInt();
                                });
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_breakDuration min',
                              style: const TextStyle(
                                color: AppConstants.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // AI Recommendations
              _buildSectionTitle('AI Recommendations'),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                          SizedBox(width: AppConstants.spacingM),
                          Expanded(
                            child: Text(
                              'Based on your profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      _buildRecommendation(
                        'Morning Study Sessions',
                        'Schedule difficult subjects between 8-10 AM when you\'re most alert',
                        Icons.wb_sunny,
                        Colors.amber,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildRecommendation(
                        'Use Visual Aids',
                        'Create mind maps and diagrams for better retention',
                        Icons.image,
                        AppConstants.primaryColor,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      _buildRecommendation(
                        'Pomodoro Technique',
                        'Your $_sessionDuration min sessions with $_breakDuration min breaks',
                        Icons.timer,
                        AppConstants.accentColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Save Button
              ElevatedButton.icon(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Preferences',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildLearningStyleOption(
    String title,
    String description,
    IconData icon,
    String value,
  ) {
    final isSelected = _studyStyle == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _studyStyle = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppConstants.primaryColor, size: 20),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppConstants.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppConstants.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String time, String value) {
    final isSelected = _productivityTime == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _productivityTime = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.accentColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.accentColor
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppConstants.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(
    String title,
    String description,
    IconData icon,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _savePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ Preferences saved! AI will personalize your study plans',
        ),
        backgroundColor: AppConstants.successColor,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
