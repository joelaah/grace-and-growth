import 'package:flutter/material.dart';

/// Parallax depth calculator for vertical PageView card transitions.
///
/// Usage inside `PageView.builder`'s `itemBuilder`:
/// ```dart
/// PageView.builder(
///   controller: _pageController,
///   itemBuilder: (context, index) {
///     return AnimatedBuilder(
///       animation: _pageController,
///       builder: (context, child) {
///         final metrics = ParallaxCardEffect.calculate(
///           pageController: _pageController,
///           index: index,
///         );
///         return Transform(
///           alignment: Alignment.center,
///           transform: Matrix4.identity()
///             ..setEntry(3, 2, 0.001)  // perspective
///             ..multiply(Matrix4.diagonal3Values(metrics.scale, metrics.scale, 1.0))
///             ..multiply(Matrix4.translationValues(0.0, metrics.translationY, 0.0)),
///           child: Opacity(
///             opacity: metrics.opacity,
///             child: child,
///           ),
///         );
///       },
///       child: InshortsStageCard(...),
///     );
///   },
/// )
/// ```
class ParallaxMetrics {
  final double scale;
  final double opacity;
  final double translationY;
  final double rotationX;

  const ParallaxMetrics({
    required this.scale,
    required this.opacity,
    required this.translationY,
    required this.rotationX,
  });

  /// Identity (no effect) — used when page position can't be determined.
  static const ParallaxMetrics identity = ParallaxMetrics(
    scale: 1.0,
    opacity: 1.0,
    translationY: 0.0,
    rotationX: 0.0,
  );
}

class ParallaxCardEffect {
  /// Calculates parallax metrics for a card at [index] given a [pageController].
  ///
  /// The math:
  /// - `pageOffset` = distance of this card from the current viewport center (0.0 = centered).
  /// - Outgoing card (pageOffset < 0): scales down to 0.92, fades to 0.4, translates up.
  /// - Incoming card (pageOffset > 0): scales from 0.95 up to 1.0, fades from 0.6 to 1.0.
  /// - Centered card (pageOffset ≈ 0): full scale, full opacity.
  static ParallaxMetrics calculate({
    required PageController pageController,
    required int index,
  }) {
    double pageOffset = 0.0;

    try {
      if (pageController.position.haveDimensions &&
          pageController.page != null) {
        pageOffset = (pageController.page! - index);
      }
    } catch (_) {
      // Controller not yet attached — return identity
      return ParallaxMetrics.identity;
    }

    // Clamp to a meaningful range for smooth interpolation
    final clampedOffset = pageOffset.clamp(-1.5, 1.5);
    final absOffset = clampedOffset.abs();

    // Scale: 1.0 at center → 0.92 at full offset
    final scale = 1.0 - (absOffset * 0.08).clamp(0.0, 0.08);

    // Opacity: 1.0 at center → 0.4 at full offset
    final opacity = (1.0 - (absOffset * 0.6)).clamp(0.4, 1.0);

    // Vertical translation: push outgoing card up, bring incoming card from below
    // Negative pageOffset = card is above (leaving), positive = card is below (entering)
    final translationY = clampedOffset * -30.0;

    // Subtle X-axis rotation for depth (radians)
    final rotationX = clampedOffset * 0.02;

    return ParallaxMetrics(
      scale: scale,
      opacity: opacity,
      translationY: translationY,
      rotationX: rotationX,
    );
  }
}
