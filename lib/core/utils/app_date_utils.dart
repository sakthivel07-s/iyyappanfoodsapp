import 'package:intl/intl.dart';

class DateRangeModel {
  final DateTime start;
  final DateTime end;
  final String label;

  const DateRangeModel({
    required this.start,
    required this.end,
    required this.label,
  });
}

class AppDateUtils {
  AppDateUtils._();

  static DateTime get _now => DateTime.now();

  static DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 0, 0, 0, 0);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateRangeModel getToday() {
    final now = _now;
    return DateRangeModel(
      start: _startOfDay(now),
      end: _endOfDay(now),
      label: 'Today',
    );
  }

  static DateRangeModel getYesterday() {
    final yesterday = _now.subtract(const Duration(days: 1));
    return DateRangeModel(
      start: _startOfDay(yesterday),
      end: _endOfDay(yesterday),
      label: 'Yesterday',
    );
  }

  static DateRangeModel getThisWeek() {
    final now = _now;
    final weekday = now.weekday; // Mon=1, Sun=7
    final start = now.subtract(Duration(days: weekday - 1));
    return DateRangeModel(
      start: _startOfDay(start),
      end: _endOfDay(now),
      label: 'This Week',
    );
  }

  static DateRangeModel getLastWeek() {
    final now = _now;
    final weekday = now.weekday;
    final thisWeekStart = now.subtract(Duration(days: weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
    return DateRangeModel(
      start: _startOfDay(lastWeekStart),
      end: _endOfDay(lastWeekEnd),
      label: 'Last Week',
    );
  }

  static DateRangeModel getThisMonth() {
    final now = _now;
    final start = DateTime(now.year, now.month, 1);
    return DateRangeModel(
      start: _startOfDay(start),
      end: _endOfDay(now),
      label: 'This Month',
    );
  }

  static DateRangeModel getLastMonth() {
    final now = _now;
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final lastDayOfLastMonth = firstOfThisMonth.subtract(const Duration(days: 1));
    final firstOfLastMonth = DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, 1);
    return DateRangeModel(
      start: _startOfDay(firstOfLastMonth),
      end: _endOfDay(lastDayOfLastMonth),
      label: 'Last Month',
    );
  }

  static DateRangeModel getThisYear() {
    final now = _now;
    final start = DateTime(now.year, 1, 1);
    return DateRangeModel(
      start: _startOfDay(start),
      end: _endOfDay(now),
      label: 'This Year',
    );
  }

  static DateRangeModel getLastYear() {
    final now = _now;
    final start = DateTime(now.year - 1, 1, 1);
    final end = DateTime(now.year - 1, 12, 31);
    return DateRangeModel(
      start: _startOfDay(start),
      end: _endOfDay(end),
      label: 'Last Year',
    );
  }

  static DateRangeModel getCustomRange(DateTime start, DateTime end) {
    return DateRangeModel(
      start: _startOfDay(start),
      end: _endOfDay(end),
      label: '${formatShort(start)} – ${formatShort(end)}',
    );
  }

  static String formatShort(DateTime date) =>
      DateFormat('d MMM').format(date);

  static String formatDate(DateTime date) =>
      DateFormat('d MMM yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('d MMM yyyy, hh:mm a').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('hh:mm a').format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);
}
