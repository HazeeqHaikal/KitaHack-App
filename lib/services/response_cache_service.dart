import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:due/models/course_info.dart';

/// Service for caching Gemini API responses
/// Prevents repeated API calls for the same files during testing
class ResponseCacheService {
  static const String _cacheKey = 'gemini_response_cache';
  static const int maxCacheAgeDays = 7; // Auto-expire after 7 days
  static const int maxCacheSize = 50; // Keep max 50 cached responses

  /// Generate a hash for a file to use as cache key
  Future<String> _generateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('Error generating file hash: $e');
      rethrow;
    }
  }

  /// Load cache from storage
  Future<Map<String, dynamic>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);

      if (cacheJson == null || cacheJson.isEmpty) {
        return {};
      }

      return json.decode(cacheJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading cache: $e');
      return {};
    }
  }

  /// Save cache to storage
  Future<void> _saveCache(Map<String, dynamic> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(cache));
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  /// Check if a cached response exists for a file
  Future<bool> hasCachedResponse(File file) async {
    try {
      final hash = await _generateFileHash(file);
      final cache = await _loadCache();

      if (!cache.containsKey(hash)) return false;

      final entry = cache[hash] as Map<String, dynamic>;
      final timestamp = DateTime.parse(entry['timestamp']);
      final age = DateTime.now().difference(timestamp);

      // Check if cache is still valid
      if (age.inDays > maxCacheAgeDays) {
        // Cache expired, remove it
        cache.remove(hash);
        await _saveCache(cache);
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking cache: $e');
      return false;
    }
  }

  /// Get cached response for a file
  Future<CourseInfo?> getCachedResponse(File file) async {
    try {
      final hash = await _generateFileHash(file);
      final cache = await _loadCache();

      if (!cache.containsKey(hash)) return null;

      final entry = cache[hash] as Map<String, dynamic>;
      final timestamp = DateTime.parse(entry['timestamp']);
      final age = DateTime.now().difference(timestamp);

      // Check if cache is still valid
      if (age.inDays > maxCacheAgeDays) {
        // Cache expired, remove it
        cache.remove(hash);
        await _saveCache(cache);
        return null;
      }

      final courseData = entry['response'] as Map<String, dynamic>;
      print('Using cached response for file (age: ${age.inHours} hours)');
      return CourseInfo.fromJson(courseData);
    } catch (e) {
      print('Error getting cached response: $e');
      return null;
    }
  }

  /// Cache a response for a file
  Future<void> cacheResponse(File file, CourseInfo courseInfo) async {
    try {
      final hash = await _generateFileHash(file);
      var cache = await _loadCache();

      // Add new entry
      cache[hash] = {
        'timestamp': DateTime.now().toIso8601String(),
        'response': courseInfo.toJson(),
        'fileName': file.path.split(Platform.pathSeparator).last,
      };

      // Enforce cache size limit (remove oldest entries)
      if (cache.length > maxCacheSize) {
        final entries = cache.entries.toList()
          ..sort((a, b) {
            final aTime = DateTime.parse(a.value['timestamp']);
            final bTime = DateTime.parse(b.value['timestamp']);
            return aTime.compareTo(bTime);
          });

        // Keep only the newest maxCacheSize entries
        cache = Map.fromEntries(entries.skip(cache.length - maxCacheSize));
      }

      await _saveCache(cache);
      print('Cached response for file: $hash');
    } catch (e) {
      print('Error caching response: $e');
      // Don't rethrow - caching is optional functionality
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cache = await _loadCache();
      int validEntries = 0;
      int expiredEntries = 0;

      for (var entry in cache.values) {
        final timestamp = DateTime.parse(entry['timestamp']);
        final age = DateTime.now().difference(timestamp);

        if (age.inDays <= maxCacheAgeDays) {
          validEntries++;
        } else {
          expiredEntries++;
        }
      }

      return {
        'totalEntries': cache.length,
        'validEntries': validEntries,
        'expiredEntries': expiredEntries,
        'maxCacheSize': maxCacheSize,
        'maxAgeDays': maxCacheAgeDays,
      };
    } catch (e) {
      print('Error getting cache stats: $e');
      return {
        'totalEntries': 0,
        'validEntries': 0,
        'expiredEntries': 0,
        'maxCacheSize': maxCacheSize,
        'maxAgeDays': maxCacheAgeDays,
      };
    }
  }

  /// Clear all cached responses
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
    }
  }

  /// Clean up expired entries
  Future<void> cleanupExpired() async {
    try {
      final cache = await _loadCache();
      final now = DateTime.now();
      int removed = 0;

      cache.removeWhere((key, value) {
        final timestamp = DateTime.parse(value['timestamp']);
        final age = now.difference(timestamp);
        final expired = age.inDays > maxCacheAgeDays;
        if (expired) removed++;
        return expired;
      });

      await _saveCache(cache);
      print('Cleaned up $removed expired cache entries');
    } catch (e) {
      print('Error cleaning up cache: $e');
    }
  }

  /// Get list of cached files
  Future<List<Map<String, dynamic>>> getCachedFiles() async {
    try {
      final cache = await _loadCache();
      final files = <Map<String, dynamic>>[];

      for (var entry in cache.entries) {
        final data = entry.value as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp']);
        final age = DateTime.now().difference(timestamp);

        files.add({
          'hash': entry.key.substring(0, 8), // First 8 chars of hash
          'fileName': data['fileName'],
          'timestamp': timestamp.toIso8601String(),
          'ageHours': age.inHours,
          'isExpired': age.inDays > maxCacheAgeDays,
        });
      }

      // Sort by timestamp (newest first)
      files.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      });

      return files;
    } catch (e) {
      print('Error getting cached files: $e');
      return [];
    }
  }
}
