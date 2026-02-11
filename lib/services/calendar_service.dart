import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:due/models/academic_event.dart';
import 'package:due/services/firebase_service.dart';

/// Service for Google Calendar API integration
/// Handles authentication and event synchronization
/// Reuses Google Sign-In from FirebaseService
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  calendar.CalendarApi? _calendarApi;

  /// Initialize Calendar service (no longer needs separate initialization)
  void initialize() {
    print('CalendarService initialized');
  }

  /// Check if user is authenticated with Google
  bool get isAuthenticated {
    final googleSignIn = FirebaseService().googleSignIn;
    return googleSignIn?.currentUser != null;
  }

  /// Get current user from Firebase's Google Sign-In
  GoogleSignInAccount? get currentUser {
    return FirebaseService().googleSignIn?.currentUser;
  }

  /// Sign in automatically reuses Firebase Google Sign-In
  /// No need to sign in again if already authenticated
  Future<GoogleSignInAccount?> signIn() async {
    final googleSignIn = FirebaseService().googleSignIn;
    if (googleSignIn == null) {
      throw Exception('Firebase not initialized');
    }

    try {
      // Check if already signed in
      final currentUser = googleSignIn.currentUser;
      if (currentUser != null) {
        print('Already signed in: ${currentUser.email}');
        await _initializeCalendarApi();
        return currentUser;
      }

      // Sign in if not already authenticated
      print('Attempting Google Sign-In for calendar...');
      final account = await googleSignIn.signIn();

      if (account != null) {
        print('Sign-in successful: ${account.email}');
        await _initializeCalendarApi();
      }

      return account;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  /// Sign out (delegates to FirebaseService)
  Future<void> signOut() async {
    await FirebaseService().signOut();
    _calendarApi = null;
    print('Signed out from calendar service');
  }

  /// Initialize Calendar API after authentication
  Future<void> _initializeCalendarApi() async {
    try {
      final currentUser = FirebaseService().googleSignIn?.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final authHeaders = await currentUser.authHeaders;

      final authenticatedClient = _GoogleAuthClient(authHeaders);
      _calendarApi = calendar.CalendarApi(authenticatedClient);
      print('Calendar API initialized');
    } catch (e) {
      print('Error initializing Calendar API: $e');
      rethrow;
    }
  }

  /// Get list of user's calendars
  Future<List<calendar.CalendarListEntry>> getCalendars() async {
    if (_calendarApi == null) {
      // Try to initialize if authenticated
      if (isAuthenticated) {
        await _initializeCalendarApi();
      } else {
        throw Exception('Not authenticated. Please sign in first.');
      }
    }

    try {
      print('Fetching user calendars...');
      final calendarList = await _calendarApi!.calendarList.list();
      final calendars = calendarList.items ?? [];
      print('Found ${calendars.length} calendars');
      return calendars;
    } catch (e) {
      print('Error fetching calendars: $e');
      rethrow;
    }
  }

  /// Create a new Google Calendar
  ///
  /// [calendarName] - Name for the new calendar
  /// [description] - Optional description
  /// [colorId] - Optional color ID (1-24)
  /// Returns the created calendar entry with its ID
  Future<calendar.CalendarListEntry> createCalendar(
    String calendarName, {
    String? description,
    String? colorId,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Not authenticated. Please sign in first.');
    }

    try {
      print('Creating new calendar: $calendarName');

      // Create calendar object
      final newCalendar = calendar.Calendar()
        ..summary = calendarName
        ..description = description ?? 'Created by Due App'
        ..timeZone = 'Asia/Kuala_Lumpur'; // Default timezone

      // Insert the calendar
      final createdCalendar = await _calendarApi!.calendars.insert(newCalendar);
      print('Calendar created with ID: ${createdCalendar.id}');

      // Get the calendar list entry (includes color and other metadata)
      final calendarListEntry = await _calendarApi!.calendarList.get(
        createdCalendar.id!,
      );

      // Update color if specified
      if (colorId != null) {
        calendarListEntry.colorId = colorId;
        await _calendarApi!.calendarList.update(
          calendarListEntry,
          calendarListEntry.id!,
        );
      }

      print('Successfully created calendar: $calendarName');
      return calendarListEntry;
    } catch (e) {
      print('Error creating calendar: $e');
      rethrow;
    }
  }

  /// Sync academic events to Google Calendar
  ///
  /// [events] - List of academic events to sync
  /// [calendarId] - Target calendar ID (use 'primary' for main calendar)
  /// [courseCode] - Optional course code to prepend to event titles
  /// [reminderDays] - Days before event to set reminder
  /// Returns map with successCount and syncedEvents list (with calendar IDs)
  Future<Map<String, dynamic>> syncEvents(
    List<AcademicEvent> events,
    String calendarId, {
    String? courseCode,
    List<int> reminderDays = const [1],
  }) async {
    if (_calendarApi == null) {
      throw Exception('Not authenticated. Please sign in first.');
    }

    if (events.isEmpty) {
      throw Exception('No events to sync');
    }

    int successCount = 0;
    final errors = <String>[];
    final syncedEvents = <AcademicEvent>[];

    print('Syncing ${events.length} events to calendar: $calendarId');

    for (final event in events) {
      try {
        final calendarEvent = await _syncSingleEvent(
          event,
          calendarId,
          courseCode,
          reminderDays,
        );
        // Store the Google Calendar event ID in our event
        event.calendarEventId = calendarEvent.id;
        syncedEvents.add(event);
        successCount++;
        print('Synced: ${event.title} (ID: ${calendarEvent.id})');
      } catch (e) {
        errors.add('${event.title}: $e');
        print('Failed to sync ${event.title}: $e');
      }
    }

    print('Successfully synced $successCount/${events.length} events');

    if (errors.isNotEmpty) {
      print('Errors: ${errors.join(", ")}');
    }

    return {
      'successCount': successCount,
      'syncedEvents': syncedEvents,
      'calendarId': calendarId,
    };
  }

  /// Sync a single event to Google Calendar
  Future<calendar.Event> _syncSingleEvent(
    AcademicEvent event,
    String calendarId,
    String? courseCode,
    List<int> reminderDays,
  ) async {
    // Format title with course code if available
    final eventTitle = courseCode != null && courseCode.isNotEmpty
        ? '[$courseCode] ${event.title}'
        : event.title;

    // Convert AcademicEvent to Google Calendar Event
    final calendarEvent = calendar.Event()
      ..summary = eventTitle
      ..description = _buildEventDescription(event)
      ..location = event.location
      ..start = calendar.EventDateTime(
        dateTime: event.dueDate,
        timeZone: 'America/New_York', // TODO: Make timezone configurable
      )
      ..end = calendar.EventDateTime(
        dateTime: event.dueDate.add(const Duration(hours: 1)),
        timeZone: 'America/New_York',
      )
      ..reminders = _buildReminders(reminderDays)
      ..colorId = _getEventColorId(event);

    // Create event in calendar
    return await _calendarApi!.events.insert(calendarEvent, calendarId);
  }

  /// Build event description with all details
  String _buildEventDescription(AcademicEvent event) {
    final buffer = StringBuffer();
    buffer.writeln(event.description);
    buffer.writeln();

    if (event.weightage != null) {
      buffer.writeln('Weight: ${event.weightage}');
    }

    buffer.writeln('Type: ${event.type.name.toUpperCase()}');
    buffer.writeln('Priority: ${event.priority.name.toUpperCase()}');
    buffer.writeln();
    buffer.writeln('Created by Due - Your Academic Timeline, Automated');

    return buffer.toString();
  }

  /// Build reminder configuration
  calendar.EventReminders _buildReminders(List<int> reminderDays) {
    final overrides = reminderDays.map((days) {
      return calendar.EventReminder(
        method: 'popup',
        minutes: days * 24 * 60, // Convert days to minutes
      );
    }).toList();

    return calendar.EventReminders(useDefault: false, overrides: overrides);
  }

  /// Get Google Calendar color ID based on event priority
  String _getEventColorId(AcademicEvent event) {
    // Google Calendar color IDs:
    // 11 = Red (High priority)
    // 5 = Yellow (Medium priority)
    // 10 = Green (Low priority)
    switch (event.priority) {
      case EventPriority.high:
        return '11'; // Red
      case EventPriority.medium:
        return '5'; // Yellow
      case EventPriority.low:
        return '10'; // Green
    }
  }

  /// Delete specific events from Google Calendar by their IDs
  Future<int> deleteEventsFromCalendar(
    List<AcademicEvent> events,
    String calendarId,
  ) async {
    if (_calendarApi == null) {
      throw Exception('Not authenticated');
    }

    int deleteCount = 0;
    for (final event in events) {
      if (event.calendarEventId != null) {
        try {
          await _calendarApi!.events.delete(calendarId, event.calendarEventId!);
          event.calendarEventId = null; // Clear the ID after deletion
          deleteCount++;
          print('Deleted event: ${event.title}');
        } catch (e) {
          print('Failed to delete event ${event.title}: $e');
        }
      }
    }

    print('Deleted $deleteCount events from calendar');
    return deleteCount;
  }

  /// Delete all events created by Due from a calendar
  /// (For cleanup/re-sync purposes)
  Future<int> deleteAllDueEvents(String calendarId) async {
    if (_calendarApi == null) {
      throw Exception('Not authenticated');
    }

    try {
      print('Fetching events to delete...');
      final events = await _calendarApi!.events.list(
        calendarId,
        q: 'Created by Due',
        maxResults: 2500,
      );

      final eventList = events.items ?? [];
      print('Found ${eventList.length} Due events to delete');

      int deleteCount = 0;
      for (final event in eventList) {
        try {
          await _calendarApi!.events.delete(calendarId, event.id!);
          deleteCount++;
        } catch (e) {
          print('Failed to delete event ${event.id}: $e');
        }
      }

      print('Deleted $deleteCount events');
      return deleteCount;
    } catch (e) {
      print('Error deleting events: $e');
      rethrow;
    }
  }

  /// Query free/busy time slots in user's calendar
  /// Returns list of busy time ranges
  Future<List<Map<String, DateTime>>> getFreeBusySlots(
    String calendarId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    if (_calendarApi == null) {
      throw Exception('Not authenticated');
    }

    try {
      print('Querying free/busy from $startTime to $endTime');

      // Create freebusy query
      final request = calendar.FreeBusyRequest(
        timeMin: startTime,
        timeMax: endTime,
        items: [calendar.FreeBusyRequestItem(id: calendarId)],
      );

      final response = await _calendarApi!.freebusy.query(request);

      // Extract busy periods
      final busyTimes = <Map<String, DateTime>>[];
      final calendarBusy = response.calendars?[calendarId]?.busy ?? [];

      for (final busyPeriod in calendarBusy) {
        if (busyPeriod.start != null && busyPeriod.end != null) {
          busyTimes.add({'start': busyPeriod.start!, 'end': busyPeriod.end!});
        }
      }

      print('Found ${busyTimes.length} busy periods');
      return busyTimes;
    } catch (e) {
      print('Error querying free/busy: $e');
      rethrow;
    }
  }

  /// Find available time slots for study sessions
  /// Returns list of suggested time slots
  Future<List<Map<String, dynamic>>> findStudySlots({
    required String calendarId,
    required int totalHours,
    required int sessionsCount,
    required DateTime startDate,
    required DateTime deadlineDate,
    List<int> preferredHours = const [9, 10, 14, 15, 16, 19, 20],
    int minSessionHours = 2,
    int maxSessionHours = 4,
  }) async {
    try {
      print('Finding $sessionsCount study slots for $totalHours hours total');

      // Get busy times for the period
      final busyTimes = await getFreeBusySlots(
        calendarId,
        startDate,
        deadlineDate,
      );

      final hoursPerSession = (totalHours / sessionsCount).ceil().clamp(
        minSessionHours,
        maxSessionHours,
      );

      final studySlots = <Map<String, dynamic>>[];
      var currentDate = startDate;
      var sessionsFound = 0;

      // Try to find slots, spreading them across available days
      while (sessionsFound < sessionsCount &&
          currentDate.isBefore(
            deadlineDate.subtract(const Duration(days: 1)),
          )) {
        // Skip weekends for now (can be made configurable)
        if (currentDate.weekday == DateTime.saturday ||
            currentDate.weekday == DateTime.sunday) {
          currentDate = currentDate.add(const Duration(days: 1));
          continue;
        }

        // Try each preferred hour
        for (final hour in preferredHours) {
          final slotStart = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            0,
          );
          final slotEnd = slotStart.add(Duration(hours: hoursPerSession));

          // Check if this slot conflicts with busy times
          if (!_isSlotBusy(slotStart, slotEnd, busyTimes)) {
            studySlots.add({
              'start': slotStart,
              'end': slotEnd,
              'duration': hoursPerSession,
            });
            sessionsFound++;

            // Move to next day after finding a slot
            break;
          }
        }

        // Move to next day
        currentDate = currentDate.add(const Duration(days: 1));
      }

      print('Found ${studySlots.length} available study slots');
      return studySlots;
    } catch (e) {
      print('Error finding study slots: $e');
      rethrow;
    }
  }

  /// Check if a time slot conflicts with busy periods
  bool _isSlotBusy(
    DateTime slotStart,
    DateTime slotEnd,
    List<Map<String, DateTime>> busyTimes,
  ) {
    for (final busy in busyTimes) {
      final busyStart = busy['start']!;
      final busyEnd = busy['end']!;

      // Check for overlap
      if (slotStart.isBefore(busyEnd) && slotEnd.isAfter(busyStart)) {
        return true; // Conflict found
      }
    }
    return false; // No conflict
  }

  /// Create study session events in calendar
  /// Returns number of successfully created sessions
  Future<int> createStudySessions({
    required String calendarId,
    required List<Map<String, dynamic>> studySlots,
    required String eventTitle,
    required String eventId,
    String phase = 'Study Session',
  }) async {
    if (_calendarApi == null) {
      throw Exception('Not authenticated');
    }

    int successCount = 0;

    for (int i = 0; i < studySlots.length; i++) {
      try {
        final slot = studySlots[i];
        final sessionNumber = i + 1;

        final calendarEvent = calendar.Event()
          ..summary = '📚 $phase ${sessionNumber}: $eventTitle'
          ..description =
              '''
Study session automatically scheduled by Due.

Related Event: $eventTitle
Session: $sessionNumber of ${studySlots.length}
Duration: ${slot['duration']} hours

Focus on preparation and understanding the material.
Take breaks every 45-60 minutes for optimal retention.

Created by Due - Your Academic Timeline, Automated'''
          ..start = calendar.EventDateTime(
            dateTime: slot['start'],
            timeZone: 'America/New_York', // TODO: Make configurable
          )
          ..end = calendar.EventDateTime(
            dateTime: slot['end'],
            timeZone: 'America/New_York',
          )
          ..colorId =
              '7' // Peacock blue for study sessions
          ..reminders = calendar.EventReminders(
            useDefault: false,
            overrides: [
              calendar.EventReminder(method: 'popup', minutes: 30),
              calendar.EventReminder(method: 'popup', minutes: 1440), // 1 day
            ],
          );

        await _calendarApi!.events.insert(calendarEvent, calendarId);
        successCount++;
        print('Created study session $sessionNumber');
      } catch (e) {
        print('Failed to create study session ${i + 1}: $e');
      }
    }

    print('Successfully created $successCount study sessions');
    return successCount;
  }
}

/// Custom HTTP client that includes Google auth headers
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
