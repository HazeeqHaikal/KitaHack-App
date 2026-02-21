import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:due/config/api_config.dart';
import 'package:due/models/course_info.dart';
import 'package:due/models/academic_event.dart';
import 'package:due/models/task.dart';
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
  /// [existingEvents] - Events already saved from other courses; Gemini will
  ///   skip anything that is clearly the same event already captured.
  /// Returns [CourseInfo] with extracted course details and events
  /// Throws [Exception] if analysis fails
  /// [bytes]     - Raw file bytes (from PlatformFile.bytes — works on web & native)
  /// [extension] - File extension without dot, e.g. 'pdf', 'jpg'
  /// [fileName]  - Original file name, used for logging/cache keying
  /// [existingEvents] - Events already saved; Gemini will skip real duplicates
  Future<CourseInfo> analyzeSyllabus(
    Uint8List bytes,
    String extension,
    String fileName, {
    List<AcademicEvent> existingEvents = const [],
  }) async {
    try {
      print('Starting syllabus analysis for: $fileName');

      // Check if dev mode is enabled
      if (ApiConfig.devMode) {
        print('DEV MODE: Using mock data instead of API call');
        await Future.delayed(const Duration(seconds: 2)); // Simulate processing
        final mockCourses = MockDataService.getSampleCourses();
        return mockCourses.first; // Return first mock course
      }

      // Check cache first (if enabled)
      if (ApiConfig.enableResponseCache) {
        final cachedResponse = await _responseCache.getCachedResponseFromBytes(
          bytes,
        );
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

      // Determine MIME type based on file extension
      final mimeType = _getMimeType(extension.toLowerCase());

      if (mimeType == null) {
        throw Exception('Unsupported file type: $extension');
      }

      // Create the content with both prompt and file
      final prompt = _buildAnalysisPrompt(existingEvents: existingEvents);
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
        await _responseCache.cacheResponseFromBytes(bytes, courseInfo);
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
  String _buildAnalysisPrompt({List<AcademicEvent> existingEvents = const []}) {
    // Build the "already captured" section so Gemini can skip real duplicates
    final String existingEventsSection = existingEvents.isEmpty
        ? ''
        : '''

ALREADY-CAPTURED EVENTS (from other courses the student has previously uploaded):
The following events are already saved in the student's calendar. If this syllabus mentions
the SAME event (same or very similar name AND same date), do NOT include it in the output
again — it would create a duplicate. Use your understanding of the context to judge whether
they are truly the same institution-wide event (e.g. "Entrance Survey", "Exit Survey",
"SuFo", mid-semester break) rather than a coincidentally similar course-specific activity.

${existingEvents.map((e) {
            final dateStr = e.dueDate.toIso8601String().substring(0, 10);
            return '- "${e.title}" on $dateStr';
          }).join('\n')}
''';

    return '''
Analyze this course syllabus document and extract all academic events, deadlines, and important dates.

IMPORTANT: Return ONLY valid JSON, no markdown formatting, no code blocks, no explanations.
$existingEventsSection
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
    int daysUntilDue, {
    Uint8List? contextBytes,
    String? contextExtension,
  }) async {
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

      final List<Content> effortContent;
      if (contextBytes != null && contextExtension != null) {
        final mimeType = _getMimeType(contextExtension.toLowerCase());
        if (mimeType != null) {
          effortContent = [
            Content.multi([TextPart(prompt), DataPart(mimeType, contextBytes)]),
          ];
        } else {
          effortContent = [Content.text(prompt)];
        }
      } else {
        effortContent = [Content.text(prompt)];
      }

      final response = await _generateWithRetry(effortContent);

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

  /// Extract an ideal YouTube search query from the full academic event context
  /// Returns a concise, topic-accurate search string (e.g. "Object Oriented Programming tutorial")
  Future<String> extractYouTubeSearchQuery(
    AcademicEvent event, {
    Uint8List? contextBytes,
    String? contextExtension,
  }) async {
    try {
      print('Extracting YouTube search query for: ${event.title}');

      if (ApiConfig.devMode) {
        return '${event.title} tutorial';
      }

      if (ApiConfig.enableUsageTracking) {
        await _usageTracking.logApiCall('youtube_query');
      }

      final prompt =
          '''
You are helping a student find educational YouTube videos for their academic task.

Task Details:
- Title: ${event.title}
- Type: ${event.type.toString().split('.').last}
- Description: ${event.description}
${event.weightage != null ? '- Weightage: ${event.weightage}' : ''}

Based on the ACTUAL academic topic described above (not just the task title), generate the single most effective YouTube search query to find helpful tutorial or study videos.

Rules:
- Focus on the core subject/topic, not the task name (e.g. do NOT return "Lab Exercise 1" — return the real topic like "Object Oriented Programming")
- Keep it concise: 3-6 words
- Add "tutorial" or "explained" if helpful
- Return ONLY the search query string, nothing else, no quotes, no punctuation at end
''';

      final List<Content> queryContent;
      if (contextBytes != null && contextExtension != null) {
        final mimeType = _getMimeType(contextExtension.toLowerCase());
        if (mimeType != null) {
          queryContent = [
            Content.multi([TextPart(prompt), DataPart(mimeType, contextBytes)]),
          ];
        } else {
          queryContent = [Content.text(prompt)];
        }
      } else {
        queryContent = [Content.text(prompt)];
      }
      final response = await _generateWithRetry(queryContent);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response');
      }

      final query = response.text!
          .trim()
          .replaceAll('"', '')
          .replaceAll("'", '');
      print('Extracted search query: $query');
      return query;
    } catch (e) {
      print('Error extracting search query: $e');
      // Fallback: use event title
      return '${event.title} tutorial';
    }
  }

  /// Generate task breakdown for an academic event
  ///
  /// Option 1: Simple mode - uses only event data
  /// Option 2: Enhanced mode - includes uploaded file for better context
  ///
  /// [event] - The academic event to break down
  /// [contextFile] - Optional file with additional instructions/requirements
  /// Returns List of [Task] objects with titles, durations, and descriptions
  Future<List<Task>> generateTaskBreakdown(
    AcademicEvent event, {
    Uint8List? contextBytes,
    String? contextExtension,
  }) async {
    try {
      print('Generating task breakdown for: ${event.title}');

      // Check if dev mode is enabled
      if (ApiConfig.devMode) {
        print('DEV MODE: Using mock task breakdown');
        await Future.delayed(const Duration(seconds: 2));
        return _getMockTaskBreakdown(event.type);
      }

      // Build the prompt based on available context
      final prompt = _buildTaskBreakdownPrompt(event);

      List<Content> content;

      if (contextBytes != null && contextExtension != null) {
        print('Enhanced mode: Including uploaded context file');
        final mimeType = _getMimeType(contextExtension.toLowerCase());
        if (mimeType != null) {
          content = [
            Content.multi([TextPart(prompt), DataPart(mimeType, contextBytes)]),
          ];
        } else {
          print(
            'Unsupported file type: $contextExtension — falling back to text-only',
          );
          content = [Content.text(prompt)];
        }
      } else {
        print('Simple mode: Using event data only');
        // Option 1: Simple mode with just event data
        content = [Content.text(prompt)];
      }

      // Log API call for tracking
      if (ApiConfig.enableUsageTracking) {
        await _usageTracking.logApiCall('task_breakdown');
      }

      // Generate content with retry logic
      final response = await _generateWithRetry(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      print('Received task breakdown response, parsing...');

      // Parse the JSON response
      final tasks = _parseTaskBreakdownResponse(response.text!);

      print('Successfully generated ${tasks.length} tasks');

      return tasks;
    } catch (e) {
      print('Error generating task breakdown: $e');
      // Fallback to mock data on error
      return _getMockTaskBreakdown(event.type);
    }
  }

  /// Build the task breakdown prompt for Gemini
  String _buildTaskBreakdownPrompt(AcademicEvent event) {
    return '''
You are an expert academic planner. Break down this academic event into detailed, actionable subtasks that will help a student complete it successfully.

EVENT DETAILS:
- Title: ${event.title}
- Type: ${event.type.toString().split('.').last}
- Due Date: ${event.dueDate}
- Description: ${event.description}
${event.weightage != null ? '- Weightage: ${event.weightage}' : ''}

IMPORTANT: Return ONLY valid JSON, no markdown formatting, no code blocks, no explanations.

Return a JSON array of tasks in this EXACT format:
[
  {
    "id": "unique_identifier",
    "title": "Clear, actionable task title",
    "duration": "Estimated time (e.g., '2 hours', '30 min')",
    "description": "Optional: Additional details or tips for this task"
  }
]

REQUIREMENTS:
1. Break down into 5-10 specific, actionable subtasks
2. Order tasks logically (research → plan → execute → review)
3. Estimate realistic durations for each task
4. For assignments: Include research, drafting, revising, formatting, submission
5. For exams: Include topic breakdown, practice, review, summary notes
6. For projects: Include planning, development, testing, documentation, presentation
7. Make tasks concrete and measurable (avoid vague tasks like "study hard")
8. Consider the event weightage for task depth

Example for an assignment:
[
  {"id": "1", "title": "Read assignment requirements thoroughly", "duration": "15 min", "description": "Highlight key requirements and grading criteria"},
  {"id": "2", "title": "Research topic and gather 5-7 credible sources", "duration": "2 hours", "description": "Focus on academic journals and textbooks"},
  {"id": "3", "title": "Create detailed outline with main points", "duration": "30 min", "description": "Structure: intro, 3 body sections, conclusion"},
  {"id": "4", "title": "Write first draft (don't edit yet)", "duration": "3 hours", "description": "Focus on getting ideas down, aim for 80% of word count"},
  {"id": "5", "title": "Revise content for clarity and arguments", "duration": "1 hour", "description": "Check logic flow and evidence support"},
  {"id": "6", "title": "Edit for grammar, citations, and formatting", "duration": "45 min", "description": "Use citation style guide, proofread twice"},
  {"id": "7", "title": "Final review and submit", "duration": "15 min", "description": "Check submission requirements and deadline"}
]

Now generate the task breakdown:
''';
  }

  /// Parse task breakdown response from Gemini
  List<Task> _parseTaskBreakdownResponse(String responseText) {
    try {
      // Clean up the response (remove markdown code blocks if present)
      var cleanJson = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Find JSON array in response
      final arrayStart = cleanJson.indexOf('[');
      final arrayEnd = cleanJson.lastIndexOf(']');

      if (arrayStart != -1 && arrayEnd != -1) {
        cleanJson = cleanJson.substring(arrayStart, arrayEnd + 1);
      }

      final jsonArray = json.decode(cleanJson) as List<dynamic>;

      return jsonArray.map((taskJson) => Task.fromJson(taskJson)).toList();
    } catch (e) {
      print('Error parsing task breakdown response: $e');
      print('Response text: $responseText');
      throw Exception('Failed to parse task breakdown: $e');
    }
  }

  /// Get mock task breakdown for dev mode or error fallback
  List<Task> _getMockTaskBreakdown(EventType eventType) {
    switch (eventType) {
      case EventType.assignment:
        return [
          Task(
            id: '1',
            title: 'Read assignment requirements thoroughly',
            duration: '15 min',
            description: 'Highlight key requirements and grading criteria',
          ),
          Task(
            id: '2',
            title: 'Research topic and gather sources',
            duration: '2 hours',
            description: 'Focus on credible academic sources',
          ),
          Task(
            id: '3',
            title: 'Create outline and structure',
            duration: '30 min',
            description: 'Plan introduction, body, and conclusion',
          ),
          Task(
            id: '4',
            title: 'Write first draft',
            duration: '3 hours',
            description: 'Focus on getting ideas down',
          ),
          Task(
            id: '5',
            title: 'Review and revise content',
            duration: '1 hour',
            description: 'Check logic flow and arguments',
          ),
          Task(
            id: '6',
            title: 'Proofread and format',
            duration: '30 min',
            description: 'Check grammar, citations, formatting',
          ),
          Task(
            id: '7',
            title: 'Submit assignment',
            duration: '10 min',
            description: 'Double-check submission requirements',
          ),
        ];
      case EventType.exam:
        return [
          Task(
            id: '1',
            title: 'Review syllabus and exam topics',
            duration: '30 min',
            description: 'Identify key topics and weightage',
          ),
          Task(
            id: '2',
            title: 'Organize study materials and notes',
            duration: '45 min',
            description: 'Gather textbooks, notes, practice problems',
          ),
          Task(
            id: '3',
            title: 'Study Chapter 1-3',
            duration: '4 hours',
            description: 'Read, take notes, summarize key concepts',
          ),
          Task(
            id: '4',
            title: 'Study Chapter 4-6',
            duration: '4 hours',
            description: 'Read, take notes, summarize key concepts',
          ),
          Task(
            id: '5',
            title: 'Practice problems and exercises',
            duration: '3 hours',
            description: 'Work through textbook and past exam questions',
          ),
          Task(
            id: '6',
            title: 'Review past exams/quizzes',
            duration: '2 hours',
            description: 'Identify common question patterns',
          ),
          Task(
            id: '7',
            title: 'Create summary notes',
            duration: '1 hour',
            description: 'Condense key formulas, concepts, definitions',
          ),
          Task(
            id: '8',
            title: 'Final review session',
            duration: '2 hours',
            description: 'Review summary notes and practice problems',
          ),
        ];
      case EventType.project:
        return [
          Task(
            id: '1',
            title: 'Understand project requirements',
            duration: '30 min',
            description: 'Review rubric and deliverables',
          ),
          Task(
            id: '2',
            title: 'Form team and assign roles',
            duration: '1 hour',
            description: 'Define responsibilities and timeline',
          ),
          Task(
            id: '3',
            title: 'Brainstorm ideas and approaches',
            duration: '2 hours',
            description: 'Evaluate feasibility and resources',
          ),
          Task(
            id: '4',
            title: 'Create project plan and timeline',
            duration: '1 hour',
            description: 'Set milestones and deadlines',
          ),
          Task(
            id: '5',
            title: 'Research and data collection',
            duration: '5 hours',
            description: 'Gather necessary information and resources',
          ),
          Task(
            id: '6',
            title: 'Develop/implement solution',
            duration: '8 hours',
            description: 'Build, code, or create project deliverable',
          ),
          Task(
            id: '7',
            title: 'Test and debug',
            duration: '3 hours',
            description: 'Ensure everything works as expected',
          ),
          Task(
            id: '8',
            title: 'Prepare documentation',
            duration: '2 hours',
            description: 'Write reports, comments, user guides',
          ),
          Task(
            id: '9',
            title: 'Create presentation',
            duration: '2 hours',
            description: 'Design slides and prepare demo',
          ),
          Task(
            id: '10',
            title: 'Practice presentation',
            duration: '1 hour',
            description: 'Rehearse delivery and timing',
          ),
        ];
      default:
        return [
          Task(
            id: '1',
            title: 'Review requirements',
            duration: '20 min',
            description: 'Understand what needs to be done',
          ),
          Task(
            id: '2',
            title: 'Prepare materials',
            duration: '1 hour',
            description: 'Gather necessary resources',
          ),
          Task(
            id: '3',
            title: 'Complete main work',
            duration: '3 hours',
            description: 'Execute the primary task',
          ),
          Task(
            id: '4',
            title: 'Review and finalize',
            duration: '30 min',
            description: 'Check quality and submit',
          ),
        ];
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
