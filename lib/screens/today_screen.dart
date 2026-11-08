import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tagged_verse.dart';
import '../models/inshorts_feed_item.dart';
import '../services/quote_api_service.dart';
import '../theme/mood_stage_theme.dart';
import '../utils/daily_selection_engine.dart';
import '../widgets/contemplation_timer.dart';
import '../widgets/notification_time_picker.dart';

/// The "Today" tab screen showing daily curated content and contemplation tools.
///
/// Features:
/// - Verse of the Day (deterministic via Knuth hash)
/// - Quote of the Day
/// - Contemplation breathing timer with selectable durations
/// - Daily intention text field
class TodayScreen extends StatefulWidget {
  final StagePalette palette;
  final List<TaggedVerse> verses;
  final List<InspirationalQuote> quotes;
  final String langCode;
  final Set<String> bookmarkedIds;
  final ValueChanged<String>? onBookmarkToggle;

  const TodayScreen({
    super.key,
    required this.palette,
    required this.verses,
    required this.quotes,
    this.langCode = 'eng',
    this.bookmarkedIds = const {},
    this.onBookmarkToggle,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final TextEditingController _intentionController = TextEditingController();
  int _timerDuration = 60; // Default 1 minute
  bool _intentionSaved = false;

  @override
  void initState() {
    super.initState();
    _loadDailyIntention();
  }

  @override
  void dispose() {
    _intentionController.dispose();
    super.dispose();
  }

  String get _todayKey {
    final now = DateTime.now();
    return 'daily_intention_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDailyIntention() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_todayKey);
    if (saved != null && mounted) {
      setState(() {
        _intentionController.text = saved;
        _intentionSaved = true;
      });
    }
  }

  Future<void> _saveDailyIntention() async {
    final text = _intentionController.text.trim();
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayKey, text);
    if (mounted) {
      setState(() => _intentionSaved = true);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final todaysVerse = DailySelectionEngine.todaysVerseItem(
      widget.verses,
      langCode: widget.langCode,
    );
    final todaysQuote = DailySelectionEngine.todaysQuoteItem(
      widget.quotes,
      langCode: widget.langCode,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Verse of the Day with Reminder quick-action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                palette,
                icon: Icons.auto_stories_outlined,
                title: 'Verse of the Day',
              ),
              InkWell(
                onTap: () => NotificationTimePickerModal.show(context, palette),
                borderRadius: BorderRadius.circular(16.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 15.0, color: palette.accent),
                      const SizedBox(width: 4.0),
                      Text(
                        'Reminder',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (todaysVerse != null)
            _buildContentCard(palette, todaysVerse)
          else
            _buildEmptyCard(palette, 'No verse available today'),

          const SizedBox(height: 24),

          // Section: Quote of the Day
          _buildSectionHeader(
            palette,
            icon: Icons.format_quote_rounded,
            title: 'Quote of the Day',
          ),
          const SizedBox(height: 10),
          if (todaysQuote != null)
            _buildContentCard(palette, todaysQuote)
          else
            _buildEmptyCard(palette, 'No quote available today'),

          const SizedBox(height: 28),

          // Section: Contemplation Timer
          _buildSectionHeader(
            palette,
            icon: Icons.self_improvement_outlined,
            title: 'Quiet Moment',
          ),
          const SizedBox(height: 6),
          Text(
            'Take a breath. Be still for a moment.',
            style: TextStyle(
              fontSize: 13,
              color: palette.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),

          // Duration chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDurationChip(palette, 60, '1 min'),
              const SizedBox(width: 8),
              _buildDurationChip(palette, 120, '2 min'),
              const SizedBox(width: 8),
              _buildDurationChip(palette, 180, '3 min'),
            ],
          ),
          const SizedBox(height: 16),

          // Timer widget
          Center(
            child: ContemplationTimer(
              key: ValueKey('timer_$_timerDuration'),
              durationSeconds: _timerDuration,
              accentColor: palette.accent,
              textColor: palette.primaryText,
              ringBackgroundColor: palette.cardBorder,
              onComplete: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Peace be with you',
                        style: TextStyle(color: palette.primaryText),
                      ),
                      backgroundColor: palette.cardSurface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 28),

          // Section: Daily Intention
          _buildSectionHeader(
            palette,
            icon: Icons.edit_outlined,
            title: 'Daily Intention',
          ),
          const SizedBox(height: 6),
          Text(
            'Set a single focus for today.',
            style: TextStyle(
              fontSize: 13,
              color: palette.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: palette.cardBorder.withValues(alpha: 0.6),
              ),
            ),
            child: TextField(
              controller: _intentionController,
              maxLines: 2,
              style: TextStyle(
                fontSize: 15,
                color: palette.primaryText,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Today I will be present in...',
                hintStyle: TextStyle(
                  color: palette.secondaryText.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  onPressed: _saveDailyIntention,
                  icon: Icon(
                    _intentionSaved
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: _intentionSaved
                        ? palette.accent
                        : palette.secondaryText,
                    size: 22,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_intentionSaved) {
                  setState(() => _intentionSaved = false);
                }
              },
              onSubmitted: (_) => _saveDailyIntention(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    StagePalette palette, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: palette.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(StagePalette palette, InshortsFeedItem item) {
    final isBookmarked = widget.bookmarkedIds.contains(item.id);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isVerse
                      ? Icons.auto_stories_outlined
                      : Icons.format_quote_rounded,
                  size: 12,
                  color: palette.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  item.sourceBadge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Main text
          Text(
            '\u201c${item.mainText}\u201d',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 17,
              height: 1.45,
              color: palette.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          // Attribution + actions
          Row(
            children: [
              Expanded(
                child: Text(
                  item.attribution,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.accent,
                  ),
                ),
              ),
              // Bookmark
              GestureDetector(
                onTap: () => widget.onBookmarkToggle?.call(item.id),
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  size: 20,
                  color: isBookmarked
                      ? palette.accent
                      : palette.secondaryText,
                ),
              ),
            ],
          ),
          if (item.reflectionContent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.bgTop.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.reflectionContent,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: palette.primaryText.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(StagePalette palette, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: palette.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(StagePalette palette, int seconds, String label) {
    final isSelected = _timerDuration == seconds;
    return GestureDetector(
      onTap: () => setState(() => _timerDuration = seconds),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent
              : palette.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? palette.accent
                : palette.cardBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : palette.secondaryText,
          ),
        ),
      ),
    );
  }
}
