import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:due/config/api_config.dart';

/// Service for YouTube Data API v3 integration
/// Used by Resource Finder to search educational videos
class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  /// Search for educational videos related to a topic
  Future<List<Map<String, dynamic>>> searchVideos(
    String query, {
    int maxResults = 3,
  }) async {
    final apiKey = ApiConfig.youtubeApiKey;
    if (apiKey.isEmpty) throw Exception('YouTube API Key not configured.');

    // 1. Build request URL for search
    final searchUrl = Uri.parse(
        '$_baseUrl/search?part=snippet&maxResults=$maxResults&q=${Uri.encodeComponent(query)}&type=video&key=$apiKey');

    // 2. Make HTTP GET request
    final response = await http.get(searchUrl);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;

      if (items.isEmpty) return [];

      // 3. Extract Video IDs to fetch exact duration and views
      final videoIds = items.map((item) => item['id']['videoId'] as String).toList();
      final details = await getVideoDetails(videoIds);

      // 4. Map the data to exactly what your UI expects
      return items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final snippet = item['snippet'];
        
        // Fallback just in case details fail to load
        final detail = details.length > index ? details[index] : {'duration': 'PT0M0S', 'viewCount': '0'};

        // Clean up HTML entities in titles like &quot; or &#39;
        final rawTitle = snippet['title'].toString();
        final cleanTitle = rawTitle.replaceAll('&quot;', '"').replaceAll('&#39;', "'").replaceAll('&amp;', '&');

        return {
          'title': cleanTitle,
          'type': 'Video',
          'platform': 'YouTube',
          'duration': formatDuration(detail['duration'] as String),
          'views': formatViewCount(int.parse(detail['viewCount'] as String)),
          'channel': snippet['channelTitle'],
          'rating': 4.9, // Hardcoded since YouTube API doesn't provide rating
          'thumbnail': snippet['thumbnails']['high']['url'],
          'url': 'https://www.youtube.com/watch?v=${item['id']['videoId']}',
        };
      }).toList();
    } else {
      throw Exception('Failed to load videos from YouTube. Status Code: ${response.statusCode}');
    }
  }

  /// Get detailed information about specific videos
  Future<List<Map<String, dynamic>>> getVideoDetails(List<String> videoIds) async {
    if (videoIds.isEmpty) return [];
    
    final apiKey = ApiConfig.youtubeApiKey;
    final idsString = videoIds.join(',');
    
    final url = Uri.parse(
        '$_baseUrl/videos?part=contentDetails,statistics&id=$idsString&key=$apiKey');

    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      
      return items.map((item) => {
            'duration': item['contentDetails']['duration'],
            'viewCount': item['statistics']['viewCount'] ?? '0',
          }).toList();
    }
    return [];
  }

  /// Format ISO 8601 duration to human-readable format
  String formatDuration(String isoDuration) {
    // Simple parser for YouTube's PT#H#M#S format
    String duration = isoDuration.replaceAll('PT', '');
    
    // Handle hours
    if (duration.contains('H')) {
      duration = duration.replaceAll('H', ':');
    }
    
    // Handle minutes
    if (duration.contains('M')) {
      duration = duration.replaceAll('M', ':');
    } else if (duration.contains(':')) {
      // If there are hours but no minutes, add '00:'
      duration = duration.replaceAll(':', ':00:');
    }
    
    // Handle seconds
    if (duration.contains('S')) {
      duration = duration.replaceAll('S', '');
      // Fix single digit seconds (e.g., 4:5 -> 4:05)
      final parts = duration.split(':');
      if (parts.length > 1 && parts.last.length == 1) {
        parts[parts.length - 1] = '0${parts.last}';
        duration = parts.join(':');
      }
    } else {
      duration += '00';
    }
    
    // Clean up trailing colons
    if (duration.endsWith(':')) {
      duration += '00';
    }
    
    return duration;
  }

  /// Format view count to human-readable format
  String formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(0)}K views';
    } else {
      return '$viewCount views';
    }
  }

  /// Check if API key is configured
  bool isConfigured() {
    return ApiConfig.youtubeApiKey.isNotEmpty;
  }
}