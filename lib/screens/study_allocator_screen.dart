import 'package:flutter/material.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/utils/date_formatter.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/custom_buttons.dart';

class StudyAllocatorScreen extends StatefulWidget {
  const StudyAllocatorScreen({super.key});

  @override
  State<StudyAllocatorScreen> createState() => _StudyAllocatorScreenState();
}

class _StudyAllocatorScreenState extends State<StudyAllocatorScreen> {
  final List<Map<String, dynamic>> _studySessions = [];
  bool _isAllocating = false;
  int _totalStudyHours = 6;

  void _allocateStudySessions(AcademicEvent event) {
    setState(() {
      _isAllocating = true;
    });

    // Simulate AI finding free slots in calendar
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isAllocating = false;
        _studySessions.clear();
        _studySessions.addAll(_generateMockSessions(event));
      });
    });
  }

  List<Map<String, dynamic>> _generateMockSessions(AcademicEvent event) {
    final now = DateTime.now();
    final daysUntilDue = event.daysUntilDue;

    // Generate study sessions based on days remaining
    final List<Map<String, dynamic>> sessions = [];

    if (event.type == EventType.exam) {
      _totalStudyHours = 12;
      // Spread 12 hours over multiple days
      final sessionCount = (daysUntilDue / 2).floor().clamp(3, 6);
      final hoursPerSession = (12 / sessionCount).round();

      for (int i = 0; i < sessionCount; i++) {
        final sessionDate = now.add(Duration(days: i * 2 + 1));
        sessions.add({
          'date': sessionDate,
          'time': '14:00 - ${14 + hoursPerSession}:00',
          'duration': '$hoursPerSession hours',
          'title': 'Study Session ${i + 1}',
          'description': 'Review chapters and practice problems',
          'location': 'Auto-detected from calendar',
        });
      }
    } else if (event.type == EventType.assignment) {
      _totalStudyHours = 6;
      final sessionCount = (daysUntilDue / 3).floor().clamp(2, 4);
      final hoursPerSession = (6 / sessionCount).round();

      for (int i = 0; i < sessionCount; i++) {
        final sessionDate = now.add(Duration(days: i * 3 + 1));
        sessions.add({
          'date': sessionDate,
          'time': '16:00 - ${16 + hoursPerSession}:00',
          'duration': '$hoursPerSession hours',
          'title': 'Work Session ${i + 1}',
          'description': 'Focus time for assignment',
          'location': 'Auto-detected from calendar',
        });
      }
    } else {
      _totalStudyHours = 4;
      sessions.add({
        'date': now.add(const Duration(days: 1)),
        'time': '15:00 - 17:00',
        'duration': '2 hours',
        'title': 'Preparation Session 1',
        'description': 'Initial work and research',
        'location': 'Auto-detected from calendar',
      });
      sessions.add({
        'date': now.add(Duration(days: (daysUntilDue / 2).round())),
        'time': '14:00 - 16:00',
        'duration': '2 hours',
        'title': 'Preparation Session 2',
        'description': 'Final review and completion',
        'location': 'Auto-detected from calendar',
      });
    }

    return sessions;
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as AcademicEvent?;

    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    // Auto-allocate on first load
    if (_studySessions.isEmpty && !_isAllocating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _allocateStudySessions(event);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Study Allocator'),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppConstants.secondaryColor
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  color: AppConstants.secondaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingM),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Smart Study Allocator',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'AI finds free time & books study sessions',
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
                          const SizedBox(height: AppConstants.spacingM),
                          Container(
                            padding: const EdgeInsets.all(
                              AppConstants.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.secondaryColor.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  color: AppConstants.secondaryColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: AppConstants.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    if (_studySessions.isNotEmpty)
                      GlassContainer(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Sessions',
                              _studySessions.length.toString(),
                              Icons.event_note,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppConstants.glassBorder,
                            ),
                            _buildStatItem(
                              'Total Time',
                              '${_totalStudyHours}h',
                              Icons.schedule,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppConstants.glassBorder,
                            ),
                            _buildStatItem(
                              'Days Left',
                              event.daysUntilDue.toString(),
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppConstants.spacingM),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingS),
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.secondaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppConstants.secondaryColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Free slots detected using Google Calendar API',
                              style: TextStyle(
                                color: AppConstants.secondaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isAllocating
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppConstants.secondaryColor,
                            ),
                            SizedBox(height: AppConstants.spacingM),
                            Text(
                              'Scanning your calendar for free time...',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _studySessions.isEmpty
                    ? const Center(
                        child: Text(
                          'No sessions yet',
                          style: TextStyle(color: AppConstants.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingL,
                        ),
                        itemCount: _studySessions.length,
                        itemBuilder: (context, index) {
                          return _buildSessionCard(index);
                        },
                      ),
              ),
              if (_studySessions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: PrimaryButton(
                    text: 'Book All Study Sessions',
                    icon: Icons.add_to_photos,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Sessions will be added to Google Calendar when API is connected!',
                          ),
                          backgroundColor: AppConstants.successColor,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.secondaryColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
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

  Widget _buildSessionCard(int index) {
    final session = _studySessions[index];
    final date = session['date'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        hasShadow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppConstants.secondaryColor,
                        AppConstants.primaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        session['description'] as String,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Divider(color: AppConstants.glassBorder, height: 1),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppConstants.secondaryColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.formatDate(date),
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                const Icon(
                  Icons.access_time,
                  color: AppConstants.secondaryColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  session['time'] as String,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppConstants.secondaryColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  session['duration'] as String,
                  style: const TextStyle(
                    color: AppConstants.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
