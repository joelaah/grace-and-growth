import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_glory/models/inshorts_feed_item.dart';
import 'package:bible_glory/models/tagged_verse.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/inshorts_stage_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Single Spiritual Bible Theme & Gospel Spreading Tests', () {
    testWidgets('Toggling theme mode switches directly between Dark and Light mode', (tester) async {
      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final state = screenKey.currentState!;
      // Initially in Dark mode
      expect(state.activeStage.palette.isDarkPalette, isTrue);

      // Find theme toggle button (shows light_mode icon when in dark mode to switch to light)
      final toggleFinder = find.byTooltip('Switch to Light mode (Sacred Scripture)');
      expect(toggleFinder, findsOneWidget);

      // Tap toggle to switch to Light mode
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(state.activeStage, equals(MoodStage.bright));
      expect(state.activeStage.palette.isDarkPalette, isFalse);

      // Now tooltip prompts to switch back to Dark mode
      final darkToggleFinder = find.byTooltip('Switch to Dark mode (Sanctuary Twilight)');
      expect(darkToggleFinder, findsOneWidget);

      // Tap toggle to switch back to Dark mode
      await tester.tap(darkToggleFinder);
      await tester.pumpAndSettle();

      expect(state.activeStage, equals(MoodStage.gloomy));
      expect(state.activeStage.palette.isDarkPalette, isTrue);
    });

    testWidgets('Swiping between feed items does NOT change theme or flash background', (tester) async {
      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final state = screenKey.currentState!;
      final initialStage = state.activeStage;
      expect(initialStage, equals(MoodStage.gloomy));

      // Scroll to next card (which may have a different stage tag)
      state.pageController.jumpToPage(1);
      await tester.pumpAndSettle();

      // Theme remains rock-solid in the selected theme mode without flashing
      expect(state.activeStage, equals(initialStage));
    });

    testWidgets('Header displays Spreading the Gospel subtitle', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Grace & Growth'), findsOneWidget);
      expect(find.text('Daily Sanctuary • Spreading the Gospel'), findsOneWidget);
    });

    testWidgets('InshortsStageCard displays Research button for verses and opens Bible Research modal', (tester) async {
      final verse = TaggedVerse(
        id: 'PSA.34.18',
        book: 'PSA',
        chapter: 34,
        verse: 18,
        primaryStage: MoodStage.gloomy,
        moodTags: const ['gloomy', 'brokenhearted', 'comfort'],
        reflectionsByLang: const {'eng': 'God draws near to heal.'},
        textsByLang: const {'eng': 'The Lord is near to the brokenhearted.'},
      );
      final item = InshortsFeedItem.fromVerse(verse, langCode: 'eng');

      bool researchOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: InshortsStageCard(
                item: item,
                palette: StagePalette.bibleDark,
                onResearch: () => researchOpened = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Research'), findsOneWidget);
      await tester.tap(find.text('Research'));
      await tester.pumpAndSettle();

      expect(researchOpened, isTrue);
    });

    testWidgets('Full HomeStageScreen opens Bible Research modal and copies Gospel text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      // Tap Research button on the visible first verse card
      final researchFinder = find.text('Research');
      expect(researchFinder, findsWidgets);

      await tester.tap(researchFinder.first);
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Bible Research & Study'), findsOneWidget);
      expect(find.text('Spreading the Gospel through Living Word'), findsOneWidget);
      expect(find.text('Scripture Context & Details'), findsOneWidget);
      expect(find.text('Spread This Gospel Verse'), findsOneWidget);

      // Scroll to and tap 'Spread This Gospel Verse'
      final buttonFinder = find.text('Spread This Gospel Verse');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Notice should be shown
      expect(find.text('Copied to share gentle comfort'), findsOneWidget);
    });

    test('StagePalette bibleDark and bibleLight have canonical spiritual labels', () {
      expect(StagePalette.bibleDark.isDarkPalette, isTrue);
      expect(StagePalette.bibleDark.stageLabel, equals('Sanctuary Twilight'));

      expect(StagePalette.bibleLight.isDarkPalette, isFalse);
      expect(StagePalette.bibleLight.stageLabel, equals('Sacred Scripture'));
    });

    testWidgets('Filtering feed preserves active theme mode without switching stages', (tester) async {
      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final state = screenKey.currentState!;

      // Switch to Light mode
      final toggleFinder = find.byTooltip('Switch to Light mode (Sacred Scripture)');
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(state.activeStage, equals(MoodStage.bright));

      // Filter to 'Verses'
      await tester.tap(find.text('Verses'));
      await tester.pumpAndSettle();

      // Theme MUST NOT revert to dark (which verse 0 PSA.34.18 is tagged with)
      expect(state.activeStage, equals(MoodStage.bright));
      expect(state.activeStage.palette.isDarkPalette, isFalse);

      // Filter to 'Quotes'
      await tester.tap(find.text('Quotes'));
      await tester.pumpAndSettle();
      expect(state.activeStage, equals(MoodStage.bright));

      // Filter to 'All'
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(state.activeStage, equals(MoodStage.bright));
    });

    testWidgets('Legacy auto theme_mode preference smoothly migrates', (tester) async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'auto'});

      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // Verifies 'auto' was migrated to 'dark' or 'light'
      final migrated = prefs.getString('theme_mode');
      expect(migrated == 'dark' || migrated == 'light', isTrue);
    });
  });
}
