import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inshorts_feed_item.dart';
import '../theme/mood_stage_theme.dart';
import '../utils/sanctuary_strings.dart';

/// Interactive modal sheet displaying in-depth Scripture research, translation
/// metadata, canon divisions, and a one-tap action to spread the Gospel with a live link.
class BibleResearchModal extends StatelessWidget {
  final InshortsFeedItem item;
  final StagePalette palette;
  final String langCode;
  final void Function(String message)? onNotice;

  const BibleResearchModal({
    super.key,
    required this.item,
    required this.palette,
    this.langCode = 'eng',
    this.onNotice,
  });

  /// Displays the interactive Bible Research & Gospel Spreading modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required InshortsFeedItem item,
    required StagePalette palette,
    String langCode = 'eng',
    void Function(String message)? onNotice,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BibleResearchModal(
          item: item,
          palette: palette,
          langCode: langCode,
          onNotice: (msg) {
            if (onNotice != null) {
              onNotice(msg);
            } else {
              _showDefaultNotice(context, msg, palette);
            }
          },
        );
      },
    );
  }

  static void _showDefaultNotice(
    BuildContext context,
    String message,
    StagePalette palette,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_outlined, size: 16.0, color: palette.accent),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: palette.primaryText, fontSize: 13.0),
              ),
            ),
          ],
        ),
        backgroundColor: palette.cardSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: palette.cardBorder, width: 1.0),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verse = item.taggedVerse;
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 680;
    final modalHeight = screenHeight * (isShort ? 0.92 : 0.85);

    return Container(
      height: modalHeight,
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                width: 38.0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: palette.secondaryText.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 20.0,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bible Research & Study',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 17.0,
                            fontWeight: FontWeight.w600,
                            color: palette.primaryText,
                          ),
                        ),
                        Text(
                          'Spreading the Gospel through Living Word',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: palette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.0, color: palette.secondaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1.0),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scripture Reference Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        item.attribution,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: palette.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Main Scripture Verse
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: palette.bgTop.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: palette.cardBorder.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '“${item.mainText}”',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16.5,
                          height: 1.5,
                          color: palette.primaryText,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20.0),

                    // Research Details Section
                    Text(
                      'Scripture Context & Details',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: palette.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    _buildResearchDetailRow(
                      palette,
                      'Translation',
                      verse != null
                          ? SanctuaryStrings.translationName(langCode)
                          : 'Curated Contemplative Devotional',
                      Icons.translate_rounded,
                    ),
                    if (verse != null) ...[
                      _buildResearchDetailRow(
                        palette,
                        'Canon Division',
                        SanctuaryStrings.getCanonDivision(verse.book),
                        Icons.account_balance_outlined,
                      ),
                      _buildResearchDetailRow(
                        palette,
                        'Book & Location',
                        'Book: ${verse.book} • Chapter ${verse.chapter}, Verse ${verse.verse}',
                        Icons.bookmark_added_outlined,
                      ),
                      _buildResearchDetailRow(
                        palette,
                        'Theme & Tags',
                        verse.moodTags.join(' • '),
                        Icons.local_offer_outlined,
                      ),
                    ],
                    _buildResearchDetailRow(
                      palette,
                      'Spiritual Aim',
                      'Spreading the Good News of God’s grace, peace, and eternal love.',
                      Icons.favorite_outline_rounded,
                    ),

                    const SizedBox(height: 18.0),

                    // Devotional Reflection
                    Text(
                      'Quiet Devotional Meditation',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: palette.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      item.reflectionContent,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: palette.secondaryText,
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    // Action: Spread the Gospel
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final verseId = verse?.id ?? item.id;
                          final gospelText =
                              '🕊️ Good News for Your Heart:\n\n“${item.mainText}”\n— ${item.attribution}\n\nRead & reflect: https://joelaah.github.io/grace-and-growth/?verse=$verseId\n\nShared with love to spread the Gospel • Grace & Growth Daily Sanctuary';
                          Clipboard.setData(ClipboardData(text: gospelText));
                          try {
                            Share.share(
                              gospelText,
                              subject: 'Spreading the Gospel: ${item.attribution}',
                            );
                          } catch (_) {
                            // Ignore headless test / unsupported platform errors
                          }
                          onNotice?.call('Copied to share gentle comfort');
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.send_rounded, size: 16.0),
                        label: const Text(
                          'Spread This Gospel Verse',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          elevation: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchDetailRow(
    StagePalette palette,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.0, color: palette.accent),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12.5, color: palette.secondaryText),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: palette.primaryText,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
