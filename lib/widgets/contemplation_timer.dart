import 'package:flutter/material.dart';

/// A simple contemplation / silence timer with ambient animation.
///
/// Counts down from [durationSeconds] with a gentle circular progress ring
/// and breathing dot, styled with the mood palette colors.
///
/// Usage:
/// ```dart
/// ContemplationTimer(
///   durationSeconds: 60,
///   accentColor: palette.accent,
///   textColor: palette.primaryText,
///   onComplete: () { /* show gentle completion message */ },
/// )
/// ```
class ContemplationTimer extends StatefulWidget {
  final int durationSeconds;
  final Color accentColor;
  final Color textColor;
  final Color? ringBackgroundColor;
  final VoidCallback? onComplete;

  const ContemplationTimer({
    super.key,
    this.durationSeconds = 60,
    required this.accentColor,
    required this.textColor,
    this.ringBackgroundColor,
    this.onComplete,
  });

  @override
  State<ContemplationTimer> createState() => _ContemplationTimerState();
}

class _ContemplationTimerState extends State<ContemplationTimer>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _breatheController;
  bool _isRunning = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();

    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRunning = false;
          _isComplete = true;
        });
        widget.onComplete?.call();
      }
    });

    // Gentle breathing animation: 4 seconds in, 4 seconds out
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isComplete = false;
    });
    _countdownController.forward(from: 0.0);
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _countdownController.stop();
  }

  void _resetTimer() {
    _countdownController.reset();
    setState(() {
      _isRunning = false;
      _isComplete = false;
    });
  }

  /// Formats remaining seconds as "M:SS".
  String _formatTime(int totalSeconds) {
    final remaining =
        (totalSeconds - (totalSeconds * _countdownController.value).round())
            .clamp(0, totalSeconds);
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress ring with breathing dot
        SizedBox(
          width: 160,
          height: 160,
          child: AnimatedBuilder(
            animation: Listenable.merge([_countdownController, _breatheController]),
            builder: (context, _) {
              final breatheScale = 0.85 + (_breatheController.value * 0.3);
              final progress = _countdownController.value;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 4.0,
                      color: (widget.ringBackgroundColor ??
                              widget.accentColor)
                          .withValues(alpha: 0.15),
                    ),
                  ),
                  // Progress ring
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _isRunning || _isComplete ? progress : 0.0,
                      strokeWidth: 4.0,
                      color: widget.accentColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Breathing dot
                  if (_isRunning)
                    Transform.scale(
                      scale: breatheScale,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withValues(alpha: 0.3),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  widget.accentColor.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Time display
                  Text(
                    _isComplete
                        ? '✓'
                        : _formatTime(widget.durationSeconds),
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: _isComplete ? 36 : 28,
                      fontWeight: FontWeight.w300,
                      color: widget.textColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Breathing instruction
        if (_isRunning)
          AnimatedBuilder(
            animation: _breatheController,
            builder: (context, _) {
              final breathePhase =
                  _breatheController.status == AnimationStatus.forward
                      ? 'Breathe in...'
                      : 'Breathe out...';
              return Text(
                breathePhase,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: widget.textColor.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              );
            },
          ),

        if (_isComplete)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Peace be with you',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: widget.accentColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isRunning && !_isComplete)
              _buildControlButton(
                icon: Icons.play_arrow_rounded,
                label: 'Begin',
                onTap: _startTimer,
              ),
            if (_isRunning)
              _buildControlButton(
                icon: Icons.pause_rounded,
                label: 'Pause',
                onTap: _pauseTimer,
              ),
            if (_isComplete || (!_isRunning && _countdownController.value > 0))
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildControlButton(
                  icon: Icons.refresh_rounded,
                  label: 'Again',
                  onTap: _resetTimer,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: widget.accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
