import 'package:bible_glory/models/inshorts_feed_item.dart';
import 'package:bible_glory/models/tagged_verse.dart';
import 'package:bible_glory/screens/today_screen.dart';
import 'package:bible_glory/services/tts_service.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/audio_sanctum_settings_modal.dart';
import 'package:bible_glory/widgets/inshorts_stage_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testVerse = TaggedVerse(
    id: 'PSA.23.1',
    book: 'PSA',
    chapter: 23,
    verse: 1,
    primaryStage: MoodStage.humble,
    moodTags: const ['peace', 'comfort'],
    textsByLang: const {
      'eng': 'The Lord is my shepherd; I shall not want.',
    },
    reflectionsByLang: const {
      'eng': 'He leads us beside still waters.',
    },
  );

  final testVerseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      return 1;
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TtsService().stop();
    await TtsService().setPersona(VoicePersona.seraph);
    await TtsService().setAmbientPadEnabled(true);
    await TtsService().setCadenceRate(0.85);
  });

  Widget buildTestableWidget(Widget child, {Size size = const Size(400, 800)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('AudioSanctumSettingsModal Component & Interaction Tests', () {
    testWidgets('Renders all personas, ambient pad switch, pace options, and preview button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AudioSanctumSettingsModal(palette: StagePalette.bibleDark),
        ),
      );

      // Verify Header
      expect(find.text('Audio Sanctum'), findsOneWidget);
      expect(find.text('Contemplative voices & sacred ambient resonance'), findsOneWidget);

      // Verify Personas
      expect(find.text('Seraph'), findsOneWidget);
      expect(find.text('Shepherd'), findsOneWidget);
      expect(find.text('System Natural'), findsOneWidget);
      expect(find.text('🕊️'), findsOneWidget);
      expect(find.text('🌿'), findsOneWidget);
      expect(find.text('⚙️'), findsOneWidget);

      // Verify Ambient Pad Switch
      expect(find.text('Cathedral Ambient Pad'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Verify Pacing pills
      expect(find.text('Meditative'), findsOneWidget);
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('Serene'), findsOneWidget);
      expect(find.text('0.85x'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);

      // Verify Preview button
      expect(find.text('Preview Sanctum Voice'), findsOneWidget);
    });

    testWidgets('Tapping Shepherd persona updates active persona and persists', (tester) async {
      final tts = TtsService();
      await tester.pumpWidget(
        buildTestableWidget(
          AudioSanctumSettingsModal(palette: StagePalette.bibleDark),
        ),
      );

      expect(tts.persona, equals(VoicePersona.seraph));

      // Tap Shepherd persona option
      await tester.tap(find.text('Shepherd'));
      await tester.pumpAndSettle();

      expect(tts.persona, equals(VoicePersona.shepherd));

      // Tap Seraph persona option
      await tester.tap(find.text('Seraph'));
      await tester.pumpAndSettle();

      expect(tts.persona, equals(VoicePersona.seraph));
    });

    testWidgets('Toggling Cathedral Ambient Pad switch updates TtsService state', (tester) async {
      final tts = TtsService();
      await tester.pumpWidget(
        buildTestableWidget(
          AudioSanctumSettingsModal(palette: StagePalette.bibleDark),
        ),
      );

      expect(tts.ambientPadEnabled, isTrue);

      // Tap switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tts.ambientPadEnabled, isFalse);

      // Tap switch again
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tts.ambientPadEnabled, isTrue);
    });

    testWidgets('Tapping pace pill updates contemplative cadence rate', (tester) async {
      final tts = TtsService();
      await tester.pumpWidget(
        buildTestableWidget(
          AudioSanctumSettingsModal(palette: StagePalette.bibleDark),
        ),
      );

      expect(tts.cadenceRate, equals(0.85));

      // Tap Meditative (0.75x)
      await tester.tap(find.text('Meditative'));
      await tester.pumpAndSettle();
      expect(tts.cadenceRate, equals(0.75));

      // Tap Standard (1.0x)
      await tester.tap(find.text('Standard'));
      await tester.pumpAndSettle();
      expect(tts.cadenceRate, equals(1.0));
    });

    testWidgets('Tapping Preview Sanctum Voice speaks preview sample and animates', (tester) async {
      final tts = TtsService();
      await tester.pumpWidget(
        buildTestableWidget(
          AudioSanctumSettingsModal(palette: StagePalette.bibleDark),
        ),
      );

      // Initial state
      expect(find.text('Preview Sanctum Voice'), findsOneWidget);

      // Scroll to Preview button and tap
      await tester.ensureVisible(find.text('Preview Sanctum Voice'));
      await tester.tap(find.text('Preview Sanctum Voice'));
      await tester.pump();

      expect(tts.currentlySpeakingId.value, equals('preview_sanctum_sample'));
      expect(find.text('Playing Preview... (Tap to stop)'), findsOneWidget);

      // Tap again to stop
      await tester.ensureVisible(find.text('Playing Preview... (Tap to stop)'));
      await tester.tap(find.text('Playing Preview... (Tap to stop)'));
      await tester.pump();

      expect(tts.currentlySpeakingId.value, isNull);
      expect(find.text('Preview Sanctum Voice'), findsOneWidget);
    });

    testWidgets('Desktop wide viewports open floating dialog with BackdropFilter', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => AudioSanctumSettingsModal.show(ctx, palette: StagePalette.bibleDark),
              child: const Text('Open Settings'),
            ),
          ),
          size: const Size(1200, 900),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Audio Sanctum'), findsOneWidget);

      // Tap Close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('InshortsStageCard & TodayScreen Tune Settings Integration Tests', () {
    testWidgets('InshortsStageCard mobile action bar contains tune icon and opens settings modal', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          InshortsStageCard(
            item: testVerseItem,
            palette: StagePalette.bibleDark,
          ),
          size: const Size(400, 800),
        ),
      );

      final tuneIcon = find.byIcon(Icons.tune_rounded);
      expect(tuneIcon, findsOneWidget);

      await tester.tap(tuneIcon);
      await tester.pumpAndSettle();

      // Verifies AudioSanctumSettingsModal opened
      expect(find.text('Audio Sanctum'), findsOneWidget);
      expect(find.text('Cathedral Ambient Pad'), findsOneWidget);
    });

    testWidgets('InshortsStageCard desktop panoramic dock contains tune icon and opens modal', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          InshortsStageCard(
            item: testVerseItem,
            palette: StagePalette.bibleDark,
          ),
          size: const Size(1200, 900),
        ),
      );

      final tuneIcon = find.byIcon(Icons.tune_rounded);
      expect(tuneIcon, findsOneWidget);

      await tester.tap(tuneIcon);
      await tester.pumpAndSettle();

      expect(find.text('Audio Sanctum'), findsOneWidget);
    });

    testWidgets('TodayScreen action bar contains tune icon and opens settings modal', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          TodayScreen(
            palette: StagePalette.bibleDark,
            verses: [testVerse],
            quotes: const [],
          ),
          size: const Size(400, 800),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final tuneIcon = find.byIcon(Icons.tune_rounded);
      expect(tuneIcon, findsWidgets);

      await tester.ensureVisible(tuneIcon.first);
      await tester.tap(tuneIcon.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Audio Sanctum'), findsOneWidget);
      expect(find.text('VOICE PERSONA'), findsOneWidget);
    });
  });

  group('AudioSanctumSettingsModal Responsive Screen Constraints Tests', () {
    final viewports = [
      const Size(280, 653), // Narrow mobile
      const Size(360, 360), // Small square / split-screen
      const Size(390, 844), // Standard mobile
    ];

    final scales = [1.0, 1.5, 2.0];

    for (final size in viewports) {
      for (final scale in scales) {
        testWidgets('AudioSanctumSettingsModal fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          FlutterErrorDetails? errorCaught;
          final originalOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed')) {
              errorCaught = details;
            }
          };

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
              ),
              child: MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (ctx) => TextButton(
                      onPressed: () => AudioSanctumSettingsModal.show(ctx, palette: StagePalette.bibleDark),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Open'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          FlutterError.onError = originalOnError;
          expect(errorCaught, isNull, reason: 'Must not overflow at $size @ ${scale}x: ${errorCaught?.exception}');
        });
      }
    }
  });
}
