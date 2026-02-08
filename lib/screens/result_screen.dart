import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/models/course_info.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/event_card.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/empty_state.dart';
import 'package:due/providers/app_providers.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with AutomaticKeepAliveClientMixin {
  // Sample extracted events (will be replaced with actual data from Gemini)
  List<AcademicEvent> _events = [];
  CourseInfo? _courseInfo;
  String _filterType = 'all';
  String _sortBy = 'date';
  bool _isLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      _loadData();
      _isLoaded = true;
    }
  }

  Future<void> _loadData() async {
    // Get arguments from navigation
    final args = ModalRoute.of(context)?.settings.arguments;
    final storageService = ref.read(storageServiceProvider);

    if (args is CourseInfo) {
      // Direct CourseInfo object (from upload screen)
      setState(() {
        _courseInfo = args;
        _events = List.from(_courseInfo!.events);
      });
      print('Loaded ${_events.length} events from CourseInfo argument');
    } else if (args is Map<String, dynamic>) {
      // Map with courseCode (from home screen or course list screen)
      final courseCode = args['courseCode'] as String?;

      if (courseCode != null) {
        try {
          // Load course from storage
          final course = await storageService.getCourse(courseCode);

          if (course != null) {
            setState(() {
              _courseInfo = course;
              _events = List.from(course.events);
            });
            print('Loaded ${_events.length} events for course: $courseCode');
          } else {
            // Course not found in storage
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Course "$courseCode" not found'),
                  backgroundColor: AppConstants.errorColor,
                ),
              );
              Navigator.pop(context);
            }
          }
        } catch (e) {
          print('Error loading course: $e');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading course: $e'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
            Navigator.pop(context);
          }
        }
      } else {
        // Invalid arguments
        print('Error: No courseCode provided in arguments map');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid course data'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          Navigator.pop(context);
        }
      }
    } else {
      // Unknown argument type
      print('Error: Invalid argument type provided to result screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No course data provided'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(coursesProvider.notifier).refresh();
    await _loadData();
  }

  List<AcademicEvent> get filteredEvents {
    var filtered = _events;

    // Apply filter
    if (_filterType != 'all') {
      filtered = filtered
          .where((e) => e.type.toString().split('.').last == _filterType)
          .toList();
    }

    // Apply sort
    if (_sortBy == 'date') {
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (_sortBy == 'priority') {
      filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    } else if (_sortBy == 'type') {
      filtered.sort((a, b) => a.type.index.compareTo(b.type.index));
    }

    return filtered;
  }

  int get selectedCount => _events.where((e) => e.isSelected).length;

  int get syncedCount =>
      _events.where((e) => e.isSelected && e.calendarEventId != null).length;

  int get unsyncedCount =>
      _events.where((e) => e.isSelected && e.calendarEventId == null).length;

  bool get allSelectedSynced => selectedCount > 0 && unsyncedCount == 0;

  void _syncToCalendar() async {
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one event to sync'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    if (allSelectedSynced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All selected events are already synced'),
          backgroundColor: AppConstants.successColor,
        ),
      );
      return;
    }

    // Navigate to calendar sync configuration screen with only unsynced events
    final unsyncedEvents = _events
        .where((e) => e.isSelected && e.calendarEventId == null)
        .toList();
    Navigator.pushNamed(
      context,
      '/calendar-sync',
      arguments: {'events': unsyncedEvents, 'courseInfo': _courseInfo},
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.backgroundStart,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusL),
        ),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.backgroundStart,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusL),
        ),
      ),
      builder: (context) => _buildSortSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_courseInfo == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppConstants.backgroundStart,
                AppConstants.backgroundEnd,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppConstants.primaryColor),
          ),
        ),
      );
    }

    final filtered = filteredEvents;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _courseInfo!.courseCode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _courseInfo!.courseName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter events',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortSheet,
            tooltip: 'Sort events',
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
              // Event list with banner and chips at top
              Expanded(
                child: filtered.isEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        child: Column(
                          children: [
                            // Course info banner
                            GlassContainer(
                              padding: const EdgeInsets.all(
                                AppConstants.spacingM,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.school,
                                    color: AppConstants.primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppConstants.spacingM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_courseInfo!.instructor ?? 'Instructor'} • ${_courseInfo!.semester ?? 'Semester'}',
                                          style: const TextStyle(
                                            color: AppConstants.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Review and select events to sync to your calendar',
                                          style: TextStyle(
                                            color: AppConstants.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            const EmptyState(
                              icon: Icons.filter_list_off,
                              title: 'No events match',
                              message: 'Try adjusting your filter settings',
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        itemCount:
                            filtered.length + 2, // +2 for banner and chips
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Course info banner
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppConstants.spacingM,
                              ),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(
                                  AppConstants.spacingM,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.school,
                                      color: AppConstants.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(
                                      width: AppConstants.spacingM,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_courseInfo!.instructor ?? 'Instructor'} • ${_courseInfo!.semester ?? 'Semester'}',
                                            style: const TextStyle(
                                              color: AppConstants.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Review and select events to sync to your calendar',
                                            style: TextStyle(
                                              color: AppConstants.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (index == 1) {
                            // Filter chips
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppConstants.spacingM,
                              ),
                              child: _buildFilterChips(),
                            );
                          } else {
                            // Event cards
                            final event = filtered[index - 2];
                            return EventCard(
                              event: event,
                              showCheckbox: true,
                              onSelectionChanged: (value) {
                                setState(() {
                                  event.isSelected = value ?? false;
                                });
                              },
                              onTap: () => _showEventDetails(event),
                            );
                          }
                        },
                      ),
              ),
              // Sync button
              _buildSyncButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'All',
            isSelected: _filterType == 'all',
            onTap: () => setState(() => _filterType = 'all'),
          ),
          _buildChip(
            label: 'Assignments',
            isSelected: _filterType == 'assignment',
            onTap: () => setState(() => _filterType = 'assignment'),
          ),
          _buildChip(
            label: 'Exams',
            isSelected: _filterType == 'exam',
            onTap: () => setState(() => _filterType = 'exam'),
          ),
          _buildChip(
            label: 'Quizzes',
            isSelected: _filterType == 'quiz',
            onTap: () => setState(() => _filterType = 'quiz'),
          ),
          _buildChip(
            label: 'Projects',
            isSelected: _filterType == 'project',
            onTap: () => setState(() => _filterType = 'project'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.spacingS),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppConstants.glassSurface,
        selectedColor: AppConstants.primaryColor,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppConstants.glassBorder,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSyncButton() {
    String buttonText;
    IconData buttonIcon;
    Color? buttonColor;

    if (selectedCount == 0) {
      buttonText = 'Select events to sync';
      buttonIcon = Icons.sync_disabled;
      buttonColor = null;
    } else if (allSelectedSynced) {
      buttonText = 'Synced ✓ ($selectedCount)';
      buttonIcon = Icons.check_circle;
      buttonColor = AppConstants.successColor;
    } else if (unsyncedCount > 0 && syncedCount > 0) {
      buttonText = 'Sync $unsyncedCount ($syncedCount synced)';
      buttonIcon = Icons.sync;
      buttonColor = AppConstants.successColor;
    } else {
      buttonText = 'Sync $unsyncedCount to Calendar';
      buttonIcon = Icons.sync;
      buttonColor = AppConstants.successColor;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      borderRadius: 0, // Flat bottom
      color: AppConstants.backgroundEnd.withValues(
        alpha: 0.8,
      ), // Slightly more opaque for button area
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          text: buttonText,
          icon: buttonIcon,
          onPressed: selectedCount > 0 && unsyncedCount > 0
              ? _syncToCalendar
              : null,
          backgroundColor: buttonColor,
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filter by Type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          ...EventType.values.map(
            (type) => RadioListTile<String>(
              title: Text(
                type.displayName,
                style: TextStyle(color: AppConstants.textPrimary),
              ),
              value: type.toString().split('.').last,
              groupValue: _filterType,
              activeColor: AppConstants.primaryColor,
              onChanged: (value) {
                setState(() {
                  _filterType = value ?? 'all';
                });
                Navigator.pop(context);
              },
            ),
          ),
          RadioListTile<String>(
            title: const Text(
              'Show All',
              style: TextStyle(color: AppConstants.textPrimary),
            ),
            value: 'all',
            groupValue: _filterType,
            activeColor: AppConstants.primaryColor,
            onChanged: (value) {
              setState(() {
                _filterType = 'all';
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortSheet() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          RadioListTile<String>(
            title: const Text(
              'Date (Earliest First)',
              style: TextStyle(color: AppConstants.textPrimary),
            ),
            subtitle: const Text('Sort by due date'),
            value: 'date',
            groupValue: _sortBy,
            activeColor: AppConstants.primaryColor,
            onChanged: (value) {
              setState(() {
                _sortBy = value ?? 'date';
              });
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text(
              'Priority (Highest First)',
              style: TextStyle(color: AppConstants.textPrimary),
            ),
            subtitle: const Text('Sort by event importance'),
            value: 'priority',
            groupValue: _sortBy,
            activeColor: AppConstants.primaryColor,
            onChanged: (value) {
              setState(() {
                _sortBy = value ?? 'priority';
              });
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text(
              'Type',
              style: TextStyle(color: AppConstants.textPrimary),
            ),
            subtitle: const Text('Group by event type'),
            value: 'type',
            groupValue: _sortBy,
            activeColor: AppConstants.primaryColor,
            onChanged: (value) {
              setState(() {
                _sortBy = value ?? 'type';
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEventDetails(AcademicEvent event) {
    Navigator.pushNamed(context, '/event-detail', arguments: event);
  }
}
