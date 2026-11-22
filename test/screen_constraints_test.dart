import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_glory/models/inshorts_feed_item.dart';
import 'package:bible_glory/models/tagged_verse.dart';
import 'package:bible_glory/services/quote_api_service.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/screens/onboarding_screen.dart';
import 'package:bible_glory/screens/today_screen.dart';
import 'package:bible_glory/screens/feelings_screen.dart';
import 'package:bible_glory/screens/journal_screen.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/inshorts_stage_card.dart';
import 'package:bible_glory/widgets/shareable_card.dart';
import 'package:bible_glory/widgets/aesthetic_share_modal.dart';
import 'package:bible_glory/widgets/mystery_box_modal.dart';
import 'package:bible_glory/widgets/bible_research_modal.dart';
import 'package:bible_glory/widgets/notification_time_picker.dart';

void main() {
  final testVerse = TaggedVerse(
    id: 'PSA.34.18',
    book: 'PSA',
    chapter: 34,
    verse: 18,
    primaryStage: MoodStage.gloomy,
    moodTags: const ['gloomy', 'brokenhearted'],
    textsByLang: const {
      'eng': 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
      'lus': 'LALPA chu thinlung lungchhiatte hnaihah a awm.',
    },
    reflectionsByLang: const {
      'eng': 'God draws closest when your spirit feels heavy. His presence is a quiet sanctuary.',
      'lus': 'I rilru a pik lai tak hian I kiangah a awm reng.',
    },
  );

  final testQuote = InspirationalQuote(
    id: 'q_test_1',
    quote: 'The cure for pain is in the pain. Where there is ruin, there is hope for a treasure.',
    author: 'Rumi',
    stage: MoodStage.gloomy,
    category: 'Comfort in Heavy Seasons',
    subTag: 'Morning Pause',
    reflections: const {
      'eng': 'Healing begins when you hold sorrow gently with faith.',
    },
    prompts: const {
      'eng': 'Take a slow breath here.',
    },
  );

  final testVerseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');
  final testQuoteItem = InshortsFeedItem.fromQuote(testQuote, langCode: 'eng');

  final baseTestSizes = [
    const Size(320, 480), // legacy / small phone
    const Size(360, 640), // compact Android phone
    const Size(375, 667), // iPhone SE / 8
    const Size(390, 844), // iPhone 14 / modern iPhone
    const Size(412, 915), // Pixel 7 / modern Android
    const Size(280, 653), // Galaxy Z Fold narrow outer display
  ];

  final comprehensiveViewports = [
    const Size(280, 653), // Fold outer narrow
    const Size(320, 480), // Legacy / small
    const Size(360, 360), // Ultra-square / compact
    const Size(390, 844), // Modern iPhone
    const Size(412, 915), // Modern Android
    const Size(768, 1024), // Tablet portrait
    const Size(1280, 800), // Desktop / landscape tablet
  ];

  final textScales = [1.0, 1.5, 2.0];

  group('Cross-Device Screen Constraints & Responsiveness Tests', () {
    for (final size in baseTestSizes) {
      testWidgets('HomeStageScreen layout fits perfectly at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('OnboardingScreen layout fits perfectly at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('FeelingsScreen layout fits at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: FeelingsScreen(
              palette: StagePalette.bibleDark,
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets('NotificationTimePickerModal fits at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => NotificationTimePickerModal.show(ctx, StagePalette.bibleDark),
                child: const Text('Open'),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
      });
    }

    // 1. TodayScreen Populated across viewports & text scaling
    for (final size in comprehensiveViewports) {
      for (final scale in textScales) {
        testWidgets('TodayScreen (populated) fits at ${size.width}x${size.height} @ ${scale}x text scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: TodayScreen(
                palette: StagePalette.bibleDark,
                verses: [testVerse],
                quotes: [testQuote],
                bookmarkedIds: {testVerseItem.id},
              ),
            ),
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('TodayScreen overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });
      }
    }

    // 2. JournalScreen (empty and populated) across viewports & text scaling
    for (final size in comprehensiveViewports) {
      for (final scale in textScales) {
        testWidgets('JournalScreen (empty) fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: JournalScreen(
                palette: StagePalette.bibleDark,
                allFeedItems: const [],
                bookmarkedIds: const {},
              ),
            ),
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('JournalScreen (empty) overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });

        testWidgets('JournalScreen (populated) fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: JournalScreen(
                palette: StagePalette.bibleDark,
                allFeedItems: [testVerseItem, testQuoteItem],
                bookmarkedIds: {testVerseItem.id, testQuoteItem.id},
              ),
            ),
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('JournalScreen (populated) overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });
      }
    }

    // 3. InshortsStageCard across compact split-screen, tablet, desktop, and text scales
    final inshortsHeights = [360.0, 380.0, 400.0, 640.0, 800.0, 1024.0];
    final inshortsItems = [
      ('verse', testVerseItem),
      ('quote', testQuoteItem),
    ];
    for (final h in inshortsHeights) {
      for (final scale in textScales) {
        for (final itemEntry in inshortsItems) {
          testWidgets('InshortsStageCard (${itemEntry.$1}) fits at height $h @ ${scale}x', (tester) async {
            tester.view.physicalSize = Size(390, h);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(MaterialApp(
              theme: ThemeData(useMaterial3: true),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: SizedBox(
                  height: h,
                  child: InshortsStageCard(
                    item: itemEntry.$2,
                    palette: StagePalette.bibleDark,
                    langCode: 'eng',
                  ),
                ),
              ),
            ));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));

            final ex = tester.takeException();
            if (ex != null) {
              debugPrint('InshortsStageCard overflow at height $h @ ${scale}x: $ex');
            }
            expect(ex, isNull);
          });
        }
      }
    }

    // 4. Standalone ShareableCard in constrained viewports
    for (final size in comprehensiveViewports) {
      for (final scale in textScales) {
        testWidgets('ShareableCard standalone fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: ShareableCard(
                  item: testVerseItem,
                  palette: StagePalette.bibleDark,
                ),
              ),
            ),
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('ShareableCard standalone overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });
      }
    }

    // 5. Modals (AestheticShareModal, MysteryBoxModal sealed & revealed, BibleResearchModal, JournalDetailSheet) across 280x653, 360x360, 390x844
    final modalViewports = [
      const Size(280, 653),
      const Size(360, 360),
      const Size(390, 844),
    ];

    for (final size in modalViewports) {
      for (final scale in textScales) {
        testWidgets('AestheticShareModal fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => AestheticShareModal.show(
                    ctx,
                    item: testVerseItem,
                    palette: StagePalette.bibleDark,
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Open Modal'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('AestheticShareModal overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });

        testWidgets('MysteryBoxModal sealed fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => MysteryBoxModal.show(
                    ctx,
                    activeMood: MoodStage.gloomy,
                    palette: StagePalette.bibleDark,
                    langCode: 'eng',
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Open Modal'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('MysteryBoxModal sealed overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });

        testWidgets('MysteryBoxModal revealed fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => MysteryBoxModal.show(
                    ctx,
                    activeMood: MoodStage.gloomy,
                    palette: StagePalette.bibleDark,
                    langCode: 'eng',
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Open Modal'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Tap to unseal
          final unsealTarget = find.text('Something for your heart today');
          if (unsealTarget.evaluate().isNotEmpty) {
            await tester.tap(unsealTarget);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 700));
          }

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('MysteryBoxModal revealed overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });

        testWidgets('BibleResearchModal fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => BibleResearchModal.show(
                    ctx,
                    item: testVerseItem,
                    palette: StagePalette.bibleDark,
                    langCode: 'eng',
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Open Modal'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('BibleResearchModal overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });

        testWidgets('Journal detail sheet fits at ${size.width}x${size.height} @ ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(useMaterial3: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: JournalScreen(
                palette: StagePalette.bibleDark,
                allFeedItems: [testVerseItem],
                bookmarkedIds: {testVerseItem.id},
              ),
            ),
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final cardFinder = find.text('Psalm 34:18');
          if (cardFinder.evaluate().isNotEmpty) {
            await tester.tap(cardFinder);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
          }

          final ex = tester.takeException();
          if (ex != null) {
            debugPrint('Journal detail sheet overflow at ${size.width}x${size.height} @ ${scale}x: $ex');
          }
          expect(ex, isNull);
        });
      }
    }
  });
}
