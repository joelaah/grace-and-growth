import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/screens/journal_screen.dart';
import 'package:bible_glory/screens/today_screen.dart';
import 'package:bible_glory/screens/feelings_screen.dart';
import 'package:bible_glory/services/journal_storage.dart';
import 'package:bible_glory/services/tts_service.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Bookmark Persistence & Journal Storage Integration', () {
    test('JournalStorage saves, retrieves, and unsaves bookmark IDs correctly', () async {
      final storage = JournalStorage();
      expect(await storage.getSavedCardIds(), isEmpty);

      await storage.saveCardId('verse_1');
      await storage.saveCardId('verse_2');
      expect(await storage.getSavedCardIds(), equals(['verse_2', 'verse_1']));
      expect(await storage.isCardSaved('verse_1'), isTrue);
      expect(await storage.isCardSaved('verse_99'), isFalse);

      await storage.unsaveCardId('verse_1');
      expect(await storage.getSavedCardIds(), equals(['verse_2']));
    });

    testWidgets('HomeStageScreen loads persisted bookmarks from storage on init', (tester) async {
      SharedPreferences.setMockInitialValues({
        'saved_card_ids': ['verse_PSA.34.18', 'quote_123'],
      });

      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      // Check Journal tab (index 2) to see saved items rendered
      await tester.tap(find.byIcon(Icons.edit_note_outlined));
      await tester.pumpAndSettle();

      // Journal should NOT show empty state because saved items exist
      expect(find.text('Your journal is empty'), findsNothing);
    });
  });

  group('Journal Empty State Call-To-Action', () {
    testWidgets('Shows Explore Scripture Feed button when journal is empty and invokes callback', (tester) async {
      bool exploreTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalScreen(
              palette: StagePalette.bibleDark,
              allFeedItems: const [],
              bookmarkedIds: const {},
              onExploreFeed: () => exploreTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your journal is empty'), findsOneWidget);
      final exploreBtn = find.text('Explore Scripture Feed');
      expect(exploreBtn, findsOneWidget);

      await tester.tap(exploreBtn);
      await tester.pumpAndSettle();
      expect(exploreTapped, isTrue);
    });
  });

  group('Scroll Padding & Collision Prevention', () {
    testWidgets('TodayScreen has bottom scroll clearance of 96dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayScreen(
              palette: StagePalette.bibleDark,
              verses: const [],
              quotes: const [],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final scrollable = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final insets = scrollable.padding as EdgeInsets;
      expect(insets.bottom, equals(96.0));
    });

    testWidgets('FeelingsScreen has bottom scroll clearance of 96dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeelingsScreen(
              palette: StagePalette.bibleDark,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final insets = scrollable.padding as EdgeInsets;
      expect(insets.bottom, equals(96.0));
    });

    testWidgets('For You floating action button is elevated by 78dp to clear bottom navigation dock', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeStageScreen()),
      );
      await tester.pumpAndSettle();

      // Find the For You button container inside the FloatingActionButton
      final forYouFinder = find.ancestor(
        of: find.text('For You'),
        matching: find.byType(Container),
      );
      expect(forYouFinder, findsWidgets);

      // Verify the outer container has bottom margin 78.0
      final containers = tester.widgetList<Container>(forYouFinder);
      final elevatedContainer = containers.firstWhere(
        (c) => c.margin is EdgeInsets && (c.margin as EdgeInsets).bottom == 78.0,
      );
      expect(elevatedContainer, isNotNull);
    });
  });

  group('Theme Contrast Enhancement', () {
    test('StagePalette bibleLight secondaryText and cardBorder meet enhanced contrast standards', () {
      final palette = StagePalette.bibleLight;
      // Secondary text is darkened to 0xFF5A5046
      expect(palette.secondaryText, equals(const Color(0xFF5A5046)));
      // Card border is strengthened to 0xFFD4C8B2
      expect(palette.cardBorder, equals(const Color(0xFFD4C8B2)));
      // Primary text is rich deep espresso 0xFF221B15
      expect(palette.primaryText, equals(const Color(0xFF221B15)));
    });
  });
}
