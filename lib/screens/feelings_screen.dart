import 'package:flutter/material.dart';
import '../services/journal_storage.dart';
import '../theme/mood_stage_theme.dart';
import '../utils/mood_calendar_utils.dart';

/// The "Feelings" tab screen showing mood history as a calendar, streak, and distribution bar.
///
/// Features:
/// - Weekly mood streak (7 colored dots, Mon→Sun)
/// - Monthly calendar grid (6×7 with mood dots)
/// - Mood distribution horizontal stacked bar
/// - Month navigation arrows
class FeelingsScreen extends StatefulWidget {
  final StagePalette palette;
  final JournalStorage? journalStorage;

  const FeelingsScreen({
    super.key,
    required this.palette,
    this.journalStorage,
  });

  @override
  State<FeelingsScreen> createState() => _FeelingsScreenState();
}

class _FeelingsScreenState extends State<FeelingsScreen> {
  late final JournalStorage _storage;
  late int _currentYear;
  late int _currentMonth;
  Map<String, MoodStage> _moodHistory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storage = widget.journalStorage ?? JournalStorage();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    final history = await _storage.getMoodHistory();
    if (mounted) {
      setState(() {
        _moodHistory = history;
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth--;
      if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentYear > now.year ||
        (_currentYear == now.year && _currentMonth >= now.month)) {
      return; // Don't go past current month
    }
    setState(() {
      _currentMonth++;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Mood Streak
          _buildSectionHeader(palette, 'This Week'),
          const SizedBox(height: 12),
          _buildWeekStreak(palette),

          const SizedBox(height: 28),

          // Monthly Calendar
          _buildMonthNav(palette),
          const SizedBox(height: 12),
          _buildCalendarGrid(palette),

          const SizedBox(height: 28),

          // Mood Distribution
          _buildSectionHeader(palette, 'Mood Distribution'),
          const SizedBox(height: 12),
          _buildMoodDistribution(palette),

          const SizedBox(height: 16),

          // Legend
          _buildLegend(palette),

          // Empty state hint
          if (_moodHistory.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.psychology_alt_outlined,
                    size: 40,
                    color: palette.secondaryText.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your mood journey begins here',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a mood chip each day to track\nhow your heart moves over time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(StagePalette palette, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.primaryText,
      ),
    );
  }

  /// 7 dots (Mon→Sun) colored by the mood recorded for each day.
  Widget _buildWeekStreak(StagePalette palette) {
    final streak = MoodCalendarUtils.weekStreak(_moodHistory);
    final now = DateTime.now();
    final todayWeekdayIndex = (now.weekday - 1) % 7; // Mon=0, Sun=6

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final mood = streak[i];
          final isToday = i == todayWeekdayIndex;
          final dotColor = MoodCalendarUtils.moodDotColor(mood);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                MoodCalendarUtils.dayHeaders[i].substring(0, 1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isToday ? palette.accent : palette.secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: isToday
                      ? Border.all(color: palette.accent, width: 2.5)
                      : null,
                  boxShadow: mood != null
                      ? [
                          BoxShadow(
                            color: dotColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              if (mood != null) ...[
                const SizedBox(height: 4),
                Text(
                  mood.palette.stageLabel.split(' ').first,
                  style: TextStyle(
                    fontSize: 8,
                    color: palette.secondaryText,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthNav(StagePalette palette) {
    final monthName = MoodCalendarUtils.monthNames[_currentMonth - 1];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionHeader(palette, '$monthName $_currentYear'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(
                Icons.chevron_left_rounded,
                color: palette.secondaryText,
              ),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: Icon(
                Icons.chevron_right_rounded,
                color: palette.secondaryText,
              ),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  /// 6×7 calendar grid with colored mood dots.
  Widget _buildCalendarGrid(StagePalette palette) {
    final gridDates =
        MoodCalendarUtils.calendarGridDates(_currentYear, _currentMonth);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Day headers
          Row(
            children: MoodCalendarUtils.dayHeaders.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day.substring(0, 1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.secondaryText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Grid
          ...List.generate(6, (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final date = gridDates[row * 7 + col];
                  final isCurrentMonth = MoodCalendarUtils.isInMonth(
                      date, _currentYear, _currentMonth);
                  final isToday = MoodCalendarUtils.isToday(date);
                  final key = MoodCalendarUtils.dateKey(date);
                  final mood = _moodHistory[key];
                  final dotColor = MoodCalendarUtils.moodDotColor(mood);

                  return Expanded(
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isToday
                              ? Border.all(
                                  color: palette.accent, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isCurrentMonth
                                      ? palette.primaryText
                                      : palette.secondaryText
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                              if (isCurrentMonth)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: mood != null
                                        ? dotColor
                                        : dotColor.withValues(alpha: 0.2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Horizontal stacked bar showing mood distribution.
  Widget _buildMoodDistribution(StagePalette palette) {
    final distribution = MoodCalendarUtils.moodDistribution(_moodHistory);
    final hasData = _moodHistory.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 16,
              child: hasData
                  ? Row(
                      children: MoodStage.values.map((stage) {
                        final fraction = distribution[stage] ?? 0.0;
                        if (fraction <= 0) return const SizedBox.shrink();
                        return Expanded(
                          flex: (fraction * 1000).round(),
                          child: Container(
                            color: stage.palette.accent,
                          ),
                        );
                      }).toList(),
                    )
                  : Container(
                      color: palette.cardBorder.withValues(alpha: 0.3),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Percentage labels
          if (hasData)
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: MoodStage.values.map((stage) {
                final fraction = distribution[stage] ?? 0.0;
                final percent = (fraction * 100).round();
                if (percent <= 0) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stage.palette.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.primaryText,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(StagePalette palette) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: MoodStage.values.map((stage) {
        final sp = stage.palette;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sp.accent,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              sp.stageLabel,
              style: TextStyle(
                fontSize: 11,
                color: palette.secondaryText,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
