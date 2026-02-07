import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:due/config/api_config.dart';
import 'package:due/models/course_info.dart';
import 'package:due/services/mock_data_service.dart';
import 'package:due/services/usage_tracking_service.dart';
import 'package:due/services/response_cache_service.dart';
import 'dart:convert';

/// Service for interacting with Google Gemini API
/// Handles syllabus analysis and academic event extraction
class GeminiService {
  late final GenerativeModel _model;
  final UsageTrackingService _usageTracking = UsageTrackingService();
  final ResponseCacheService _responseCache = ResponseCacheService();

  GeminiService() {
    ApiConfig.validateConfig();
    _model = GenerativeModel(
      model: ApiConfig.geminiModel,
      apiKey: ApiConfig.geminiApiKey,
    );
  }

  /// Analyze a syllabus file (PDF or Image) and extract academic events
  ///
  /// [file] - The syllabus file to analyze (PDF, JPG, PNG)
  /// Returns [CourseInfo] with extracted course details and events
  /// Throws [Exception] if analysis fails
  Future<CourseInfo> analyzeSyllabus(File file) async {
    try {
      print('Starting syllabus analysis for: ${file.path}');

      // Check if dev mode is enabled
      if (ApiConfig.devMode) {
        print('DEV MODE: Using mock data instead of API call');
        await Future.delayed(const Duration(seconds: 2)); // Simulate processing
        final mockCourses = MockDataService.getSampleCourses();
        return mockCourses.first; // Return first mock course
      }

      // Check cache first (if enabled)
      if (ApiConfig.enableResponseCache) {
        final cachedResponse = await _responseCache.getCachedResponse(file);
        if (cachedResponse != null) {
          print('Using cached response (saved API call)');
          return cachedResponse;
        }
      }

      // Check usage tracking and daily limit
      if (ApiConfig.enableUsageTracking) {
        final limitExceeded = await _usageTracking.isDailyLimitExceeded();
        if (limitExceeded) {
          final todayCalls = await _usageTracking.getTodayCalls();
          final limit = await _usageTracking.getDailyLimit();
          print('WARNING: Daily API limit exceeded ($todayCalls/$limit calls)');
          // Still proceed but warn user
        }
      }

      // Read file as bytes
      final bytes = await file.readAsBytes();

      // Determine MIME type based on file extension
      final extension = file.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      if (mimeType == null) {
        throw Exception('Unsupported file type: $extension');
      }

      // Create the content with both prompt and file
      final prompt = _buildAnalysisPrompt();
      final content = [
        Content.multi([TextPart(prompt), DataPart(mimeType, bytes)]),
      ];

      print('Sending request to Gemini API...');

      // Log API call for tracking
      if (ApiConfig.enableUsageTracking) {
        await _usageTracking.logApiCall('syllabus');
      }

      // Generate content with retry logic
      final response = await _generateWithRetry(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      print('Received response, parsing JSON...');

      // Parse the JSON response
      final courseInfo = _parseGeminiResponse(response.text!);

      print('Successfully extracted ${courseInfo.events.length} events');

      // Cache the response (if enabled)
      if (ApiConfig.enableResponseCache) {
        await _responseCache.cacheResponse(file, courseInfo);
      }

      return courseInfo;
    } catch (e) {
      print('Error analyzing syllabus: $e');
      throw Exception('Failed to analyze syllabus: $e');
    }
  }

  /// Generate content with retry logic for network failures
  Future<GenerateContentResponse> _generateWithRetry(
    List<Content> content, {
    int attempt = 1,
  }) async {
    try {
      final response = await _model.generateContent(content);
      return response;
    } catch (e) {
      if (attempt < ApiConfig.maxRetries) {
        print('Retry attempt $attempt/${ApiConfig.maxRetries}');
        await Future.delayed(Duration(seconds: attempt * 2));
        return _generateWithRetry(content, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  /// Build the analysis prompt for Gemini
  String _buildAnalysisPrompt() {
    return '''
Analyze this course syllabus document and extract all academic events, deadlines, and important dates.

IMPORTANT: Return ONLY valid JSON, no markdown formatting, no code blocks, no explanations.

Extract the following information in this EXACT JSON format:
{
  "courseName": "Full course name",
  "courseCode": "Course code (e.g., CS101)",
  "instructor": "Instructor name if available, otherwise null",
  "semester": "Semester/term if available (e.g., Spring 2026), otherwise null",
  "events": [
    {
      "id": "unique_identifier",
      "title": "Assignment/Exam title",
      "dueDate": "ISO 8601 date string (YYYY-MM-DDTHH:MM:SS)",
      "description": "Detailed description with requirements",
      "weightage": "Percentage as string (e.g., '15%') or null",
      "type": "assignment|exam|quiz|project|presentation|lab|other",
      "location": "Submission method or physical location, or null"
    }
  ]
}

RULES:
1. Extract ALL dates mentioned: assignments, exams, quizzes, projects, presentations, labs, deadlines
2. For date parsing:
   - If year not specified, use 2026
   - If only day/month given, infer reasonable time (11:59 PM for assignments, class time for exams)
   - Convert relative dates like "Week 3" to actual dates if semester start is mentioned
3. For event types:
   - "assignment" for homework, essays, assignments
   - "exam" for midterms, finals, tests
   - "quiz" for quizzes, short tests
   - "project" for term projects, group work
   - "presentation" for oral presentations
   - "lab" for lab work, practicals
   - "other" for anything else
4. Extract weightage from context like "worth 20%", "20% of grade", etc.
5. For location: note if it's "Canvas submission", "Email", "In-class", room numbers, etc.
6. Create unique IDs using pattern: courseCode_eventType_number (e.g., "CS101_assignment_1")
7. Return ONLY the JSON object, nothing else

If you cannot extract a value, use null. If the document is not a syllabus, return an error message in JSON format:
{"error": "This does not appear to be a course syllabus"}
''';
  }

  /// Parse Gemini's JSON response into CourseInfo model
  CourseInfo _parseGeminiResponse(String responseText) {
    try {
      // Clean the response text - remove markdown formatting if present
      String cleanJson = responseText.trim();

      // Remove markdown code blocks if present
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }

      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }

      cleanJson = cleanJson.trim();

      // Parse JSON
      final Map<String, dynamic> jsonData = json.decode(cleanJson);

      // Check for error response
      if (jsonData.containsKey('error')) {
        throw Exception(jsonData['error']);
      }

      // Convert to CourseInfo model
      return CourseInfo.fromJson(jsonData);
    } catch (e) {
      print('Error parsing Gemini response: $e');
      print('Response text: $responseText');
      throw Exception('Failed to parse Gemini response: $e');
    }
  }

  /// Estimate study time required for an academic event
  /// Returns an object with totalHours and breakdown suggestions
  Future<Map<String, dynamic>> estimateStudyEffort(
    String eventTitle,
    String eventType,
    String description,
    int? weightage,
    int daysUntilDue,
  ) async {
    try {
      print('Estimating study effort for: $eventTitle');

      // Check if dev mode is enabled
      if (ApiConfig.devMode) {
        print('DEV MODE: Using mock effort estimation');
        await Future.delayed(const Duration(seconds: 1)); // Simulate processing
        return _getMockEffortEstimate(eventType);
      }

      // Log API call for tracking
      if (ApiConfig.enableUsageTracking) {
        await _usageTracking.logApiCall('effort');
      }

      final prompt =
          '''
Analyze this academic event and estimate the required study/preparation time.

Event Details:
- Title: $eventTitle
- Type: $eventType
- Description: $description
- Weightage: ${weightage ?? 'Unknown'}%
- Days until due: $daysUntilDue days

Return ONLY valid JSON (no markdown, no code blocks) in this EXACT format:
{
  "totalHours": <number>,
  "sessionsRecommended": <number>,
  "hoursPerSession": <number>,
  "breakdown": [
    {
      "phase": "Phase name (e.g., Research, Writing, Review)",
      "hours": <number>,
      "description": "Brief description of activities"
    }
  ],
  "reasoning": "Brief explanation of time estimate"
}

Consider:
- Event type complexity (exams need more review time, assignments need work time)
- Weightage (higher weight = more time investment)
- Days available (spread effectively without overwhelming)
- Optimal session length (2-3 hours for focus, longer for projects)

Guidelines:
- Exam: 8-15 hours total (review, practice, consolidation)
- Assignment: 6-12 hours total (research, writing, editing)
- Project: 10-20 hours total (planning, execution, refinement)
- Quiz: 2-4 hours total (focused review)
- Presentation: 5-8 hours total (prep, practice)
- Lab: 3-6 hours total (prep, execution)

Recommend 2-5 study sessions total.
''';

      final content = [Content.text(prompt)];

      final response = await _generateWithRetry(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Parse JSON response
      String cleanJson = response.text!.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final result = json.decode(cleanJson) as Map<String, dynamic>;
      print('Estimated ${result['totalHours']} hours of study needed');

      return result;
    } catch (e) {
      print('Error estimating study effort: $e');
      // Return reasonable defaults on error
      return _getMockEffortEstimate(eventType);
    }
  }

  /// Get mock effort estimate for dev mode or error fallback
  Map<String, dynamic> _getMockEffortEstimate(String eventType) {
    return {
      'totalHours': eventType == 'exam' ? 10 : 6,
      'sessionsRecommended': 3,
      'hoursPerSession': eventType == 'exam' ? 3 : 2,
      'breakdown': [
        {
          'phase': 'Preparation',
          'hours': eventType == 'exam' ? 6 : 4,
          'description': 'Initial study and understanding',
        },
        {
          'phase': 'Practice/Work',
          'hours': eventType == 'exam' ? 3 : 2,
          'description': 'Active work and application',
        },
        {
          'phase': 'Review',
          'hours': 1,
          'description': 'Final review and refinement',
        },
      ],
      'reasoning': ApiConfig.devMode
          ? 'Mock estimate (Dev Mode enabled)'
          : 'Default estimate (AI estimation failed)',
    };
  }

  /// Get MIME type from file extension
  String? _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }
}
