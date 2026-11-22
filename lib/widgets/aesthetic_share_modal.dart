import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inshorts_feed_item.dart';
import '../theme/mood_stage_theme.dart';
import '../utils/card_image_capture.dart';
import '../utils/web_download_helper.dart';
import 'shareable_card.dart';

/// Modal dialog / bottom sheet providing an aesthetic preview of the shareable
/// devotional card with theme switching (Sanctuary Twilight / Sacred Scripture)
/// and direct image export / sharing.
class AestheticShareModal extends StatefulWidget {
  final InshortsFeedItem item;
  final StagePalette initialPalette;
  final void Function(String message)? onNotice;

  const AestheticShareModal({
    super.key,
    required this.item,
    required this.initialPalette,
    this.onNotice,
  });

  /// Displays the aesthetic card sharing modal.
  static Future<void> show(
    BuildContext context, {
    required InshortsFeedItem item,
    required StagePalette palette,
    void Function(String message)? onNotice,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return AestheticShareModal(
          item: item,
          initialPalette: palette,
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
  State<AestheticShareModal> createState() => _AestheticShareModalState();
}

class _AestheticShareModalState extends State<AestheticShareModal> {
  final GlobalKey _previewBoundaryKey = GlobalKey();
  late StagePalette _selectedPalette;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default to a canonical spiritual palette
    _selectedPalette = widget.initialPalette.isDarkPalette
        ? StagePalette.bibleDark
        : StagePalette.bibleLight;
  }

  Future<void> _shareCardImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final item = widget.item;
    final verseId = item.taggedVerse?.id ??
        (item.id.startsWith('verse_') ? item.id.substring(6) : item.id);
    final filename = 'grace_and_growth_$verseId.png';
    final liveLink = 'https://joelaah.github.io/grace-and-growth/?verse=$verseId';
    final shareText =
        '“${item.mainText}”\n— ${item.attribution}\n\nRead & reflect: $liveLink\n\n🕊️ Spreading the Gospel • Grace & Growth Sanctuary';

    try {
      final Uint8List? pngBytes = await CardImageCapture.captureAsPng(
        _previewBoundaryKey,
        pixelRatio: 3.0,
      );

      if (pngBytes != null && pngBytes.isNotEmpty) {
        if (kIsWeb) {
          WebDownloadHelper.download(pngBytes, filename);
          try {
            await Share.shareXFiles(
              [
                XFile.fromData(
                  pngBytes,
                  mimeType: 'image/png',
                  name: filename,
                ),
              ],
              text: shareText,
            );
          } catch (_) {
            await Clipboard.setData(ClipboardData(text: shareText));
          }
        } else {
          try {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/$filename');
            await file.writeAsBytes(pngBytes);

            await Share.shareXFiles(
              [XFile(file.path, mimeType: 'image/png')],
              text: shareText,
            );
          } catch (_) {
            await Clipboard.setData(ClipboardData(text: shareText));
          }
        }
        widget.onNotice?.call('Image prepared for sharing gentle comfort');
      } else {
        await Clipboard.setData(ClipboardData(text: shareText));
        widget.onNotice?.call('Copied to share gentle comfort');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      widget.onNotice?.call('Copied to share gentle comfort');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _copyTextOnly() async {
    final item = widget.item;
    final verseId = item.taggedVerse?.id ??
        (item.id.startsWith('verse_') ? item.id.substring(6) : item.id);
    final liveLink = 'https://joelaah.github.io/grace-and-growth/?verse=$verseId';
    final shareText =
        '“${item.mainText}”\n— ${item.attribution}\n\nRead & reflect: $liveLink\n\n🕊️ Spreading the Gospel • Grace & Growth Sanctuary';
    try {
      Clipboard.setData(ClipboardData(text: shareText));
    } catch (_) {
      // Platform or headless safety
    }
    widget.onNotice?.call('Copied to share gentle comfort');
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 680;
    final modalHeight = screenHeight * (isShort ? 0.94 : 0.88);
    final palette = _selectedPalette;

    return Container(
      constraints: BoxConstraints(maxHeight: modalHeight),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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

              // Header with theme toggle
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
                        Icons.palette_outlined,
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
                            'Aesthetic Card Sharing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 17.0,
                              fontWeight: FontWeight.w600,
                              color: palette.primaryText,
                            ),
                          ),
                          Text(
                            'Select sanctuary theme & share the Word',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

              // Theme selector pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                child: Row(
                  children: [
                    _buildThemeOption(
                      label: 'Sanctuary Twilight',
                      isDark: true,
                      isSelected: _selectedPalette.isDarkPalette,
                    ),
                    const SizedBox(width: 8.0),
                    _buildThemeOption(
                      label: 'Sacred Scripture',
                      isDark: false,
                      isSelected: !_selectedPalette.isDarkPalette,
                    ),
                  ],
                ),
              ),

              const Divider(height: 16.0),

              // Card Preview Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 380.0,
                      maxHeight: isShort ? 280.0 : 400.0,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 380.0,
                        child: RepaintBoundary(
                          key: _previewBoundaryKey,
                          child: ShareableCard(
                            item: widget.item,
                            palette: _selectedPalette,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 16.0),
                decoration: BoxDecoration(
                  color: palette.cardSurface,
                  border: Border(
                    top: BorderSide(
                      color: palette.cardBorder.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Copy text button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _copyTextOnly,
                        icon: const Icon(Icons.copy_rounded, size: 16.0),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Copy Text',
                            style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.primaryText,
                          side: BorderSide(color: palette.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    // Export / Share image button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _shareCardImage,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 16.0,
                                height: 16.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.share_rounded, size: 16.0),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            kIsWeb ? 'Download & Share Card' : 'Share Devotional Card',
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          elevation: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required bool isDark,
    required bool isSelected,
  }) {
    final currentPalette = _selectedPalette;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPalette = isDark ? StagePalette.bibleDark : StagePalette.bibleLight;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? currentPalette.accent.withValues(alpha: 0.18)
                : currentPalette.bgTop.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? currentPalette.accent : currentPalette.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                size: 14.0,
                color: isSelected ? currentPalette.accent : currentPalette.secondaryText,
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? currentPalette.primaryText : currentPalette.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
