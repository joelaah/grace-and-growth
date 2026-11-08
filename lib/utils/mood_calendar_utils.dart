import 'package:flutter/material.dart';
import '../theme/mood_stage_theme.dart';

/// Mood calendar date math and grid layout utilities.
///
/// Builds the data structure for a weekly or monthly mood history calendar
/// showing which MoodStage the user selected each day.
class MoodCalendarUtils {
  /// Returns all dates in the calendar month grid for [year]/[month].
  ///
  /// The grid always starts on Monday and includes leading/trailing days
  /// from adjacent months to fill complete weeks (6 rows × 7 columns = 42 cells).
  ///
  /// Algorithm:
  /// 1. Find the 1st of the month.
  /// 2. Walk backward to the previous Monday (or stay if the 1st is Monday).
  /// 3. Generate 42 consecutive dates.
  static List<DateTime> calendarGridDates(int year, int month) {
    final firstOfMonth = DateTime(year, month, 1);

    // DateTime.weekday: Monday=1, Sunday=7
    // We want the grid to start on Monday.
    // If the 1st is Wednesday (3), we go back 2 days.
    // offset = (weekday - 1) % 7
    final offset = (firstOfMonth.weekday - 1) % 7;
    final gridStart = firstOfMonth.subtract(Duration(days: offset));

    return List<DateTime>.generate(
      42,
      (i) => gridStart.add(Duration(days: i)),
    );
  }

  /// Returns the number of complete weeks needed to display [year]/[month].
  /// Always 6 rows for a consistent grid height.
  static int weeksInMonthGrid(int year, int month) => 6;

  /// Checks if [date] falls within the month of [year]/[month].
  static bool isInMonth(DateTime date, int year, int month) {
    return date.year == year && date.month == month;
  }

  /// Returns true if [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Formats a date as 'YYYY-MM-DD' for use as a SharedPreferences key.
  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parses a 'YYYY-MM-DD' key back to a DateTime.
  static DateTime? parseKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the color for a mood dot on the calendar.
  static Color moodDotColor(MoodStage? stage) {
    if (stage == null) return const Color(0x33888888); // ghost dot for no data
    return stage.palette.accent;
  }

  /// Computes a 7-day mood streak summary for the past week.
  ///
  /// Returns a list of 7 entries (Monday→Sunday) where each entry is
  /// the MoodStage recorded for that day, or null if no entry.
  static List<MoodStage?> weekStreak(Map<String, MoodStage> moodHistory) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find this week's Monday
    final monday = today.subtract(Duration(days: (today.weekday - 1) % 7));

    return List<MoodStage?>.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final key = dateKey(day);
      return moodHistory[key];
    });
  }

  /// Computes mood distribution percentages from history.
  ///
  /// Returns a Map<MoodStage, double> where values are 0.0–1.0 fractions.
  static Map<MoodStage, double> moodDistribution(
    Map<String, MoodStage> moodHistory,
  ) {
    if (moodHistory.isEmpty) {
      return {for (final stage in MoodStage.values) stage: 0.0};
    }

    final counts = <MoodStage, int>{};
    for (final stage in moodHistory.values) {
      counts[stage] = (counts[stage] ?? 0) + 1;
    }

    final total = moodHistory.length.toDouble();
    return {
      for (final stage in MoodStage.values)
        stage: (counts[stage] ?? 0) / total,
    };
  }

  /// Month names for display.
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Short day-of-week headers (Mon–Sun).
  static const List<String> dayHeaders = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
}
