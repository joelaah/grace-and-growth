import 'package:bible_glory/models/inshorts_feed_item.dart';
import 'package:bible_glory/models/tagged_verse.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/utils/sanctuary_strings.dart';
import 'package:bible_glory/utils/web_download_helper.dart';
import 'package:bible_glory/widgets/aesthetic_share_modal.dart';
import 'package:bible_glory/widgets/bible_research_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testVerse = TaggedVerse(
    id: 'JHN.3.16',
    book: 'JHN',
    chapter: 3,
    verse: 16,
    primaryStage: MoodStage.bright,
    moodTags: const ['love', 'salvation', 'grace'],
    textsByLang: const {
      'eng': 'For God so loved the world...',
      'lus': 'Pathianin khawvel a hmangaih em em a...',
      'hin': 'क्योंकि परमेश्वर ने जगत से ऐसा प्रेम रखा...',
      'spa': 'Porque de tal manera amó Dios al mundo...',
    },
    reflectionsByLang: const {
      'eng': 'Eternal love given freely.',
      'lus': 'Chatuan hmangaihna thlawn pek.',
      'hin': 'अनंत प्रेम मुफ्त में दिया गया।',
      'spa': 'Amor eterno dado libremente.',
    },
  );

  final testItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');

  group('SanctuaryStrings & Canon Divisions', () {
    test('Localized translation names match each language code', () {
      expect(SanctuaryStrings.translationName('eng'), contains('Berean Standard Bible'));
      expect(SanctuaryStrings.translationName('spa'), contains('Reina Valera 1909'));
      expect(SanctuaryStrings.translationName('hin'), contains('Indian Revised Version'));
      expect(SanctuaryStrings.translationName('lus'), contains('Lushai Holy Bible'));
    });

    test('Canon divisions categorize Old and New Testament books accurately', () {
      expect(SanctuaryStrings.getCanonDivision('GEN'), contains('Pentateuch'));
      expect(SanctuaryStrings.getCanonDivision('PSA'), contains('Wisdom & Poetry'));
      expect(SanctuaryStrings.getCanonDivision('ISA'), contains('Major Prophets'));
      expect(SanctuaryStrings.getCanonDivision('MIC'), contains('Minor Prophets'));
      expect(SanctuaryStrings.getCanonDivision('MAT'), contains('The Gospels'));
      expect(SanctuaryStrings.getCanonDivision('JHN'), contains('The Gospels'));
      expect(SanctuaryStrings.getCanonDivision('ACT'), contains('Apostolic History'));
      expect(SanctuaryStrings.getCanonDivision('ROM'), contains('Pauline Epistles'));
      expect(SanctuaryStrings.getCanonDivision('HEB'), contains('General Epistles'));
      expect(SanctuaryStrings.getCanonDivision('REV'), contains('Apocalyptic Prophecy'));

      // Also supports full book names
      expect(SanctuaryStrings.getCanonDivision('John'), contains('The Gospels'));
      expect(SanctuaryStrings.getCanonDivision('Psalms'), contains('Wisdom & Poetry'));
      expect(SanctuaryStrings.getCanonDivision('Genesis'), contains('Pentateuch'));
    });

    test('Language endonyms are correctly mapped', () {
      expect(SanctuaryStrings.languageName('eng'), equals('English'));
      expect(SanctuaryStrings.languageName('lus'), equals('Mizo'));
      expect(SanctuaryStrings.languageName('hin'), equals('हिंदी'));
      expect(SanctuaryStrings.languageName('spa'), equals('Español'));
    });
  });

  group('BibleResearchModal Reusable Widget', () {
    testWidgets('Renders BSB translation and Gospels division for John 3:16', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    BibleResearchModal.show(
                      context,
                      item: testItem,
                      palette: StagePalette.bibleDark,
                      langCode: 'eng',
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Bible Research & Study'), findsOneWidget);
      expect(find.text('Spreading the Gospel through Living Word'), findsOneWidget);
      expect(find.textContaining('Berean Standard Bible (BSB)'), findsOneWidget);
      expect(find.textContaining('New Testament • The Gospels'), findsOneWidget);
      expect(find.textContaining('Book: JHN • Chapter 3, Verse 16'), findsOneWidget);
      expect(find.text('Spread This Gospel Verse'), findsOneWidget);
    });

    testWidgets('Tapping Spread This Gospel Verse triggers onNotice callback and live link', (tester) async {
      String? notice;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    BibleResearchModal.show(
                      context,
                      item: testItem,
                      palette: StagePalette.bibleDark,
                      langCode: 'eng',
                      onNotice: (msg) => notice = msg,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      final spreadBtn = find.text('Spread This Gospel Verse');
      await tester.ensureVisible(spreadBtn);
      await tester.pumpAndSettle();

      await tester.tap(spreadBtn);
      await tester.pumpAndSettle();

      expect(notice, equals('Copied to share gentle comfort'));
    });
  });

  group('AestheticShareModal Widget', () {
    testWidgets('Renders preview and theme switcher between Twilight and Sacred Scripture', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AestheticShareModal.show(
                      context,
                      item: testItem,
                      palette: StagePalette.bibleDark,
                    );
                  },
                  child: const Text('Open Share'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share'));
      await tester.pumpAndSettle();

      expect(find.text('Aesthetic Card Sharing'), findsOneWidget);
      expect(find.text('Sanctuary Twilight'), findsWidgets);
      expect(find.text('Sacred Scripture'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);

      // Tap 'Sacred Scripture' to switch theme
      await tester.tap(find.text('Sacred Scripture'));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Modal dismissed
      expect(find.text('Aesthetic Card Sharing'), findsNothing);
    });

    testWidgets('Tapping Copy Text copies scripture and triggers onNotice', (tester) async {
      String? notice;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AestheticShareModal.show(
                      context,
                      item: testItem,
                      palette: StagePalette.bibleDark,
                      onNotice: (msg) => notice = msg,
                    );
                  },
                  child: const Text('Open Share'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Share'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy Text'));
      await tester.pumpAndSettle();

      expect(notice, equals('Copied to share gentle comfort'));
      expect(find.text('Aesthetic Card Sharing'), findsNothing);
    });
  });

  group('WebDownloadHelper stub', () {
    test('Non-web download does not throw', () {
      expect(
        () => WebDownloadHelper.download(Uint8List.fromList([1, 2, 3]), 'test.png'),
        returnsNormally,
      );
    });
  });

  group('Target Verse Deep Linking in HomeStageScreen', () {
    testWidgets('Opening HomeStageScreen with targetVerseId focuses that card index', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeStageScreen(
            targetVerseId: 'PSA.34.18',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final homeFinder = find.byType(HomeStageScreen);
      expect(homeFinder, findsOneWidget);
      final state = tester.state<HomeStageScreenState>(homeFinder);
      final targetIndex = state.displayedItems.indexWhere((it) =>
          it.id == 'PSA.34.18' ||
          it.taggedVerse?.id == 'PSA.34.18' ||
          it.id == 'verse_PSA.34.18');
      expect(targetIndex, isNot(-1));
      expect(state.pageController.page?.round(), equals(targetIndex));
    });

    testWidgets('Opening HomeStageScreen with prefix verse_PSA.34.18 normalizes and focuses card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeStageScreen(
            targetVerseId: 'verse_PSA.34.18',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final homeFinder = find.byType(HomeStageScreen);
      expect(homeFinder, findsOneWidget);
      final state = tester.state<HomeStageScreenState>(homeFinder);
      final targetIndex = state.displayedItems.indexWhere((it) =>
          it.taggedVerse?.id == 'PSA.34.18' ||
          it.id == 'verse_PSA.34.18');
      expect(targetIndex, isNot(-1));
      expect(state.pageController.page?.round(), equals(targetIndex));
    });

    testWidgets('Opening HomeStageScreen with initialLanguage sets active language', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeStageScreen(
            initialLanguage: 'spa',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect Spanish reflection header
      expect(find.text('Un Pensamiento Suave'), findsWidgets);
    });
  });
}
