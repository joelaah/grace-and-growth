import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/living_audio_bars.dart';
import 'package:bible_glory/widgets/verse_stage_card.dart';

void main() {
  final sampleVerse = StageVerse.mockData[MoodStage.gloomy]!;

  group('LivingAudioBars & Specular Card Tests', () {
    testWidgets('LivingAudioBars renders 3 bars in resting state when isPlaying is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LivingAudioBars(
                color: Color(0xFFDEB377),
                isPlaying: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinders = find.descendant(
        of: find.byType(LivingAudioBars),
        matching: find.byType(Container),
      );
      expect(containerFinders, findsNWidgets(3));
    });

    testWidgets('LivingAudioBars animates smoothly across frames when isPlaying is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LivingAudioBars(
                color: Color(0xFFDEB377),
                isPlaying: true,
              ),
            ),
          ),
        ),
      );
      // Advance by one frame
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final containerFinders = find.descendant(
        of: find.byType(LivingAudioBars),
        matching: find.byType(Container),
      );
      expect(containerFinders, findsNWidgets(3));

      // Advance again to verify non-zero animation
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('VerseStageCard renders sacred glyph ornament and living audio bars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VerseStageCard(
                verse: sampleVerse,
                palette: StagePalette.bibleDark,
                langCode: 'eng',
                isPlayingAudio: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Centered sacred glyph ornament
      expect(find.text('❖'), findsOneWidget);

      // Living audio bars during audio playback
      expect(find.byType(LivingAudioBars), findsOneWidget);
      expect(find.text('Playing'), findsOneWidget);
    });

    testWidgets('VerseStageCard renders Listen button when not playing audio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VerseStageCard(
                verse: sampleVerse,
                palette: StagePalette.bibleDark,
                langCode: 'eng',
                isPlayingAudio: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('❖'), findsOneWidget);
    });
  });
}
