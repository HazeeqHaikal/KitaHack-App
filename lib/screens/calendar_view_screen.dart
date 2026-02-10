import 'package:flutter/material.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/services/mock_data_service.dart';
import 'package:due/utils/constants.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/event_card.dart';
import 'package:due/widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';

/// A calendar view screen that displays all academic events in a calendar format
/// Similar to Google Calendar, showing events by date
class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  List<AcademicEvent> _allEvents = [];
  CalendarViewMode _viewMode = CalendarViewMode.month;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    // Load all events from mock data or storage
    setState(() {
      _allEvents = MockDataService.getAllUpcomingEvents();
    });
  }

  List<AcademicEvent> _getEventsForDate(DateTime date) {
    return _allEvents.where((event) {
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
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
          child: Column(
            children: [
              // Month/Year navigation (only for month/week view)
              if (_viewMode != CalendarViewMode.agenda) _buildMonthNavigation(),
              if (_viewMode != CalendarViewMode.agenda)
                const SizedBox(height: AppConstants.spacingM),

              // Calendar grid, week view, or agenda list
              Expanded(
                child: _viewMode == CalendarViewMode.month
                    ? _buildMonthView()
                    : _viewMode == CalendarViewMode.week
                    ? _buildWeekView()
                    : _buildAgendaView(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => SizedBox(
                      width: 50,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spacingS),

            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.75, // Make cells taller to fit event names
              ),
              itemCount: 42, // 6 weeks max
              itemBuilder: (context, index) {
                if (index < firstWeekday ||
                    index >= firstWeekday + daysInMonth) {
                  return const SizedBox.shrink();
                }

                final day = index - firstWeekday + 1;
                final date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  day,
                );
                final events = _getEventsForDate(date);
                final isSelected =
                    _selectedDate.year == date.year &&
                    _selectedDate.month == date.month &&
                    _selectedDate.day == date.day;
                final isToday =
                    DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;

                return _buildDayCell(date, events, isSelected, isToday);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    List<AcademicEvent> events,
    bool isSelected,
    bool isToday,
  ) {
    return GestureDetector(
      onTap: () {
        if (events.isNotEmpty) {
          Navigator.pushNamed(context, '/event-detail', arguments: events[0]);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.3)
              : Colors.transparent,
          border: isToday
              ? Border.all(color: AppConstants.primaryColor, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day number
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected || isToday
                    ? AppConstants.textPrimary
                    : AppConstants.textSecondary,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            // Event names
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length > 3 ? 3 : events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _getEventColor(event.type).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            // "More" indicator if there are more than 3 events
            if (events.length > 3)
              Text(
                '+${events.length - 3} more',
                style: TextStyle(
                  color: AppConstants.textSecondary,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
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

  Widget _buildWeekView() {
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );

    return SingleChildScrollView(
      child: GlassContainer(
        margin: const EdgeInsets.all(AppConstants.spacingM),
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Column(
          children: [
            // Week header with dates
            SizedBox(
              height: 60,
              child: Row(
                children: List.generate(7, (index) {
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
                              ? AppConstants.primaryColor.withOpacity(0.3)
                              : Colors.transparent,
                          border: isToday
                              ? Border.all(
                                  color: AppConstants.primaryColor,
                                  width: 2,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isSelected || isToday
                                    ? AppConstants.textPrimary
                                    : AppConstants.textSecondary,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            // Events for each day in the week
            ...List.generate(7, (index) {
              final date = weekStart.add(Duration(days: index));
              final events = _getEventsForDate(date);

              if (events.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.spacingS,
                    ),
                    child: Text(
                      DateFormat('EEEE, MMM d').format(date),
                      style: const TextStyle(
                        color: AppConstants.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...events.map(
                    (event) => Container(
                      margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingS,
                      ),
                      padding: const EdgeInsets.all(AppConstants.spacingS),
                      decoration: BoxDecoration(
                        color: _getEventColor(event.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: _getEventColor(event.type),
                            width: 4,
                          ),
                        ),
                      ),
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
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            color: AppConstants.textSecondary,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/event-detail',
                                arguments: event,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaView() {
    final upcomingEvents =
        _allEvents
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
        final isToday =
            DateTime.now().year == date.year &&
            DateTime.now().month == date.month &&
            DateTime.now().day == date.day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingS,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppConstants.primaryColor
                          : AppConstants.glassSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : AppConstants.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : AppConstants.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(date),
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMMM d, yyyy').format(date),
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
            // Events for this day
            ...eventsForDay.map(
              (event) => EventCard(
                event: event,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/event-detail',
                    arguments: event,
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
          ],
        );
      },
    );
  }
}

enum CalendarViewMode { month, week, agenda }
