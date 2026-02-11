import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/bottom_nav_bar.dart';
import 'package:due/providers/app_providers.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

/// A calendar view screen that displays all academic events in a calendar format
/// Material Design 3 style similar to Google Calendar
class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<AcademicEvent> _allEvents = [];
  CalendarViewMode _viewMode = CalendarViewMode.month;
  late PageController _monthPageController;
  late PageController _weekPageController;
  final int _initialPage = 500; // Start in the middle for infinite scroll

  @override
  void initState() {
    super.initState();
    _monthPageController = PageController(initialPage: _initialPage);
    _weekPageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  /// Extract all events from courses loaded via provider
  List<AcademicEvent> _getAllEventsFromCourses() {
    final coursesAsync = ref.watch(coursesProvider);

    return coursesAsync.when(
      data: (courses) {
        final allEvents = <AcademicEvent>[];
        for (var course in courses) {
          allEvents.addAll(course.events);
        }
        allEvents.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return allEvents;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  DateTime _getMonthForPage(int page) {
    final offset = page - _initialPage;
    return DateTime(DateTime.now().year, DateTime.now().month + offset);
  }

  DateTime _getWeekStartForPage(int page) {
    final offset = page - _initialPage;
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday % 7));
    return weekStart.add(Duration(days: offset * 7));
  }

  List<AcademicEvent> _getEventsForDate(DateTime date) {
    final allEvents = _getAllEventsFromCourses();
    return allEvents.where((event) {
      return event.dueDate.year == date.year &&
          event.dueDate.month == date.month &&
          event.dueDate.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _viewMode == CalendarViewMode.month
              ? DateFormat('MMMM yyyy').format(_focusedMonth)
              : _viewMode == CalendarViewMode.week
              ? 'Week View'
              : 'Schedule',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          // View mode toggle
          IconButton(
            icon: Icon(
              _viewMode == CalendarViewMode.month
                  ? Icons.view_agenda_rounded
                  : _viewMode == CalendarViewMode.week
                  ? Icons.calendar_month_rounded
                  : Icons.calendar_view_month_rounded,
            ),
            onPressed: () {
              setState(() {
                if (_viewMode == CalendarViewMode.month) {
                  _viewMode = CalendarViewMode.agenda;
                } else if (_viewMode == CalendarViewMode.agenda) {
                  _viewMode = CalendarViewMode.week;
                } else {
                  _viewMode = CalendarViewMode.month;
                }
              });
            },
            tooltip: _viewMode == CalendarViewMode.month
                ? 'Agenda View'
                : _viewMode == CalendarViewMode.week
                ? 'Month View'
                : 'Week View',
          ),
          // Today button
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedMonth = DateTime.now();
                if (_viewMode == CalendarViewMode.month) {
                  _monthPageController.jumpToPage(_initialPage);
                } else if (_viewMode == CalendarViewMode.week) {
                  _weekPageController.jumpToPage(_initialPage);
                }
              });
            },
            tooltip: 'Today',
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
          child: _viewMode == CalendarViewMode.month
              ? _buildMonthViewWithSwipe()
              : _viewMode == CalendarViewMode.week
              ? _buildWeekViewWithSwipe()
              : _buildAgendaView(),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildMonthViewWithSwipe() {
    return PageView.builder(
      controller: _monthPageController,
      onPageChanged: (page) {
        setState(() {
          _focusedMonth = _getMonthForPage(page);
        });
      },
      itemBuilder: (context, page) {
        final month = _getMonthForPage(page);
        return _buildMonthView(month);
      },
    );
  }

  Widget _buildMonthView(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return SingleChildScrollView(
      child: GlassContainer(
        margin: const EdgeInsets.all(AppConstants.spacingM),
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Column(
          children: [
            // Weekday headers
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spacingS),

            // Calendar grid - Dense layout
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 0.8,
              ),
              itemCount: 42, // 6 weeks max
              itemBuilder: (context, index) {
                if (index < firstWeekday ||
                    index >= firstWeekday + daysInMonth) {
                  return const SizedBox.shrink();
                }

                final day = index - firstWeekday + 1;
                final date = DateTime(month.year, month.month, day);
                final events = _getEventsForDate(date);
                final isSelected =
                    _selectedDate.year == date.year &&
                    _selectedDate.month == date.month &&
                    _selectedDate.day == date.day;
                final isToday =
                    DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;

                return _buildDenseMonthCell(date, events, isSelected, isToday);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenseMonthCell(
    DateTime date,
    List<AcademicEvent> events,
    bool isSelected,
    bool isToday,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        if (events.isNotEmpty) {
          Navigator.pushNamed(context, '/event-detail', arguments: events[0]);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Day number at top center
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isToday ? AppConstants.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday
                        ? Colors.white
                        : (isSelected
                              ? AppConstants.textPrimary
                              : AppConstants.textSecondary),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Event chips (pills)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: math.min(events.length, 3),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8), // Pill shape
                        border: Border.all(
                          color: _getEventColor(event.type),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _getEventColor(event.type),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // "More" indicator
            if (events.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '+${events.length - 3}',
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.assignment:
        return AppConstants.primaryColor;
      case EventType.quiz:
        return AppConstants.warningColor;
      case EventType.exam:
        return AppConstants.errorColor;
      case EventType.lab:
        return Colors.purple;
      case EventType.presentation:
        return Colors.orange;
      case EventType.project:
        return Colors.indigo;
      case EventType.other:
        return AppConstants.textSecondary;
    }
  }

  Widget _buildWeekViewWithSwipe() {
    return PageView.builder(
      controller: _weekPageController,
      onPageChanged: (page) {
        setState(() {
          final weekStart = _getWeekStartForPage(page);
          _selectedDate = weekStart;
        });
      },
      itemBuilder: (context, page) {
        final weekStart = _getWeekStartForPage(page);
        return _buildWeekView(weekStart);
      },
    );
  }

  Widget _buildWeekView(DateTime weekStart) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    return GlassContainer(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      child: Column(
        children: [
          // Week header with dates
          _buildWeekHeader(weekStart),
          const SizedBox(height: AppConstants.spacingS),
          // Time grid
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 24 * 60.0, // 24 hours * 60 pixels per hour
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time labels column
                    _buildTimeLabels(),
                    // Days grid
                    Expanded(
                      child: Stack(
                        children: [
                          // Grid lines
                          _buildGridLines(),
                          // Current time indicator
                          if (_isCurrentWeek(weekStart))
                            _buildCurrentTimeIndicator(
                              currentMinutes,
                              weekStart,
                            ),
                          // Events positioned on grid
                          _buildWeekEvents(weekStart),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader(DateTime weekStart) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Spacer for time column
          const SizedBox(width: 50),
          // Day headers
          ...List.generate(7, (index) {
            final date = weekStart.add(Duration(days: index));
            final isSelected =
                _selectedDate.year == date.year &&
                _selectedDate.month == date.month &&
                _selectedDate.day == date.day;
            final isToday =
                DateTime.now().year == date.year &&
                DateTime.now().month == date.month &&
                DateTime.now().day == date.day;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppConstants.primaryColor
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isToday
                                  ? Colors.white
                                  : (isSelected
                                        ? AppConstants.textPrimary
                                        : AppConstants.textSecondary),
                              fontWeight: isToday || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeLabels() {
    return SizedBox(
      width: 50,
      child: Column(
        children: List.generate(24, (hour) {
          return SizedBox(
            height: 60,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Text(
                  hour == 0
                      ? '12 AM'
                      : hour < 12
                      ? '$hour AM'
                      : hour == 12
                      ? '12 PM'
                      : '${hour - 12} PM',
                  style: const TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGridLines() {
    return Column(
      children: List.generate(24, (hour) {
        return Container(
          height: 60,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppConstants.glassBorder, width: 0.5),
            ),
          ),
        );
      }),
    );
  }

  bool _isCurrentWeek(DateTime weekStart) {
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 7));
    return now.isAfter(weekStart) && now.isBefore(weekEnd);
  }

  Widget _buildCurrentTimeIndicator(int currentMinutes, DateTime weekStart) {
    final topPosition = currentMinutes.toDouble();

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Red circle
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          // Red line
          Expanded(child: Container(height: 2, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildWeekEvents(DateTime weekStart) {
    return Row(
      children: List.generate(7, (dayIndex) {
        final date = weekStart.add(Duration(days: dayIndex));
        final eventsForDay = _getEventsForDate(date);

        return Expanded(
          child: Stack(
            children: eventsForDay.map((event) {
              // Position event based on time (assuming all-day events at 9 AM)
              final eventHour =
                  9; // Default time for events without specific time
              final eventMinutes = eventHour * 60;
              final eventDuration = 60; // 1 hour default duration

              return Positioned(
                top: eventMinutes.toDouble(),
                left: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/event-detail',
                      arguments: event,
                    );
                  },
                  child: Container(
                    height: eventDuration.toDouble(),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getEventColor(event.type).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border(
                        left: BorderSide(
                          color: _getEventColor(event.type),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      event.title,
                      style: TextStyle(
                        color: _getEventColor(event.type),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildAgendaView() {
    final allEvents = _getAllEventsFromCourses();
    final upcomingEvents =
        allEvents
            .where((event) => event.dueDate.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (upcomingEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 64,
              color: AppConstants.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'No upcoming events',
              style: TextStyle(color: AppConstants.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group events by date
    final Map<String, List<AcademicEvent>> groupedEvents = {};
    for (var event in upcomingEvents) {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.dueDate);
      if (!groupedEvents.containsKey(dateKey)) {
        groupedEvents[dateKey] = [];
      }
      groupedEvents[dateKey]!.add(event);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: groupedEvents.length,
      itemBuilder: (context, index) {
        final dateKey = groupedEvents.keys.elementAt(index);
        final eventsForDay = groupedEvents[dateKey]!;
        final date = DateTime.parse(dateKey);
        final now = DateTime.now();
        final isToday =
            now.year == date.year &&
            now.month == date.month &&
            now.day == date.day;
        final isTomorrow =
            now.add(const Duration(days: 1)).year == date.year &&
            now.add(const Duration(days: 1)).month == date.month &&
            now.add(const Duration(days: 1)).day == date.day;

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Date graphic
              Column(
                children: [
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppConstants.primaryColor
                          : AppConstants.glassSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMM').format(date).toUpperCase(),
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : AppConstants.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : AppConstants.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: TextStyle(
                            color: isToday
                                ? Colors.white.withOpacity(0.9)
                                : AppConstants.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday || isTomorrow)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        isToday ? 'TODAY' : 'TOMORROW',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppConstants.spacingM),
              // Right: Events stack
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: eventsForDay.map((event) {
                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingS,
                      ),
                      padding: const EdgeInsets.all(AppConstants.spacingS),
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: _getEventColor(event.type),
                            width: 4,
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/event-detail',
                            arguments: event,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        color: AppConstants.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getEventColor(
                                              event.type,
                                            ).withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            event.type
                                                .toString()
                                                .split('.')
                                                .last
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _getEventColor(event.type),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        if (event.location != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            event.location!,
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
                              Icon(
                                Icons.chevron_right,
                                color: AppConstants.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum CalendarViewMode { month, week, agenda }
