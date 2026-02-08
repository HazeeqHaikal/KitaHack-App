import 'package:intl/intl.dart';

/// Utility class for date formatting
class DateFormatter {
  /// Format date as "Feb 15, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date as "Monday, Feb 15"
  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, MMM dd').format(date);
  }

  /// Format date as "15/02/2026"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date as "Feb 15" (for compact displays)
  static String formatShortDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  /// Format time as "2:30 PM"
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Get relative time string (e.g., "in 5 days", "tomorrow", "today")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1 && difference <= 7) return 'In $difference days';
    if (difference < -1 && difference >= -7) {
      return '${difference.abs()} days ago';
    }
    if (difference > 7) {
      final weeks = (difference / 7).floor();
      return 'In $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }
    if (difference < -7) {
      final weeks = (difference.abs() / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    return formatDate(date);
  }

  /// Get countdown string (e.g., "5 days left", "Due today")
  static String getCountdown(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Due today';
    if (difference == 1) return 'Due tomorrow';
    return '$difference days left';
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is within the next week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return date.isAfter(now) && date.isBefore(nextWeek);
  }

  /// Get month abbreviation (e.g., "JAN", "FEB")
  static String getMonthAbbreviation(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }
}
