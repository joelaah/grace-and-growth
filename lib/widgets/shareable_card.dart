import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inshorts_feed_item.dart';
import '../theme/mood_stage_theme.dart';
import '../utils/card_image_capture.dart';

/// A standalone, high-resolution aesthetic devotional card designed for export and sharing.
class ShareableCard extends StatelessWidget {
  final InshortsFeedItem item;
  final StagePalette palette;

  const ShareableCard({
    super.key,
    required this.item,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420.0,
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.bgTop,
            palette.bgBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30.0,
            offset: const Offset(0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Source badge and mood label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isVerse
                          ? Icons.auto_stories_outlined
                          : Icons.format_quote_rounded,
                      size: 14.0,
                      color: palette.accent,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      item.sourceBadge,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7.0,
                    height: 7.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Text(
                    palette.stageLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28.0),

          // Main scripture or quote text
          Text(
            '“${item.mainText}”',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 21.0,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: palette.primaryText,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 18.0),

          // Attribution reference
          Text(
            item.attribution,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: palette.accent,
            ),
          ),

          const SizedBox(height: 22.0),

          // Divider
          Divider(
            color: palette.cardBorder.withValues(alpha: 0.5),
            thickness: 1.0,
          ),

          const SizedBox(height: 14.0),

          // Reflection excerpt
          if (item.reflectionContent.isNotEmpty) ...[
            Text(
              item.reflectionContent,
              style: TextStyle(
                fontSize: 13.0,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: palette.primaryText.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 18.0),
          ],

          // Watermark footer
          Row(
            children: [
              Icon(
                Icons.spa_rounded,
                size: 15.0,
                color: palette.accent,
              ),
              const SizedBox(width: 6.0),
              Text(
                'Grace & Growth',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: palette.primaryText.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                '• Daily Sanctuary',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: palette.secondaryText.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Utility method to share the card either as an image or formatted text fallback.
  static Future<bool> shareItemAsImage({
    required BuildContext context,
    required GlobalKey boundaryKey,
    required InshortsFeedItem item,
  }) async {
    try {
      final Uint8List? pngBytes = await CardImageCapture.captureAsPng(
        boundaryKey,
        pixelRatio: 3.0,
      );

      final shareText = '“${item.mainText}”\n— ${item.attribution}\n\nShared from Grace & Growth • Daily Sanctuary';

      if (pngBytes != null && pngBytes.isNotEmpty) {
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/grace_and_growth_${item.id}.png');
          await file.writeAsBytes(pngBytes);

          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'image/png')],
            text: shareText,
          );
          return true;
        } else {
          // On Web, try sharing XFile from bytes
          try {
            await Share.shareXFiles(
              [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'grace_and_growth.png')],
              text: shareText,
            );
            return true;
          } catch (_) {
            // Fallback to clipboard
            await Clipboard.setData(ClipboardData(text: shareText));
            return false;
          }
        }
      } else {
        // Fallback to text copy
        await Clipboard.setData(ClipboardData(text: shareText));
        return false;
      }
    } catch (_) {
      // Graceful fallback to text
      final shareText = '“${item.mainText}”\n— ${item.attribution}\n\nShared from Grace & Growth';
      await Clipboard.setData(ClipboardData(text: shareText));
      return false;
    }
  }
}
