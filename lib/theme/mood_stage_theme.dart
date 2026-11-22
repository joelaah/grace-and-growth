import 'package:flutter/material.dart';

/// The four contemplative mood stages supported by the Grace & Growth sanctuary.
enum MoodStage {
  gloomy,
  growing,
  bright,
  humble,
}

/// An immutable color and identity palette corresponding to each [MoodStage],
/// extracted with fidelity from the Stitch design specifications.
@immutable
class StagePalette {
  final Color bgTop;
  final Color bgBottom;
  final Color cardSurface;
  final Color cardBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final String stageLabel;

  const StagePalette({
    required this.bgTop,
    required this.bgBottom,
    required this.cardSurface,
    required this.cardBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.stageLabel,
  });

  /// Whether this palette represents a dark theme (low-luminance background).
  bool get isDarkPalette => bgTop.computeLuminance() < 0.3;

  /// Gloomy & Heavy palette (Twilight contemplation / Sanctuary Twilight)
  static const StagePalette gloomy = StagePalette(
    bgTop: Color(0xFF0D111A),
    bgBottom: Color(0xFF141923),
    cardSurface: Color(0xFF19202D),
    cardBorder: Color(0x38DEB377),
    primaryText: Color(0xFFF4F0E8),
    secondaryText: Color(0xFFA5B1C2),
    accent: Color(0xFFDEB377),
    stageLabel: 'Gloomy & Heavy',
  );

  /// Growing in Sorrow palette (Deep quiet growth in reverent sanctuary dark)
  static const StagePalette growing = StagePalette(
    bgTop: Color(0xFF0D111A),
    bgBottom: Color(0xFF141923),
    cardSurface: Color(0xFF19202D),
    cardBorder: Color(0x38DEB377),
    primaryText: Color(0xFFF4F0E8),
    secondaryText: Color(0xFFA5B1C2),
    accent: Color(0xFFD49E72),
    stageLabel: 'Growing in Sorrow',
  );

  /// Bright & Grateful palette (Sunlit sacred manuscript / Eye-soothing warm linen)
  static const StagePalette bright = StagePalette(
    bgTop: Color(0xFFFFFDF8),
    bgBottom: Color(0xFFF3ECE0),
    cardSurface: Color(0xFFFAF7F0),
    cardBorder: Color(0xFFE2D9C8),
    primaryText: Color(0xFF2E2620),
    secondaryText: Color(0xFF756A5E),
    accent: Color(0xFFC47A3B),
    stageLabel: 'Bright & Grateful',
  );

  /// Walking Humbly palette (Quiet sacred parchment & gentle warm umber)
  static const StagePalette humble = StagePalette(
    bgTop: Color(0xFFFFFDF8),
    bgBottom: Color(0xFFF3ECE0),
    cardSurface: Color(0xFFFAF7F0),
    cardBorder: Color(0xFFE2D9C8),
    primaryText: Color(0xFF2E2620),
    secondaryText: Color(0xFF756A5E),
    accent: Color(0xFFB57C48),
    stageLabel: 'Walking Humbly',
  );

  /// Canonical Spiritual Bible Dark Palette (Sanctuary Twilight & Holy Reverence)
  static const StagePalette bibleDark = StagePalette(
    bgTop: Color(0xFF0D111A),
    bgBottom: Color(0xFF141923),
    cardSurface: Color(0xFF19202D),
    cardBorder: Color(0x38DEB377),
    primaryText: Color(0xFFF4F0E8),
    secondaryText: Color(0xFFA5B1C2),
    accent: Color(0xFFDEB377),
    stageLabel: 'Sanctuary Twilight',
  );

  /// Canonical Spiritual Bible Light Palette (Sacred Scripture & Ancient Parchment Linen)
  static const StagePalette bibleLight = StagePalette(
    bgTop: Color(0xFFFFFDF8),
    bgBottom: Color(0xFFF3ECE0),
    cardSurface: Color(0xFFFAF7F0),
    cardBorder: Color(0xFFE2D9C8),
    primaryText: Color(0xFF2E2620),
    secondaryText: Color(0xFF756A5E),
    accent: Color(0xFFC47A3B),
    stageLabel: 'Sacred Scripture',
  );

  /// Complete lookup map of palettes keyed by [MoodStage].
  static const Map<MoodStage, StagePalette> palettes = {
    MoodStage.gloomy: gloomy,
    MoodStage.growing: growing,
    MoodStage.bright: bright,
    MoodStage.humble: humble,
  };

  /// Resolves the [StagePalette] for a given [MoodStage]. Defaults to [gloomy].
  static StagePalette of(MoodStage stage) => palettes[stage] ?? gloomy;

  /// Creates a copy of this [StagePalette] with the given fields replaced.
  StagePalette copyWith({
    Color? bgTop,
    Color? bgBottom,
    Color? cardSurface,
    Color? cardBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? accent,
    String? stageLabel,
  }) {
    return StagePalette(
      bgTop: bgTop ?? this.bgTop,
      bgBottom: bgBottom ?? this.bgBottom,
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      accent: accent ?? this.accent,
      stageLabel: stageLabel ?? this.stageLabel,
    );
  }

  /// Linearly interpolates between two [StagePalette]s.
  static StagePalette lerp(StagePalette a, StagePalette b, double t) {
    return StagePalette(
      bgTop: Color.lerp(a.bgTop, b.bgTop, t) ?? a.bgTop,
      bgBottom: Color.lerp(a.bgBottom, b.bgBottom, t) ?? a.bgBottom,
      cardSurface: Color.lerp(a.cardSurface, b.cardSurface, t) ?? a.cardSurface,
      cardBorder: Color.lerp(a.cardBorder, b.cardBorder, t) ?? a.cardBorder,
      primaryText: Color.lerp(a.primaryText, b.primaryText, t) ?? a.primaryText,
      secondaryText:
          Color.lerp(a.secondaryText, b.secondaryText, t) ?? a.secondaryText,
      accent: Color.lerp(a.accent, b.accent, t) ?? a.accent,
      stageLabel: t < 0.5 ? a.stageLabel : b.stageLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StagePalette &&
          runtimeType == other.runtimeType &&
          bgTop == other.bgTop &&
          bgBottom == other.bgBottom &&
          cardSurface == other.cardSurface &&
          cardBorder == other.cardBorder &&
          primaryText == other.primaryText &&
          secondaryText == other.secondaryText &&
          accent == other.accent &&
          stageLabel == other.stageLabel;

  @override
  int get hashCode => Object.hash(
        bgTop,
        bgBottom,
        cardSurface,
        cardBorder,
        primaryText,
        secondaryText,
        accent,
        stageLabel,
      );

  @override
  String toString() =>
      'StagePalette(stageLabel: $stageLabel, bgTop: $bgTop, bgBottom: $bgBottom, accent: $accent)';
}

/// Reactive controller managing active [MoodStage] and its corresponding [StagePalette].
class MoodThemeController extends ValueNotifier<MoodStage> {
  MoodThemeController([MoodStage initialStage = MoodStage.gloomy])
      : super(initialStage);

  /// Convenient getter for the active stage's [StagePalette].
  StagePalette get currentPalette => value.palette;

  /// Changes the active stage if different.
  void setStage(MoodStage stage) {
    if (value != stage) {
      value = stage;
    }
  }
}

/// Convenience extension on [MoodStage] providing quick palette access.
extension MoodStageThemeX on MoodStage {
  StagePalette get palette => StagePalette.of(this);
}
