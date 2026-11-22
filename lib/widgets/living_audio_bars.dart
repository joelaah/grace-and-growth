import 'dart:math';
import 'package:flutter/material.dart';

/// A subtle 3-bar pulsing living audio indicator for active TTS speech.
class LivingAudioBars extends StatefulWidget {
  final Color color;
  final bool isPlaying;

  const LivingAudioBars({
    super.key,
    required this.color,
    this.isPlaying = true,
  });

  @override
  State<LivingAudioBars> createState() => _LivingAudioBarsState();
}

class _LivingAudioBarsState extends State<LivingAudioBars>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) {
      _initAndStart();
    }
  }

  void _initAndStart() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LivingAudioBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        if (_controller == null) {
          _initAndStart();
        } else {
          _controller!.repeat(reverse: true);
        }
      } else {
        _controller?.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying || _controller == null) {
      return SizedBox(
        width: 14.0,
        height: 14.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(4.0),
            _buildBar(9.0),
            _buildBar(6.0),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        final val = _controller!.value;
        final h1 = 3.5 + 7.0 * (0.5 + 0.5 * sin(val * 2 * pi));
        final h2 = 4.5 + 8.5 * (0.5 + 0.5 * sin((val + 0.33) * 2 * pi));
        final h3 = 3.5 + 6.5 * (0.5 + 0.5 * sin((val + 0.67) * 2 * pi));

        return SizedBox(
          width: 14.0,
          height: 14.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(h1),
              _buildBar(h2),
              _buildBar(h3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 2.5,
      height: height.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
