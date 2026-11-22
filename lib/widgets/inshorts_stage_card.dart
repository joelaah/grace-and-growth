import 'package:flutter/material.dart';
import '../models/inshorts_feed_item.dart';
import '../services/tts_service.dart';
import '../theme/mood_stage_theme.dart';
import 'aesthetic_share_modal.dart';
import 'living_audio_bars.dart';

/// An Inshorts-style split stage card blending Scripture passages and inspirational quotes.
///
/// Top 55%: Source badge, main quote/verse in editorial serif font, and reference/author.
/// Divider line: Floating Listen, Bookmark, and Share buttons.
/// Bottom 45%: "A Gentle Thought" humble reflection + subtle "Swipe up for next" indicator.
class InshortsStageCard extends StatefulWidget {
  final InshortsFeedItem item;
  final StagePalette palette;
  final bool isBookmarked;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onShare;
  final VoidCallback? onResearch;
  final String langCode;

  const InshortsStageCard({
    super.key,
    required this.item,
    required this.palette,
    this.isBookmarked = false,
    this.onBookmarkToggle,
    this.onShare,
    this.onResearch,
    this.langCode = 'eng',
  });

  @override
  State<InshortsStageCard> createState() => _InshortsStageCardState();
}

class _InshortsStageCardState extends State<InshortsStageCard> {
  final GlobalKey _cardBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final isShort = cardHeight < 440 || textScale > 1.25;
        final isVeryShort = cardHeight < 400 || (cardHeight < 500 && textScale > 1.25);
        final isNarrow = constraints.maxWidth < 320 || textScale > 1.25;
        final isWide = constraints.maxWidth >= 720;

        return RepaintBoundary(
          key: _cardBoundaryKey,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            margin: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8.0 : (isWide ? 24.0 : 16.0),
              vertical: isVeryShort ? 2.0 : (isShort ? 4.0 : 8.0),
            ),
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: palette.cardBorder.withValues(alpha: 0.75),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20.0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.08),
                  blurRadius: 32.0,
                  offset: const Offset(0, 4),
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Column(
                children: [
                  // Top 55%: Source badge, main text in serif, and reference/author
                  Expanded(
                    flex: 55,
                    child: _buildTopSection(
                      context,
                      isShort: isShort,
                      isVeryShort: isVeryShort,
                      isNarrow: isNarrow,
                      isWide: isWide,
                    ),
                  ),

                  // Divider line with floating Listen, Bookmark and Share buttons
                  _buildFloatingActionDivider(),

                  // Bottom 45%: "A Gentle Thought" reflection + "Swipe up for next" indicator
                  Expanded(
                    flex: 45,
                    child: _buildBottomSection(
                      context,
                      isShort: isShort,
                      isVeryShort: isVeryShort,
                      isNarrow: isNarrow,
                      isWide: isWide,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Top 55% of the card
  Widget _buildTopSection(
    BuildContext context, {
    required bool isShort,
    required bool isVeryShort,
    required bool isNarrow,
    bool isWide = false,
  }) {
    final palette = widget.palette;
    final item = widget.item;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 4.0 : (isShort ? 10.0 : 18.0),
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 2.0 : (isShort ? 6.0 : 10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single row with Flexible children and FittedBox
          Row(
            children: [
              // Source badge ("BIBLE VERSE" vs. "INSPIRATIONAL QUOTE")
              Flexible(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 6.0 : 8.5,
                    vertical: isVeryShort ? 2.5 : 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isVerse
                              ? Icons.auto_stories_outlined
                              : Icons.format_quote_rounded,
                          size: isVeryShort ? 11.0 : 13.0,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 4.0),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                          style: TextStyle(
                            fontSize: isVeryShort ? 9.0 : 10.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: palette.accent,
                          ),
                          child: Text(item.sourceBadge),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6.0),

              // Category tag pill
              Flexible(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: isVeryShort ? 2.5 : 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: palette.bgTop.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: palette.cardBorder.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.spa_outlined,
                          size: isVeryShort ? 10.0 : 12.0,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 4.0),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                          style: TextStyle(
                            fontSize: isVeryShort ? 9.5 : 11.0,
                            fontWeight: FontWeight.w500,
                            color: palette.secondaryText,
                          ),
                          child: Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isVeryShort ? 2.0 : (isShort ? 6.0 : 12.0)),

          // Main quote/verse text in editorial serif font
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isVeryShort ? 1.0 : (isShort ? 2.0 : 4.0)),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontFamilyFallback: const [
                        'Cormorant Garamond',
                        'Noto Sans Devanagari',
                        'Georgia',
                      ],
                      fontSize: isVeryShort ? 14.0 : (isShort ? 17.0 : 20.0),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: palette.primaryText,
                      letterSpacing: 0.1,
                    ),
                    child: Text(
                      '“${item.mainText}”',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontFamilyFallback: [
                          'Cormorant Garamond',
                          'Noto Sans Devanagari',
                          'Georgia',
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isVeryShort ? 2.0 : (isShort ? 6.0 : 10.0)),

          // Reference / Author & SubTag row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    fontSize: isVeryShort ? 11.0 : (isShort ? 12.0 : 13.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: palette.accent,
                  ),
                  child: Text(
                    item.attribution,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                        width: 4.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                        style: TextStyle(
                          fontSize: isVeryShort ? 9.5 : (isShort ? 10.5 : 11.5),
                          fontWeight: FontWeight.w400,
                          color: palette.secondaryText,
                        ),
                        child: Text(
                          item.subTag,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Divider line with floating Listen, Bookmark, and Share buttons
  Widget _buildFloatingActionDivider() {
    final palette = widget.palette;
    final item = widget.item;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Centered sacred glyph ornament line in champagne gold, visible across flanks
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                      height: 1.0,
                      color: palette.cardBorder.withValues(alpha: 0.55),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      '❖',
                      style: TextStyle(
                        fontSize: 9.0,
                        color: palette.accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                      height: 1.0,
                      color: palette.cardBorder.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                '❖',
                style: TextStyle(
                  fontSize: 10.0,
                  color: palette.accent.withValues(alpha: 0.85),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                      height: 1.0,
                      color: palette.cardBorder.withValues(alpha: 0.55),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      '❖',
                      style: TextStyle(
                        fontSize: 9.0,
                        color: palette.accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                      height: 1.0,
                      color: palette.cardBorder.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Floating action pill
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              color: palette.cardSurface,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: palette.cardBorder.withValues(alpha: 0.7),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Listen (TTS) button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      String? englishFallback;
                      if (widget.langCode == 'lus') {
                        englishFallback = item.taggedVerse?.textFor('eng') ??
                            item.quote?.quote;
                      }
                      TtsService().speak(
                        id: item.id,
                        text: item.mainText,
                        langCode: widget.langCode,
                        englishFallbackText: englishFallback,
                        onNotice: (notice) {
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            SnackBar(
                              content: Text(notice),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 4.0),
                      child: ValueListenableBuilder<String?>(
                        valueListenable: TtsService().currentlySpeakingId,
                        builder: (context, speakingId, _) {
                          final isSpeaking = speakingId == item.id;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSpeaking) ...[
                                LivingAudioBars(
                                  color: palette.accent,
                                  isPlaying: true,
                                ),
                              ] else ...[
                                Icon(
                                  Icons.volume_mute_outlined,
                                  size: 15.0,
                                  color: palette.secondaryText,
                                ),
                              ],
                              const SizedBox(width: 4.0),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: isSpeaking ? FontWeight.w700 : FontWeight.w500,
                                  color: isSpeaking ? palette.accent : palette.secondaryText,
                                ),
                                child: Text(isSpeaking ? 'Playing' : 'Listen'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Separator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  width: 1.0,
                  height: 14.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  color: palette.cardBorder.withValues(alpha: 0.6),
                ),

                // Bookmark button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onBookmarkToggle,
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                            size: 15.0,
                            color: widget.isBookmarked ? palette.accent : palette.secondaryText,
                          ),
                          const SizedBox(width: 4.0),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: widget.isBookmarked ? FontWeight.w600 : FontWeight.w500,
                              color: widget.isBookmarked ? palette.accent : palette.secondaryText,
                            ),
                            child: Text(widget.isBookmarked ? 'Saved' : 'Save'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Separator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  width: 1.0,
                  height: 14.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  color: palette.cardBorder.withValues(alpha: 0.6),
                ),

                // Share button (Aesthetic Card Share Modal)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (widget.onShare != null) {
                        widget.onShare!();
                      }
                      await AestheticShareModal.show(
                        context,
                        item: item,
                        palette: palette,
                      );
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 14.5,
                            color: palette.secondaryText,
                          ),
                          const SizedBox(width: 4.0),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: palette.secondaryText,
                            ),
                            child: const Text('Share'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (widget.onResearch != null) ...[
                  // Separator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    width: 1.0,
                    height: 14.0,
                    margin: const EdgeInsets.symmetric(horizontal: 3.0),
                    color: palette.cardBorder.withValues(alpha: 0.6),
                  ),

                  // Research / Bible Study button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onResearch,
                      borderRadius: BorderRadius.circular(16.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 14.5,
                              color: palette.accent,
                            ),
                            const SizedBox(width: 4.0),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: palette.accent,
                              ),
                              child: const Text('Research'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom 45% of the card
  Widget _buildBottomSection(
    BuildContext context, {
    required bool isShort,
    required bool isVeryShort,
    required bool isNarrow,
    bool isWide = false,
  }) {
    final palette = widget.palette;
    final item = widget.item;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      color: palette.cardSurface.withValues(alpha: 0.7),
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 4.0 : (isShort ? 8.0 : 14.0),
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 2.0 : (isShort ? 4.0 : 8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon, title, and reading time
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                width: isVeryShort ? 20.0 : (isShort ? 24.0 : 28.0),
                height: isVeryShort ? 20.0 : (isShort ? 24.0 : 28.0),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volunteer_activism_outlined,
                  size: isVeryShort ? 10.0 : (isShort ? 12.0 : 14.0),
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                        style: TextStyle(
                          fontSize: isVeryShort ? 12.0 : (isShort ? 13.0 : 14.5),
                          fontWeight: FontWeight.w600,
                          color: palette.primaryText,
                        ),
                        child: Text(item.reflectionTitle),
                      ),
                      const SizedBox(width: 8.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 11.0,
                            color: palette.secondaryText.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 3.0),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                              color: palette.secondaryText,
                            ),
                            child: Text(item.readingTime),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isVeryShort ? 2.0 : (isShort ? 4.0 : 8.0)),

          // Humble reflection body (2-3 sentences)
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: isVeryShort ? 11.0 : (isShort ? 12.5 : 13.5),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: palette.primaryText.withValues(alpha: 0.9),
                    ),
                    child: Text(item.reflectionContent),
                  ),
                  SizedBox(height: isVeryShort ? 2.0 : (isShort ? 4.0 : 8.0)),
                  // Ambient prompt
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.arrow_right_alt_rounded,
                          size: isVeryShort ? 12.0 : 14.0,
                          color: palette.accent.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                          style: TextStyle(
                            fontSize: isVeryShort ? 10.0 : (isShort ? 11.0 : 12.0),
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                            color: palette.secondaryText,
                          ),
                          child: Text(item.promptText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Subtle "Swipe up for next" indicator at the bottom (omitted on very short viewports)
          if (!isVeryShort)
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: isShort ? 1.0 : 2.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 16.0,
                        color: palette.secondaryText.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 2.0),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutCubic,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.4,
                          color: palette.secondaryText.withValues(alpha: 0.55),
                        ),
                        child: const Text('Swipe up for next'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
