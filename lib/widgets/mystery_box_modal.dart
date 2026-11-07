import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/inshorts_feed_item.dart';
import '../services/mystery_box_engine.dart';
import '../theme/mood_stage_theme.dart';
import 'inshorts_stage_card.dart';

/// A calm, contemplative modal sheet representing the "Mysterious Personal Message Box".
///
/// Features two states:
/// - State 1 (Sealed): Gently breathing/glowing sealed box with "Something for your heart today"
///   and "Tap to unseal".
/// - State 2 (Revealed): Triggered by haptic tap with a 600ms unsealing fade/scale transition,
///   revealing the drawn [InshortsStageCard] with "Save" and "Unseal Another" buttons.
///
/// Contains NO rarity tiers, epic/common labels, or game percentages.
class MysteryBoxModal extends StatefulWidget {
  final MoodStage activeMood;
  final String langCode;
  final MysteryBoxEngine? mysteryBoxEngine;
  final void Function(InshortsFeedItem item)? onBookmarkToggle;
  final void Function(InshortsFeedItem item)? onShare;
  final bool initialIsBookmarked;
  final bool Function(InshortsFeedItem item)? isItemBookmarked;

  const MysteryBoxModal({
    super.key,
    required this.activeMood,
    this.langCode = 'eng',
    this.mysteryBoxEngine,
    this.onBookmarkToggle,
    this.onShare,
    this.initialIsBookmarked = false,
    this.isItemBookmarked,
  });

  /// Displays the [MysteryBoxModal] as a calm modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required MoodStage activeMood,
    String langCode = 'eng',
    MysteryBoxEngine? mysteryBoxEngine,
    void Function(InshortsFeedItem item)? onBookmarkToggle,
    void Function(InshortsFeedItem item)? onShare,
    bool isBookmarked = false,
    bool Function(InshortsFeedItem item)? isItemBookmarked,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MysteryBoxModal(
        activeMood: activeMood,
        langCode: langCode,
        mysteryBoxEngine: mysteryBoxEngine,
        onBookmarkToggle: onBookmarkToggle,
        onShare: onShare,
        initialIsBookmarked: isBookmarked,
        isItemBookmarked: isItemBookmarked,
      ),
    );
  }

  @override
  State<MysteryBoxModal> createState() => _MysteryBoxModalState();
}

class _MysteryBoxModalState extends State<MysteryBoxModal>
    with TickerProviderStateMixin {
  late final MysteryBoxEngine _engine;
  late final AnimationController _pulseController;
  late final AnimationController _revealController;
  late final Animation<double> _revealFadeAnimation;
  late final Animation<double> _revealScaleAnimation;

  bool _isRevealed = false;
  bool _isLoadingItem = false;
  InshortsFeedItem? _drawnItem;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _engine = widget.mysteryBoxEngine ?? MysteryBoxEngine();
    _isSaved = widget.initialIsBookmarked;

    // State 1: Soft pulse animation for sealed box
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // State 2: 600ms unsealing fade and scale transition
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _revealFadeAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );

    _revealScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _unseal() async {
    if (_isRevealed || _isLoadingItem) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isLoadingItem = true;
    });

    try {
      final item = await _engine.openMysteryBox(
        widget.activeMood,
        widget.langCode,
      );
      if (!mounted) return;

      final isSaved = widget.isItemBookmarked?.call(item) ?? widget.initialIsBookmarked;

      setState(() {
        _drawnItem = item;
        _isSaved = isSaved;
        _isLoadingItem = false;
        _isRevealed = true;
      });

      _pulseController.stop();
      _revealController.forward(from: 0.0);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingItem = false;
        });
      }
    }
  }

  Future<void> _unsealAnother() async {
    if (_isLoadingItem) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isLoadingItem = true;
    });

    try {
      final nextItem = await _engine.openMysteryBox(
        widget.activeMood,
        widget.langCode,
      );
      if (!mounted) return;

      final isSaved = widget.isItemBookmarked?.call(nextItem) ?? false;

      setState(() {
        _drawnItem = nextItem;
        _isSaved = isSaved;
        _isLoadingItem = false;
      });

      _revealController.forward(from: 0.0);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingItem = false;
        });
      }
    }
  }

  void _handleBookmarkToggle() {
    final item = _drawnItem;
    if (item == null) return;
    setState(() {
      _isSaved = !_isSaved;
    });
    widget.onBookmarkToggle?.call(item);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.activeMood.palette;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isShort = screenHeight < 680;
    final modalHeight = math.min(screenHeight * (isShort ? 0.94 : 0.88), 760.0);

    return Container(
      height: modalHeight,
      decoration: BoxDecoration(
        color: palette.bgTop,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.75),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30.0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        child: Column(
          children: [
            // Top Drag Handle & Close Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 12.0, 4.0),
              child: Row(
                children: [
                  const SizedBox(width: 32.0),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40.0,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: palette.secondaryText.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.0,
                      color: palette.secondaryText,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content Area: State 1 (Sealed) or State 2 (Revealed)
            Expanded(
              child: _isRevealed && _drawnItem != null
                  ? _buildRevealedState(palette)
                  : _buildSealedState(palette),
            ),
          ],
        ),
      ),
    );
  }

  /// State 1: Sealed state with a breathing/glowing pulse animation.
  Widget _buildSealedState(StagePalette palette) {
    return SizedBox.expand(
      child: GestureDetector(
        onTap: _unseal,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gently breathing glowing sealed icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulseVal = _pulseController.value;
                    final scale = 0.96 + (pulseVal * 0.08);

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 116.0,
                        height: 116.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.accent.withValues(alpha: 0.12 + (pulseVal * 0.08)),
                          border: Border.all(
                            color: palette.accent.withValues(alpha: 0.45 + (pulseVal * 0.25)),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.accent.withValues(alpha: 0.2 + (pulseVal * 0.2)),
                              blurRadius: 18.0 + (pulseVal * 14.0),
                              spreadRadius: 2.0 + (pulseVal * 4.0),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 50.0,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28.0),

                // Title
                Text(
                  'Something for your heart today',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 21.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: palette.primaryText,
                  ),
                ),
                const SizedBox(height: 10.0),

                // Subtitle / Tap prompt
                Text(
                  _isLoadingItem ? 'Unsealing...' : 'Tap to unseal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// State 2: Smooth 600ms unsealing fade/scale transition revealing InshortsStageCard.
  Widget _buildRevealedState(StagePalette palette) {
    final item = _drawnItem!;

    return FadeTransition(
      opacity: _revealFadeAnimation,
      child: ScaleTransition(
        scale: _revealScaleAnimation,
        child: Column(
          children: [
            // Drawn InshortsStageCard
            Expanded(
              child: InshortsStageCard(
                key: ValueKey('mystery_${item.id}'),
                item: item,
                palette: palette,
                isBookmarked: _isSaved,
                langCode: widget.langCode,
                onBookmarkToggle: _handleBookmarkToggle,
                onShare: () {
                  widget.onShare?.call(item);
                },
              ),
            ),

            // Action Buttons: "Save" and "Unseal Another"
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 14.0),
              child: Row(
                children: [
                  // Save button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleBookmarkToggle,
                      icon: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                        size: 18.0,
                        color: _isSaved ? palette.accent : palette.primaryText,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isSaved ? 'Saved' : 'Save',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: _isSaved ? palette.accent : palette.primaryText,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        side: BorderSide(
                          color: _isSaved
                              ? palette.accent
                              : palette.cardBorder.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),

                  // Unseal Another button
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingItem ? null : _unsealAnother,
                      icon: _isLoadingItem
                          ? const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18.0,
                              color: Colors.white,
                            ),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Unseal Another',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
