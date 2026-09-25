import 'package:intl/intl.dart';

import '../ar.dart';

class AppDateUtils {
  static const List<String> arabicDays = Ar.arabicDays;
  static const List<String> arabicMonths = Ar.arabicMonths;

  /// Formats date cleanly in Arabic: مثلاً "الجمعة، 25 سبتمبر 2026"
  static String formatFullDate(DateTime date) {
    try {
      final dayName = arabicDays[date.weekday - 1];
      final monthName = arabicMonths[date.month - 1];
      return '$dayName${Ar.arabicComma}${date.day} $monthName ${date.year}';
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  /// Formats date and time: مثلاً "الجمعة، 25 سبتمبر - 08:30 ص"
  static String formatDateTime(DateTime date) {
    try {
      final dayName = arabicDays[date.weekday - 1];
      final monthName = arabicMonths[date.month - 1];
      final timeStr = formatTime(date);
      return '$dayName${Ar.arabicComma}${date.day} $monthName${Ar.arabicDash}$timeStr';
    } catch (_) {
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
  }

  /// Formats time in 12-hour format: مثلاً "08:30 ص" أو "09:15 م"
  static String formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? Ar.timePm : Ar.timeAm;
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hourStr = hour12.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

  /// Formats TimeOfDay in 12-hour format: مثلاً "08:30 ص" أو "09:15 م"
  static String formatTimeOfDay(dynamic time) {
    final int hour = time.hour;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = hour >= 12 ? Ar.timePm : Ar.timeAm;
    final int hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final String hourStr = hour12.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

  /// Formats short date: مثلاً "25 سبتمبر" أو "25/09/2026"
  static String formatShortDate(DateTime date) {
    try {
      final monthName = arabicMonths[date.month - 1];
      return '${date.day} $monthName';
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Checks if two DateTimes fall on the exact same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if target is tomorrow relative to base (defaults to now)
  static bool isTomorrow(DateTime target, [DateTime? base]) {
    final now = base ?? DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return isSameDay(target, tomorrow);
  }

  /// Checks if target was yesterday relative to base (defaults to now)
  static bool isYesterday(DateTime target, [DateTime? base]) {
    final now = base ?? DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    return isSameDay(target, yesterday);
  }
}
