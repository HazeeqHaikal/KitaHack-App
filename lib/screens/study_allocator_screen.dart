import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/utils/constants.dart';
import 'package:due/utils/date_formatter.dart';
import 'package:due/widgets/glass_container.dart';
import 'package:due/widgets/custom_buttons.dart';
import 'package:due/services/gemini_service.dart';
import 'package:due/services/calendar_service.dart';
import 'package:due/services/firebase_service.dart';
import 'package:due/config/api_config.dart';

class StudyAllocatorScreen extends StatefulWidget {
  const StudyAllocatorScreen({super.key});

  @override
  State<StudyAllocatorScreen> createState() => _StudyAllocatorScreenState();
}

class _StudyAllocatorScreenState extends State<StudyAllocatorScreen> {
  final GeminiService _geminiService = GeminiService();
  final CalendarService _calendarService = CalendarService();

  // Optional resource bytes forwarded from EventDetailScreen
  Uint8List? _contextBytes;
  String? _contextExtension;
  bool _argsLoaded = false;

  final List<Map<String, dynamic>> _studySessions = [];
  bool _isAllocating = false;
  bool _isPastDue = false;
  bool _isCached = false;
  int _totalStudyHours = 6;
  String? _selectedCalendarId;
  String _statusMessage = 'Analyzing event...';

  // ── Firestore cache helpers ──────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>>? _cacheDoc(String eventId) {
    final uid = FirebaseService().currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('study_allocations')
        .doc(eventId);
  }

  /// Returns true and populates state if a valid cache exists.
  Future<bool> _loadFromFirestore(String eventId) async {
    try {
      final doc = _cacheDoc(eventId);
      if (doc == null) return false;
      final snap = await doc.get();
      if (!snap.exists) return false;
      final data = snap.data()!;
      final raw = data['sessions'] as List<dynamic>? ?? [];
      if (raw.isEmpty) return false;

      final sessions = raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        // Timestamps are stored as ISO strings
        m['start'] = DateTime.parse(m['start'] as String);
        m['end'] = DateTime.parse(m['end'] as String);
        m['date'] = DateTime.parse(m['date'] as String);
        return m;
      }).toList();

      setState(() {
        _studySessions
          ..clear()
          ..addAll(sessions);
        _totalStudyHours = (data['totalHours'] as num?)?.toInt() ?? 6;
        _isCached = true;
      });
      print('Loaded ${sessions.length} study sessions from Firestore cache');
      return true;
    } catch (e) {
      print('Study allocator cache load error (non-critical): $e');
      return false;
    }
  }

  Future<void> _saveToFirestore(String eventId) async {
    try {
      final doc = _cacheDoc(eventId);
      if (doc == null) return;

      // Serialize DateTimes to ISO strings for Firestore
      final serialized = _studySessions.map((s) {
        final m = Map<String, dynamic>.from(s);
        m['start'] = (s['start'] as DateTime).toIso8601String();
        m['end'] = (s['end'] as DateTime).toIso8601String();
        m['date'] = (s['date'] as DateTime).toIso8601String();
        return m;
      }).toList();

      await doc.set({
        'eventId': eventId,
        'totalHours': _totalStudyHours,
        'sessions': serialized,
        'cachedAt': FieldValue.serverTimestamp(),
      });
      print('Saved ${_studySessions.length} study sessions to Firestore');
    } catch (e) {
      print('Study allocator cache save error (non-critical): $e');
    }
  }

  Future<void> _allocateStudySessions(
    AcademicEvent event, {
    bool forceRefresh = false,
  }) async {
    // Try cache first unless user wants a fresh allocation
    if (!forceRefresh) {
      final loaded = await _loadFromFirestore(event.id);
      if (loaded) return;
    }
    setState(() {
      _isAllocating = true;
      _isCached = false;
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
        contextBytes: _contextBytes,
        contextExtension: _contextExtension,
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

      // Warn the user if the event due date is already past
      final isPastDue = !event.dueDate.isAfter(startDate);
      if (isPastDue) {
        setState(() => _isPastDue = true);
      }

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

      // Save to Firestore so other devices (and next open) skip re-allocation
      await _saveToFirestore(event.id);
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final AcademicEvent? event;
    if (args is AcademicEvent) {
      event = args;
    } else if (args is Map) {
      event = args['event'] as AcademicEvent?;
      if (!_argsLoaded) {
        _argsLoaded = true;
        _contextBytes = args['contextBytes'] as Uint8List?;
        _contextExtension = args['contextExtension'] as String?;
      }
    } else {
      event = null;
    }

    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    // Auto-allocate on first load
    if (_studySessions.isEmpty && !_isAllocating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _allocateStudySessions(event!);
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
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GlassContainer(
                              padding: const EdgeInsets.all(
                                AppConstants.spacingM,
                              ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month,
                                          color: AppConstants.secondaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppConstants.spacingM,
                                      ),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                color:
                                                    AppConstants.textSecondary,
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
                                      color: AppConstants.secondaryColor
                                          .withOpacity(0.1),
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
                                padding: const EdgeInsets.all(
                                  AppConstants.spacingM,
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.science,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    SizedBox(width: AppConstants.spacingM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                padding: const EdgeInsets.all(
                                  AppConstants.spacingM,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
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
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      AppConstants.spacingS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isCached
                                          ? Colors.green.withOpacity(0.1)
                                          : AppConstants.secondaryColor
                                                .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isCached
                                            ? Colors.green.withOpacity(0.4)
                                            : AppConstants.secondaryColor
                                                  .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isCached
                                              ? Icons.cloud_done
                                              : Icons.info_outline,
                                          color: _isCached
                                              ? Colors.green
                                              : AppConstants.secondaryColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _isCached
                                                ? 'Loaded from cloud cache'
                                                : 'Free slots detected using Google Calendar API',
                                            style: TextStyle(
                                              color: _isCached
                                                  ? Colors.green
                                                  : AppConstants.secondaryColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_studySessions.isNotEmpty) ...[
                                  const SizedBox(width: AppConstants.spacingS),
                                  Tooltip(
                                    message: 'Re-allocate (uses API credits)',
                                    child: IconButton(
                                      onPressed: _isAllocating
                                          ? null
                                          : () => _allocateStudySessions(
                                              event!,
                                              forceRefresh: true,
                                            ),
                                      icon: _isAllocating
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    AppConstants.secondaryColor,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.refresh,
                                              color:
                                                  AppConstants.secondaryColor,
                                            ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppConstants
                                            .secondaryColor
                                            .withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: AppConstants.secondaryColor
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isAllocating)
                      SliverFillRemaining(
                        child: Center(
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
                        ),
                      )
                    else if (_studySessions.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No sessions yet',
                            style: TextStyle(color: AppConstants.textSecondary),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingL,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (_isPastDue && index == 0) {
                                return _buildPastDueBanner();
                              }
                              return _buildSessionCard(
                                index - (_isPastDue ? 1 : 0),
                              );
                            },
                            childCount:
                                _studySessions.length + (_isPastDue ? 1 : 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_studySessions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: PrimaryButton(
                    text: 'Book All Study Sessions to Calendar',
                    icon: Icons.add_to_photos,
                    onPressed: () => _bookStudySessions(event!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastDueBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This event is past its due date. Showing the next 14 days of free slots instead.',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        ],
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
