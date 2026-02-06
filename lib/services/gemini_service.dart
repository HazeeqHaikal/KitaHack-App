import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:due/config/api_config.dart';
import 'package:due/models/course_info.dart';
import 'dart:convert';

/// Service for interacting with Google Gemini API
/// Handles syllabus analysis and academic event extraction
class GeminiService {
  late final GenerativeModel _model;

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

      // Generate content with retry logic
      final response = await _generateWithRetry(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      print('Received response, parsing JSON...');

      // Parse the JSON response
      final courseInfo = _parseGeminiResponse(response.text!);

      print('Successfully extracted ${courseInfo.events.length} events');

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
