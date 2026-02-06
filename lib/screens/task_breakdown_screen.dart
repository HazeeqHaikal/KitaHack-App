import 'package:flutter/material.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/custom_buttons.dart';

class TaskBreakdownScreen extends StatefulWidget {
  const TaskBreakdownScreen({super.key});

  @override
  State<TaskBreakdownScreen> createState() => _TaskBreakdownScreenState();
}

class _TaskBreakdownScreenState extends State<TaskBreakdownScreen> {
  final List<Map<String, dynamic>> _tasks = [];
  bool _isGenerating = false;

  void _generateTaskBreakdown(AcademicEvent event) {
    setState(() {
      _isGenerating = true;
    });

    // Simulate AI task breakdown generation
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isGenerating = false;
        _tasks.clear();
        _tasks.addAll(_getMockTasks(event));
      });
    });
  }

  List<Map<String, dynamic>> _getMockTasks(AcademicEvent event) {
    // Mock AI-generated task breakdown based on event type
    switch (event.type) {
      case EventType.assignment:
        return [
          {
            'title': 'Read assignment requirements thoroughly',
            'duration': '15 min',
            'completed': false,
          },
          {
            'title': 'Research topic and gather sources',
            'duration': '2 hours',
            'completed': false,
          },
          {
            'title': 'Create outline and structure',
            'duration': '30 min',
            'completed': false,
          },
          {
            'title': 'Write first draft',
            'duration': '3 hours',
            'completed': false,
          },
          {
            'title': 'Review and revise content',
            'duration': '1 hour',
            'completed': false,
          },
          {
            'title': 'Proofread and format',
            'duration': '30 min',
            'completed': false,
          },
          {
            'title': 'Submit assignment',
            'duration': '10 min',
            'completed': false,
          },
        ];
      case EventType.exam:
        return [
          {
            'title': 'Review syllabus and exam topics',
            'duration': '30 min',
            'completed': false,
          },
          {
            'title': 'Organize study materials and notes',
            'duration': '45 min',
            'completed': false,
          },
          {
            'title': 'Study Chapter 1-3',
            'duration': '4 hours',
            'completed': false,
          },
          {
            'title': 'Study Chapter 4-6',
            'duration': '4 hours',
            'completed': false,
          },
          {
            'title': 'Practice problems and exercises',
            'duration': '3 hours',
            'completed': false,
          },
          {
            'title': 'Review past exams/quizzes',
            'duration': '2 hours',
            'completed': false,
          },
          {
            'title': 'Create summary notes',
            'duration': '1 hour',
            'completed': false,
          },
          {
            'title': 'Final review session',
            'duration': '2 hours',
            'completed': false,
          },
        ];
      case EventType.project:
        return [
          {
            'title': 'Understand project requirements',
            'duration': '30 min',
            'completed': false,
          },
          {
            'title': 'Form team and assign roles',
            'duration': '1 hour',
            'completed': false,
          },
          {
            'title': 'Brainstorm ideas and approaches',
            'duration': '2 hours',
            'completed': false,
          },
          {
            'title': 'Create project plan and timeline',
            'duration': '1 hour',
            'completed': false,
          },
          {
            'title': 'Research and data collection',
            'duration': '5 hours',
            'completed': false,
          },
          {
            'title': 'Develop/implement solution',
            'duration': '8 hours',
            'completed': false,
          },
          {
            'title': 'Test and debug',
            'duration': '3 hours',
            'completed': false,
          },
          {
            'title': 'Prepare documentation',
            'duration': '2 hours',
            'completed': false,
          },
          {
            'title': 'Create presentation',
            'duration': '2 hours',
            'completed': false,
          },
          {
            'title': 'Practice presentation',
            'duration': '1 hour',
            'completed': false,
          },
        ];
      default:
        return [
          {
            'title': 'Review requirements',
            'duration': '20 min',
            'completed': false,
          },
          {
            'title': 'Prepare materials',
            'duration': '1 hour',
            'completed': false,
          },
          {
            'title': 'Complete main work',
            'duration': '3 hours',
            'completed': false,
          },
          {
            'title': 'Review and finalize',
            'duration': '30 min',
            'completed': false,
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as AcademicEvent?;

    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    // Auto-generate on first load
    if (_tasks.isEmpty && !_isGenerating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateTaskBreakdown(event);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Task Breakdown'),
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
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: AppConstants.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingM),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Task Breakdown',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Beat procrastination with bite-sized tasks',
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
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb,
                                  color: AppConstants.primaryColor,
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
                    if (_tasks.isNotEmpty)
                      GlassContainer(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total Tasks',
                              _tasks.length.toString(),
                              Icons.checklist,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppConstants.glassBorder,
                            ),
                            _buildStatItem(
                              'Completed',
                              _tasks
                                  .where((t) => t['completed'] as bool)
                                  .length
                                  .toString(),
                              Icons.check_circle,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppConstants.glassBorder,
                            ),
                            _buildStatItem(
                              'Est. Time',
                              _calculateTotalTime(),
                              Icons.schedule,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _isGenerating
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppConstants.primaryColor,
                            ),
                            SizedBox(height: AppConstants.spacingM),
                            Text(
                              'AI is analyzing your task...',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _tasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks yet',
                          style: TextStyle(color: AppConstants.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingL,
                        ),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(index);
                        },
                      ),
              ),
              if (_tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: PrimaryButton(
                    text: 'Add All to Google Tasks',
                    icon: Icons.add_task,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tasks will be synced to Google Tasks when API is connected!',
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
        Icon(icon, color: AppConstants.primaryColor, size: 18),
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

  Widget _buildTaskCard(int index) {
    final task = _tasks[index];
    final isCompleted = task['completed'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] as String,
                    style: TextStyle(
                      color: isCompleted
                          ? AppConstants.textSecondary
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: AppConstants.textSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task['duration'] as String,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isCompleted,
              onChanged: (value) {
                setState(() {
                  _tasks[index]['completed'] = value ?? false;
                });
              },
              activeColor: AppConstants.successColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTotalTime() {
    int totalMinutes = 0;
    for (var task in _tasks) {
      final duration = task['duration'] as String;
      if (duration.contains('hour')) {
        final hours = int.tryParse(duration.split(' ')[0]) ?? 0;
        totalMinutes += hours * 60;
      } else if (duration.contains('min')) {
        final mins = int.tryParse(duration.split(' ')[0]) ?? 0;
        totalMinutes += mins;
      }
    }

    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      return '${totalMinutes}m';
    }
  }
}
