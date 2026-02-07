import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking Gemini API usage and estimated costs
/// Helps monitor spending during development and testing
class UsageTrackingService {
  static const String _usageKey = 'api_usage_log';
  static const String _dailyLimitKey = 'api_daily_limit';

  // Gemini 2.5 Pro pricing (as of Feb 2026)
  // Input: $3.50 per 1M tokens
  // Output: $10.50 per 1M tokens
  // Rough estimates per operation type:
  static const double syllabusAnalysisCostRM = 0.12; // ~10K input + 2K output
  static const double effortEstimationCostRM = 0.02; // ~500 input + 300 output

  // Daily limit threshold (number of calls)
  static const int defaultDailyLimit = 10; // ~RM 1.50/day max

  /// Log an API call
  Future<void> logApiCall(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = await _getUsageLogs();

      final logEntry = {
        'type': type, // 'syllabus' or 'effort'
        'timestamp': DateTime.now().toIso8601String(),
        'cost': type == 'syllabus'
            ? syllabusAnalysisCostRM
            : effortEstimationCostRM,
      };

      logs.add(logEntry);

      // Keep only last 1000 entries to prevent storage bloat
      if (logs.length > 1000) {
        logs.removeRange(0, logs.length - 1000);
      }

      await prefs.setString(_usageKey, json.encode(logs));
      print('Logged API call: $type (estimated cost: RM ${logEntry['cost']})');
    } catch (e) {
      print('Error logging API call: $e');
    }
  }

  /// Get all usage logs
  Future<List<Map<String, dynamic>>> _getUsageLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_usageKey);

      if (logsJson == null || logsJson.isEmpty) {
        return [];
      }

      final List<dynamic> logsList = json.decode(logsJson);
      return logsList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading usage logs: $e');
      return [];
    }
  }

  /// Get total API calls (all time)
  Future<int> getTotalCalls() async {
    final logs = await _getUsageLogs();
    return logs.length;
  }

  /// Get API calls for today
  Future<int> getTodayCalls() async {
    final logs = await _getUsageLogs();
    final today = DateTime.now();
    final todayLogs = logs.where((log) {
      final timestamp = DateTime.parse(log['timestamp']);
      return timestamp.year == today.year &&
          timestamp.month == today.month &&
          timestamp.day == today.day;
    });
    return todayLogs.length;
  }

  /// Get API calls for this week
  Future<int> getWeekCalls() async {
    final logs = await _getUsageLogs();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekLogs = logs.where((log) {
      final timestamp = DateTime.parse(log['timestamp']);
      return timestamp.isAfter(weekAgo);
    });
    return weekLogs.length;
  }

  /// Get estimated total cost (all time)
  Future<double> getEstimatedCost() async {
    final logs = await _getUsageLogs();
    double total = 0;
    for (var log in logs) {
      total += (log['cost'] as num).toDouble();
    }
    return total;
  }

  /// Get estimated cost for today
  Future<double> getTodayCost() async {
    final logs = await _getUsageLogs();
    final today = DateTime.now();
    double total = 0;
    for (var log in logs) {
      final timestamp = DateTime.parse(log['timestamp']);
      if (timestamp.year == today.year &&
          timestamp.month == today.month &&
          timestamp.day == today.day) {
        total += (log['cost'] as num).toDouble();
      }
    }
    return total;
  }

  /// Get estimated cost for this week
  Future<double> getWeekCost() async {
    final logs = await _getUsageLogs();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    double total = 0;
    for (var log in logs) {
      final timestamp = DateTime.parse(log['timestamp']);
      if (timestamp.isAfter(weekAgo)) {
        total += (log['cost'] as num).toDouble();
      }
    }
    return total;
  }

  /// Get breakdown by type
  Future<Map<String, int>> getCallsByType() async {
    final logs = await _getUsageLogs();
    int syllabusCount = 0;
    int effortCount = 0;

    for (var log in logs) {
      if (log['type'] == 'syllabus') {
        syllabusCount++;
      } else if (log['type'] == 'effort') {
        effortCount++;
      }
    }

    return {'syllabus': syllabusCount, 'effort': effortCount};
  }

  /// Get last API call timestamp
  Future<DateTime?> getLastCallTime() async {
    final logs = await _getUsageLogs();
    if (logs.isEmpty) return null;

    final lastLog = logs.last;
    return DateTime.parse(lastLog['timestamp']);
  }

  /// Check if today's calls exceed daily limit
  Future<bool> isDailyLimitExceeded() async {
    final todayCalls = await getTodayCalls();
    final limit = await getDailyLimit();
    return todayCalls >= limit;
  }

  /// Get daily limit
  Future<int> getDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyLimitKey) ?? defaultDailyLimit;
  }

  /// Set daily limit
  Future<void> setDailyLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyLimitKey, limit);
  }

  /// Reset all usage statistics
  Future<void> resetTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usageKey);
      print('Usage tracking reset successfully');
    } catch (e) {
      print('Error resetting tracking: $e');
      rethrow;
    }
  }

  /// Get usage statistics summary
  Future<Map<String, dynamic>> getUsageSummary() async {
    final totalCalls = await getTotalCalls();
    final todayCalls = await getTodayCalls();
    final weekCalls = await getWeekCalls();
    final totalCost = await getEstimatedCost();
    final todayCost = await getTodayCost();
    final weekCost = await getWeekCost();
    final breakdown = await getCallsByType();
    final lastCall = await getLastCallTime();
    final limitExceeded = await isDailyLimitExceeded();

    return {
      'totalCalls': totalCalls,
      'todayCalls': todayCalls,
      'weekCalls': weekCalls,
      'totalCost': totalCost,
      'todayCost': todayCost,
      'weekCost': weekCost,
      'syllabusCount': breakdown['syllabus'] ?? 0,
      'effortCount': breakdown['effort'] ?? 0,
      'lastCallTime': lastCall?.toIso8601String(),
      'limitExceeded': limitExceeded,
    };
  }

  /// Get cost indicator color (for UI)
  /// Returns: 'green' (<RM 1), 'yellow' (RM 1-5), 'red' (>RM 5)
  String getCostIndicatorColor(double cost) {
    if (cost < 1.0) return 'green';
    if (cost < 5.0) return 'yellow';
    return 'red';
  }
}
