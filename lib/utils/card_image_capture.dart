import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Utility to capture a widget (wrapped in a RepaintBoundary) as a PNG image.
///
/// Usage:
/// 1. Wrap the target widget with `RepaintBoundary(key: _cardBoundaryKey)`.
/// 2. Call `CardImageCapture.captureAsPng(_cardBoundaryKey)` to get PNG bytes.
/// 3. Pass the bytes to `Share.shareXFiles` from `share_plus`.
class CardImageCapture {
  /// Captures the widget identified by [boundaryKey] as PNG bytes.
  ///
  /// [pixelRatio] controls the resolution multiplier (default 3.0 for crisp images).
  /// Returns `null` if the boundary is not found or capture fails.
  static Future<Uint8List?> captureAsPng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
