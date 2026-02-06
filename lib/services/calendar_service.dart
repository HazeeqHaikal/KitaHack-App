import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:due/config/api_config.dart';
import 'package:due/models/academic_event.dart';

/// Service for Google Calendar API integration
/// Handles authentication and event synchronization
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  GoogleSignIn? _googleSignIn;
  calendar.CalendarApi? _calendarApi;
  GoogleSignInAccount? _currentUser;

  /// Initialize Google Sign-In
  void initialize() {
    _googleSignIn = GoogleSignIn(
      scopes: ApiConfig.calendarScopes,
    );

    // Listen to sign-in state changes
    _googleSignIn?.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      if (account != null) {
        _initializeCalendarApi();
      }
    });
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      print('Attempting Google Sign-In...');
      final account = await _googleSignIn?.signIn();
      
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

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    _currentUser = null;
    _calendarApi = null;
    print('Signed out successfully');
  }

  /// Initialize Calendar API after authentication
  Future<void> _initializeCalendarApi() async {
    try {
      final authHeaders = await _currentUser?.authHeaders;
      if (authHeaders == null) {
        throw Exception('Failed to get auth headers');
      }

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

    return calendar.EventReminders(
      useDefault: false,
      overrides: overrides,
    );
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
