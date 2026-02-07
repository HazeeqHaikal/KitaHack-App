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
      throw Exception('Not authenticated. Please sign in first.');
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

  /// Sync academic events to Google Calendar
  ///
  /// [events] - List of academic events to sync
  /// [calendarId] - Target calendar ID (use 'primary' for main calendar)
  /// [reminderDays] - Days before event to set reminder
  /// Returns number of successfully synced events
  Future<int> syncEvents(
    List<AcademicEvent> events,
    String calendarId, {
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

    print('Syncing ${events.length} events to calendar: $calendarId');

    for (final event in events) {
      try {
        await _syncSingleEvent(event, calendarId, reminderDays);
        successCount++;
        print('Synced: ${event.title}');
      } catch (e) {
        errors.add('${event.title}: $e');
        print('Failed to sync ${event.title}: $e');
      }
    }

    print('Successfully synced $successCount/${events.length} events');

    if (errors.isNotEmpty) {
      print('Errors: ${errors.join(", ")}');
    }

    return successCount;
  }

  /// Sync a single event to Google Calendar
  Future<calendar.Event> _syncSingleEvent(
    AcademicEvent event,
    String calendarId,
    List<int> reminderDays,
  ) async {
    // Convert AcademicEvent to Google Calendar Event
    final calendarEvent = calendar.Event()
      ..summary = event.title
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
