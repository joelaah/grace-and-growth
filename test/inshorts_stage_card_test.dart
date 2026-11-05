import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_glory/models/inshorts_feed_item.dart';
import 'package:bible_glory/models/tagged_verse.dart';
import 'package:bible_glory/services/quote_api_service.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/inshorts_stage_card.dart';

void main() {
  final testVerse = TaggedVerse(
    id: 'PSA.34.18',
    book: 'PSA',
    chapter: 34,
    verse: 18,
    primaryStage: MoodStage.gloomy,
    moodTags: const ['gloomy', 'brokenhearted'],
    textsByLang: const {
      'eng': 'The Lord is close to the brokenhearted.',
      'lus': 'LALPA chu thinlung lungchhiatte hnaihah a awm.',
    },
    reflectionsByLang: const {
      'eng': 'God draws closest when your spirit feels heavy.',
      'lus': 'I rilru a pik lai tak hian I kiangah a awm reng.',
    },
  );

  final testQuote = InspirationalQuote(
    id: 'q_test_1',
    quote: 'The cure for pain is in the pain.',
    author: 'Rumi',
    stage: MoodStage.gloomy,
    category: 'Comfort in Heavy Seasons',
    subTag: 'Morning Pause',
    reflections: const {
      'eng': 'Healing begins when you hold sorrow gently.',
    },
    prompts: const {
      'eng': 'Take a slow breath here.',
    },
  );

  group('InshortsStageCard Widget Tests', () {
    testWidgets('Renders Bible verse card with "BIBLE VERSE" source badge and serif font', (tester) async {
      final verseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: InshortsStageCard(
                item: verseItem,
                palette: StagePalette.gloomy,
                langCode: 'eng',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Source badge
      expect(find.text('BIBLE VERSE'), findsOneWidget);

      // Quote in editorial serif font
      final quoteTextFinder = find.text('“The Lord is close to the brokenhearted.”');
      expect(quoteTextFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(quoteTextFinder);
      expect(textWidget.style?.fontFamily, equals('serif'));

      // Reference
      expect(find.text('Psalm 34:18'), findsOneWidget);

      // Reflection & indicators
      expect(find.text('A Gentle Thought'), findsOneWidget);
      expect(find.text('God draws closest when your spirit feels heavy.'), findsOneWidget);
      expect(find.text('Swipe up for next'), findsOneWidget);

      // Floating action divider buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('Renders Inspirational Quote card with "INSPIRATIONAL QUOTE" badge and author attribution', (tester) async {
      final quoteItem = InshortsFeedItem.fromQuote(testQuote, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: InshortsStageCard(
                item: quoteItem,
                palette: StagePalette.gloomy,
                langCode: 'eng',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INSPIRATIONAL QUOTE'), findsOneWidget);
      expect(find.text('“The cure for pain is in the pain.”'), findsOneWidget);
      expect(find.text('— Rumi'), findsOneWidget);
      expect(find.text('Swipe up for next'), findsOneWidget);
    });

    testWidgets('Toggles Bookmark state between Save and Saved', (tester) async {
      final verseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');
      var bookmarked = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 700,
                  child: InshortsStageCard(
                    item: verseItem,
                    palette: StagePalette.gloomy,
                    isBookmarked: bookmarked,
                    onBookmarkToggle: () {
                      setState(() {
                        bookmarked = !bookmarked;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('Has 24px border radius for card surface', (tester) async {
      final verseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: InshortsStageCard(
                item: verseItem,
                palette: StagePalette.gloomy,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.borderRadius as BorderRadius).topLeft.x, equals(24.0));
    });

    testWidgets('Split 55% / 45% layout using Expanded flex', (tester) async {
      final verseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: InshortsStageCard(
                item: verseItem,
                palette: StagePalette.gloomy,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expandedWidgets = tester.widgetList<Expanded>(find.descendant(
        of: find.byType(InshortsStageCard),
        matching: find.byType(Expanded),
      )).toList();

      final flexValues = expandedWidgets.map((e) => e.flex).toList();
      expect(flexValues, contains(55));
      expect(flexValues, contains(45));
    });

    testWidgets('Renders cleanly on 280dp narrow card width without horizontal overflow', (tester) async {
      final quoteItem = InshortsFeedItem.fromQuote(testQuote, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              height: 600,
              child: InshortsStageCard(
                item: quoteItem,
                palette: StagePalette.gloomy,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('INSPIRATIONAL QUOTE'), findsOneWidget);
    });

    testWidgets('Renders cleanly on short height (< 380dp) cards without vertical overflow', (tester) async {
      final verseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 350,
              child: InshortsStageCard(
                item: verseItem,
                palette: StagePalette.gloomy,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BIBLE VERSE'), findsOneWidget);
    });

    testWidgets('Renders on 280dp narrow card with 2.0x text scaling without horizontal overflow', (tester) async {
      final quoteItem = InshortsFeedItem.fromQuote(testQuote, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: SizedBox(
                width: 280,
                height: 500,
                child: InshortsStageCard(
                  item: quoteItem,
                  palette: StagePalette.gloomy,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('INSPIRATIONAL QUOTE'), findsOneWidget);
    });
  });
}
