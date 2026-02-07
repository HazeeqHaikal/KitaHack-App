import 'package:flutter/material.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/utils/date_formatter.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/services/gemini_service.dart';
import 'package:due/services/calendar_service.dart';
import 'package:due/config/api_config.dart';

class StudyAllocatorScreen extends StatefulWidget {
  const StudyAllocatorScreen({super.key});

  @override
  State<StudyAllocatorScreen> createState() => _StudyAllocatorScreenState();
}

class _StudyAllocatorScreenState extends State<StudyAllocatorScreen> {
  final GeminiService _geminiService = GeminiService();
  final CalendarService _calendarService = CalendarService();

  final List<Map<String, dynamic>> _studySessions = [];
  bool _isAllocating = false;
  int _totalStudyHours = 6;
  String? _selectedCalendarId;
  String _statusMessage = 'Analyzing event...';

  Future<void> _allocateStudySessions(AcademicEvent event) async {
    setState(() {
      _isAllocating = true;
      _statusMessage = 'Analyzing event with AI...';
    });

    try {
      // Step 1: Use Gemini to estimate study effort
      setState(() {
        _statusMessage = 'Estimating study time needed...';
      });

      final effortEstimate = await _geminiService.estimateStudyEffort(
        event.title,
        event.type.name,
        event.description,
        int.tryParse(event.weightage?.replaceAll('%', '') ?? ''),
        event.daysUntilDue,
      );

      _totalStudyHours = effortEstimate['totalHours'] as int;
      final sessionsCount = effortEstimate['sessionsRecommended'] as int;

      print('AI recommends $_totalStudyHours hours in $sessionsCount sessions');

      // Step 2: Check if user is authenticated with Google Calendar
      if (!_calendarService.isAuthenticated) {
        setState(() {
          _statusMessage = 'Authenticating with Google Calendar...';
        });

        final account = await _calendarService.signIn();
        if (account == null) {
          throw Exception('Failed to authenticate with Google Calendar');
        }
      }

      // Step 3: Get user's calendars and use primary
      setState(() {
        _statusMessage = 'Finding your calendars...';
      });

      final calendars = await _calendarService.getCalendars();
      _selectedCalendarId = calendars
          .firstWhere(
            (cal) => cal.primary == true,
            orElse: () => calendars.first,
          )
          .id;

      print('Using calendar: $_selectedCalendarId');

      // Step 4: Find available study slots
      setState(() {
        _statusMessage = 'Scanning calendar for free time slots...';
      });

      final startDate = DateTime.now().add(const Duration(days: 1));
      final studySlots = await _calendarService.findStudySlots(
        calendarId: _selectedCalendarId!,
        totalHours: _totalStudyHours,
        sessionsCount: sessionsCount,
        startDate: startDate,
        deadlineDate: event.dueDate,
      );

      if (studySlots.isEmpty) {
        throw Exception(
          'No available time slots found. Your calendar might be too busy!',
        );
      }

      // Step 5: Format sessions for display
      setState(() {
        _isAllocating = false;
        _studySessions.clear();

        for (int i = 0; i < studySlots.length; i++) {
          final slot = studySlots[i];
          final breakdown = effortEstimate['breakdown'] as List;
          final phase = i < breakdown.length
              ? breakdown[i]['phase']
              : 'Study Session';

          _studySessions.add({
            'start': slot['start'],
            'end': slot['end'],
            'date': slot['start'] as DateTime,
            'time': _formatTimeRange(
              slot['start'] as DateTime,
              slot['end'] as DateTime,
            ),
            'duration': '${slot['duration']} hours',
            'title': '$phase ${i + 1}',
            'description': i < breakdown.length
                ? breakdown[i]['description']
                : 'Focus study session',
            'location': 'Free slot detected',
          });
        }
      });

      print('Successfully allocated ${_studySessions.length} study sessions');
    } catch (e) {
      print('Error allocating study sessions: $e');
      setState(() {
        _isAllocating = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to allocate sessions: $e'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startHour = start.hour;
    final endHour = end.hour;
    final startPeriod = startHour >= 12 ? 'PM' : 'AM';
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final displayStartHour = startHour > 12 ? startHour - 12 : startHour;
    final displayEndHour = endHour > 12 ? endHour - 12 : endHour;

    return '${displayStartHour}:00 $startPeriod - ${displayEndHour}:00 $endPeriod';
  }

  Future<void> _bookStudySessions(AcademicEvent event) async {
    if (_selectedCalendarId == null || _studySessions.isEmpty) {
      return;
    }

    setState(() {
      _isAllocating = true;
      _statusMessage = 'Booking study sessions to your calendar...';
    });

    try {
      final successCount = await _calendarService.createStudySessions(
        calendarId: _selectedCalendarId!,
        studySlots: _studySessions,
        eventTitle: event.title,
        eventId: event.id,
      );

      setState(() {
        _isAllocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Successfully booked $successCount study sessions to your calendar!',
            ),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error booking sessions: $e');
      setState(() {
        _isAllocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book sessions: $e'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
                    // Dev Mode indicator
                    if (ApiConfig.devMode)
                      GlassContainer(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        child: const Row(
                          children: [
                            Icon(Icons.science, color: Colors.orange, size: 20),
                            SizedBox(width: AppConstants.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🧪 Development Mode',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Using mock effort estimates',
                                    style: TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (ApiConfig.devMode)
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: AppConstants.secondaryColor,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                    text: 'Book All Study Sessions to Calendar',
                    icon: Icons.add_to_photos,
                    onPressed: () => _bookStudySessions(event),
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
