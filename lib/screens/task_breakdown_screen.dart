import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/models/task.dart';
import 'package:due/services/gemini_service.dart';
import 'package:due/config/api_config.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/providers/app_providers.dart';

class TaskBreakdownScreen extends ConsumerStatefulWidget {
  const TaskBreakdownScreen({super.key});

  @override
  ConsumerState<TaskBreakdownScreen> createState() =>
      _TaskBreakdownScreenState();
}

class _TaskBreakdownScreenState extends ConsumerState<TaskBreakdownScreen> {
  final GeminiService _geminiService = GeminiService();
  List<Task> _tasks = [];
  bool _isGenerating = false;
  File? _contextFile;
  String? _errorMessage;
  bool _hasGenerated = false;

  Future<void> _generateTaskBreakdown(AcademicEvent event) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Call Gemini API with optional context file
      final tasks = await _geminiService.generateTaskBreakdown(
        event,
        contextFile: _contextFile,
      );

      setState(() {
        _tasks = tasks;
        _isGenerating = false;
        _hasGenerated = true;
      });

      // Save tasks to event and update storage
      event.generatedTasks = tasks;
      await _saveTasksToEvent(event);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Generated ${tasks.length} tasks ${_contextFile != null ? 'with enhanced context' : 'successfully'}',
            ),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveTasksToEvent(AcademicEvent event) async {
    try {
      final storageService = ref.read(storageServiceProvider);

      // Get the course that contains this event
      final courses = await storageService.getAllCourses();
      for (var course in courses) {
        final eventIndex = course.events.indexWhere((e) => e.id == event.id);
        if (eventIndex != -1) {
          // Update the event with generated tasks
          course.events[eventIndex].generatedTasks = event.generatedTasks;
          // Save the updated course (automatically syncs to Firebase Firestore)
          await storageService.saveCourse(course);
          // Refresh courses provider
          await ref.read(coursesProvider.notifier).refresh();
          print('✓ Tasks saved to Firebase for event: ${event.title}');
          break;
        }
      }
    } catch (e) {
      print('Error saving tasks to event: $e');
    }
  }

  Future<void> _pickContextFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        final maxSize = 10 * 1024 * 1024; // 10MB

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File too large. Maximum size is 10MB.'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _contextFile = file;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📄 Added: ${result.files.single.name}'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _removeContextFile() {
    setState(() {
      _contextFile = null;
    });
  }

  void _toggleTaskCompletion(int index, AcademicEvent event) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
    });

    // Save updated tasks to event
    event.generatedTasks = _tasks;
    _saveTasksToEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as AcademicEvent?;

    if (event == null) {
      return _EventSelectionScreen(
        title: 'Task Breakdown',
        subtitle: 'Select an event to break down into tasks',
        routeName: '/task-breakdown',
      );
    }

    // Load existing tasks if they exist, otherwise auto-generate on first load
    if (!_hasGenerated && !_isGenerating && _tasks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Sync from Firebase first to ensure we have the latest data
        final storageService = ref.read(storageServiceProvider);
        await storageService.syncFromCloud();

        // Reload the event with latest data from storage
        final courses = await storageService.getAllCourses();
        AcademicEvent? latestEvent;
        for (var course in courses) {
          final foundEvent = course.events.firstWhere(
            (e) => e.id == event.id,
            orElse: () => event,
          );
          if (foundEvent.id == event.id) {
            latestEvent = foundEvent;
            break;
          }
        }

        final eventToUse = latestEvent ?? event;

        if (eventToUse.generatedTasks != null &&
            eventToUse.generatedTasks!.isNotEmpty) {
          // Load existing tasks from Firebase
          setState(() {
            _tasks = List.from(eventToUse.generatedTasks!);
            _hasGenerated = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Loaded ${_tasks.length} tasks from cloud'),
                backgroundColor: AppConstants.successColor,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Generate new tasks
          _generateTaskBreakdown(eventToUse);
        }
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Task Breakdown'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          if (_contextFile != null || _hasGenerated)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerate Tasks',
              onPressed: _isGenerating
                  ? null
                  : () {
                      _generateTaskBreakdown(event);
                    },
            ),
        ],
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
              // Task List with all content
              Expanded(
                child: _isGenerating
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppConstants.primaryColor,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            const Text(
                              'AI is analyzing your task...',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingS),
                            Text(
                              _contextFile != null
                                  ? 'Using enhanced context from uploaded file'
                                  : 'Using event details',
                              style: TextStyle(
                                color: AppConstants.textSecondary.withOpacity(
                                  0.7,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.spacingL),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppConstants.errorColor,
                                size: 48,
                              ),
                              const SizedBox(height: AppConstants.spacingM),
                              Text(
                                'Error: $_errorMessage',
                                style: const TextStyle(
                                  color: AppConstants.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppConstants.spacingM),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _generateTaskBreakdown(event);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _tasks.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        child: Column(
                          children: [
                            _buildHeaderCard(event),
                            if (ApiConfig.devMode) ...[
                              const SizedBox(height: AppConstants.spacingM),
                              _buildDevModeBadge(),
                            ],
                            if (!_isGenerating) ...[
                              const SizedBox(height: AppConstants.spacingM),
                              _buildUploadSection(event),
                            ],
                            const SizedBox(height: AppConstants.spacingXL),
                            const Text(
                              'No tasks yet',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        itemCount:
                            _tasks.length +
                            1 + // Header
                            (ApiConfig.devMode ? 1 : 0) +
                            (!_isGenerating ? 1 : 0) +
                            (_tasks.isNotEmpty ? 1 : 0), // Stats
                        itemBuilder: (context, index) {
                          int currentIndex = 0;

                          // Header Card
                          if (index == currentIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppConstants.spacingM,
                              ),
                              child: _buildHeaderCard(event),
                            );
                          }
                          currentIndex++;

                          // Dev Mode Badge
                          if (ApiConfig.devMode) {
                            if (index == currentIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppConstants.spacingM,
                                ),
                                child: _buildDevModeBadge(),
                              );
                            }
                            currentIndex++;
                          }

                          // Upload Section
                          if (!_isGenerating) {
                            if (index == currentIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppConstants.spacingM,
                                ),
                                child: _buildUploadSection(event),
                              );
                            }
                            currentIndex++;
                          }

                          // Stats Card
                          if (_tasks.isNotEmpty) {
                            if (index == currentIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppConstants.spacingM,
                                ),
                                child: _buildStatsCard(),
                              );
                            }
                            currentIndex++;
                          }

                          // Task cards
                          final taskIndex = index - currentIndex;
                          if (taskIndex >= 0 && taskIndex < _tasks.length) {
                            return _buildTaskCard(taskIndex, event);
                          }

                          return const SizedBox.shrink();
                        },
                      ),
              ),

              // Progress Indicator
              if (_tasks.isNotEmpty && !_isGenerating)
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  color: AppConstants.glassSurface.withOpacity(0.5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: AppConstants.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Progress: ${_tasks.where((t) => t.isCompleted).length}/${_tasks.length} tasks',
                        style: const TextStyle(
                          color: AppConstants.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _tasks.isEmpty
                              ? 0
                              : _tasks.where((t) => t.isCompleted).length /
                                    _tasks.length,
                          backgroundColor: AppConstants.glassBorder.withOpacity(
                            0.3,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppConstants.successColor,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildTaskCard(int index, AcademicEvent event) {
    final task = _tasks[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppConstants.successColor.withOpacity(0.2)
                    : AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: task.isCompleted
                    ? const Icon(
                        Icons.check,
                        color: AppConstants.successColor,
                        size: 18,
                      )
                    : Text(
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
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppConstants.textSecondary
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
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
                        task.duration,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        color: AppConstants.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                _toggleTaskCompletion(index, event);
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
      final duration = task.duration;
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

  Widget _buildHeaderCard(AcademicEvent event) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.2),
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
            padding: const EdgeInsets.all(AppConstants.spacingS),
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
    );
  }

  Widget _buildDevModeBadge() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.science, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dev Mode: Using mock task breakdown',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(AcademicEvent event) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.upload_file,
                color: AppConstants.secondaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Want Better Results?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_contextFile != null)
                const Icon(
                  Icons.check_circle,
                  color: AppConstants.successColor,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload assignment details for more specific task breakdown',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppConstants.spacingM),
          if (_contextFile == null)
            OutlinedButton.icon(
              onPressed: _pickContextFile,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Upload Instructions (Optional)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.secondaryColor,
                side: const BorderSide(color: AppConstants.secondaryColor),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    color: AppConstants.successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _contextFile!.path.split('/').last,
                      style: const TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    color: AppConstants.textSecondary,
                    onPressed: _removeContextFile,
                  ),
                ],
              ),
            ),
          if (_contextFile != null) ...[
            const SizedBox(height: AppConstants.spacingS),
            ElevatedButton.icon(
              onPressed: () {
                _generateTaskBreakdown(event);
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Regenerate with Context'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.secondaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Tasks',
            _tasks.length.toString(),
            Icons.checklist,
          ),
          Container(width: 1, height: 30, color: AppConstants.glassBorder),
          _buildStatItem(
            'Completed',
            _tasks.where((t) => t.isCompleted).length.toString(),
            Icons.check_circle,
          ),
          Container(width: 1, height: 30, color: AppConstants.glassBorder),
          _buildStatItem('Est. Time', _calculateTotalTime(), Icons.schedule),
        ],
      ),
    );
  }
}

// Event Selection Screen Widget
class _EventSelectionScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String routeName;

  const _EventSelectionScreen({
    required this.title,
    required this.subtitle,
    required this.routeName,
  });

  @override
  ConsumerState<_EventSelectionScreen> createState() =>
      _EventSelectionScreenState();
}

class _EventSelectionScreenState extends ConsumerState<_EventSelectionScreen> {
  List<AcademicEvent> _allEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final storageService = ref.read(storageServiceProvider);
      final courses = await storageService.getAllCourses();

      final List<AcademicEvent> events = [];
      for (var course in courses) {
        events.addAll(course.events);
      }

      // Sort by date (upcoming first)
      events.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title),
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                )
              : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppConstants.errorColor,
                        size: 64,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'Error loading events',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _allEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy,
                        color: AppConstants.textSecondary,
                        size: 64,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      const Text(
                        'No Events Found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingS),
                      const Text(
                        'Upload a syllabus to get started',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/upload');
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Syllabus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingL,
                            vertical: AppConstants.spacingM,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          Text(
                            '${_allEvents.length} ${_allEvents.length == 1 ? 'event' : 'events'} available',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingL,
                        ),
                        itemCount: _allEvents.length,
                        itemBuilder: (context, index) {
                          final event = _allEvents[index];
                          return _buildEventCard(event);
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEventCard(AcademicEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(
          context,
          widget.routeName,
          arguments: event,
        );
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getEventColor(event).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventIcon(event),
                  color: _getEventColor(event),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.type.displayName,
                      style: TextStyle(
                        color: _getEventColor(event),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppConstants.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.dueDate),
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (event.weightage != null) ...[
                          const SizedBox(width: AppConstants.spacingM),
                          Icon(
                            Icons.show_chart,
                            size: 12,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.weightage}%',
                            style: const TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppConstants.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor(AcademicEvent event) {
    switch (event.priority) {
      case EventPriority.high:
        return AppConstants.errorColor;
      case EventPriority.medium:
        return AppConstants.warningColor;
      default:
        return AppConstants.successColor;
    }
  }

  IconData _getEventIcon(AcademicEvent event) {
    final type = event.type.name.toLowerCase();
    if (type.contains('exam')) return Icons.edit_note;
    if (type.contains('assignment')) return Icons.assignment;
    if (type.contains('quiz')) return Icons.quiz;
    if (type.contains('project')) return Icons.work;
    if (type.contains('lab')) return Icons.science;
    return Icons.event;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
