import 'package:flutter/material.dart';
import '../models/inshorts_feed_item.dart';
import '../services/tts_service.dart';
import '../theme/mood_stage_theme.dart';
import 'shareable_card.dart';

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
        final isVeryShort = cardHeight < 340 || (cardHeight < 400 && textScale > 1.25);
        final isNarrow = constraints.maxWidth < 320 || textScale > 1.25;
        final isWide = constraints.maxWidth >= 720;

        return RepaintBoundary(
          key: _cardBoundaryKey,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8.0 : (isWide ? 24.0 : 16.0),
              vertical: isShort ? 4.0 : 8.0,
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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20.0,
                  offset: const Offset(0, 6),
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 6.0 : (isShort ? 10.0 : 18.0),
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 4.0 : (isShort ? 6.0 : 10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single row with Flexible children and FittedBox
          Row(
            children: [
              // Source badge ("BIBLE VERSE" vs. "INSPIRATIONAL QUOTE")
              Flexible(
                child: Container(
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
                        Text(
                          item.sourceBadge,
                          style: TextStyle(
                            fontSize: isVeryShort ? 9.0 : 10.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6.0),

              // Category tag pill
              Flexible(
                child: Container(
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
                        Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isVeryShort ? 9.5 : 11.0,
                            fontWeight: FontWeight.w500,
                            color: palette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isVeryShort ? 3.0 : (isShort ? 6.0 : 12.0)),

          // Main quote/verse text in editorial serif font
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isVeryShort ? 1.0 : (isShort ? 2.0 : 4.0)),
                  child: Text(
                    '“${item.mainText}”',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: isVeryShort ? 14.0 : (isShort ? 17.0 : 20.0),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: palette.primaryText,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isVeryShort ? 3.0 : (isShort ? 6.0 : 10.0)),

          // Reference / Author & SubTag row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.attribution,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isVeryShort ? 11.0 : (isShort ? 12.0 : 13.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: palette.accent,
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
                      Container(
                        width: 4.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        item.subTag,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: isVeryShort ? 9.5 : (isShort ? 10.5 : 11.5),
                          fontWeight: FontWeight.w400,
                          color: palette.secondaryText,
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
        // Horizontal divider line
        Divider(
          height: 1.0,
          thickness: 1.0,
          color: palette.cardBorder.withValues(alpha: 0.55),
        ),

        // Floating action pill
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
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
                      TtsService().speak(
                        id: item.id,
                        text: item.mainText,
                        langCode: widget.langCode,
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
                              Icon(
                                isSpeaking
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_mute_outlined,
                                size: 15.0,
                                color: isSpeaking ? palette.accent : palette.secondaryText,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                isSpeaking ? 'Playing' : 'Listen',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: isSpeaking ? FontWeight.w700 : FontWeight.w500,
                                  color: isSpeaking ? palette.accent : palette.secondaryText,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Separator
                Container(
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
                          Text(
                            widget.isBookmarked ? 'Saved' : 'Save',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: widget.isBookmarked ? FontWeight.w600 : FontWeight.w500,
                              color: widget.isBookmarked ? palette.accent : palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Separator
                Container(
                  width: 1.0,
                  height: 14.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  color: palette.cardBorder.withValues(alpha: 0.6),
                ),

                // Share button (Image export + share)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (widget.onShare != null) {
                        widget.onShare!();
                      }
                      await ShareableCard.shareItemAsImage(
                        context: context,
                        boundaryKey: _cardBoundaryKey,
                        item: item,
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
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                              color: palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (widget.onResearch != null) ...[
                  // Separator
                  Container(
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
                            Text(
                              'Research',
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: palette.accent,
                              ),
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

    return Container(
      color: palette.cardSurface.withValues(alpha: 0.7),
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 5.0 : (isShort ? 8.0 : 14.0),
        isNarrow ? 12.0 : (isWide ? 28.0 : 20.0),
        isVeryShort ? 3.0 : (isShort ? 4.0 : 8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon, title, and reading time
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
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
                      Text(
                        item.reflectionTitle,
                        style: TextStyle(
                          fontSize: isVeryShort ? 12.0 : (isShort ? 13.0 : 14.5),
                          fontWeight: FontWeight.w600,
                          color: palette.primaryText,
                        ),
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
                          Text(
                            item.readingTime,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                              color: palette.secondaryText,
                            ),
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
                  Text(
                    item.reflectionContent,
                    style: TextStyle(
                      fontSize: isVeryShort ? 11.0 : (isShort ? 12.5 : 13.5),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      color: palette.primaryText.withValues(alpha: 0.9),
                    ),
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
                        child: Text(
                          item.promptText,
                          style: TextStyle(
                            fontSize: isVeryShort ? 10.0 : (isShort ? 11.0 : 12.0),
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                            color: palette.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Subtle "Swipe up for next" indicator at the bottom
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
                      size: isVeryShort ? 14.0 : 16.0,
                      color: palette.secondaryText.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      'Swipe up for next',
                      style: TextStyle(
                        fontSize: isVeryShort ? 9.5 : 10.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.4,
                        color: palette.secondaryText.withValues(alpha: 0.55),
                      ),
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
