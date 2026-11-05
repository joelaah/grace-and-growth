import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_glory/models/tagged_verse.dart';
import 'package:bible_glory/services/bible_api_service.dart';
import 'package:bible_glory/services/mood_matching_engine.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('MoodMatchingEngine - Seen Verses & Reset Logic', () {
    test('Skips seen verses and resets when all verses in a mood stage have been read', () async {
      // Setup test verses for MoodStage.gloomy: 2 distinct verses
      final verse1 = TaggedVerse(
        id: 'TEST.GLOOMY.1',
        book: 'PSA',
        chapter: 34,
        verse: 18,
        primaryStage: MoodStage.gloomy,
        moodTags: ['gloomy'],
        textsByLang: {'eng': 'First gloomy verse'},
        reflectionsByLang: {'eng': 'First gloomy reflection'},
      );

      final verse2 = TaggedVerse(
        id: 'TEST.GLOOMY.2',
        book: 'PSA',
        chapter: 42,
        verse: 11,
        primaryStage: MoodStage.gloomy,
        moodTags: ['gloomy'],
        textsByLang: {'eng': 'Second gloomy verse'},
        reflectionsByLang: {'eng': 'Second gloomy reflection'},
      );

      final engine = MoodMatchingEngine(
        prefs: prefs,
        seedVerses: [verse1, verse2],
      );

      // 1. First fetch: should return verse1
      final firstFetch = await engine.getVerseForMood(
        stage: MoodStage.gloomy,
        langCode: 'eng',
      );
      expect(firstFetch.verse.id, equals('TEST.GLOOMY.1'));
      expect(firstFetch.text, equals('First gloomy verse'));
      expect(firstFetch.wasReset, isFalse);

      var seenIds = prefs.getStringList(MoodMatchingEngine.seenVerseIdsKey) ?? [];
      expect(seenIds, contains('TEST.GLOOMY.1'));
      expect(seenIds, isNot(contains('TEST.GLOOMY.2')));

      // 2. Second fetch: verse1 is skipped, should return verse2
      final secondFetch = await engine.getVerseForMood(
        stage: MoodStage.gloomy,
        langCode: 'eng',
      );
      expect(secondFetch.verse.id, equals('TEST.GLOOMY.2'));
      expect(secondFetch.text, equals('Second gloomy verse'));
      expect(secondFetch.wasReset, isFalse);

      seenIds = prefs.getStringList(MoodMatchingEngine.seenVerseIdsKey) ?? [];
      expect(seenIds, containsAll(['TEST.GLOOMY.1', 'TEST.GLOOMY.2']));

      // 3. Third fetch: All verses in gloomy were read!
      // Must reset seen verses for this mood and return a verse from the reset pool
      final thirdFetch = await engine.getVerseForMood(
        stage: MoodStage.gloomy,
        langCode: 'eng',
      );
      expect(thirdFetch.wasReset, isTrue);
      expect(
        thirdFetch.verse.id,
        isIn(['TEST.GLOOMY.1', 'TEST.GLOOMY.2']),
      );

      // Now only the newly picked verse is in the seen list for this stage
      seenIds = prefs.getStringList(MoodMatchingEngine.seenVerseIdsKey) ?? [];
      expect(seenIds, contains(thirdFetch.verse.id));
      // And the other verse was cleared by the reset
      final otherId = thirdFetch.verse.id == 'TEST.GLOOMY.1'
          ? 'TEST.GLOOMY.2'
          : 'TEST.GLOOMY.1';
      expect(seenIds, isNot(contains(otherId)));
    });

    test('Does not reset or clear verses of other moods when resetting a mood', () async {
      final gloomyVerse = TaggedVerse(
        id: 'GLOOMY.1',
        book: 'PSA',
        chapter: 34,
        verse: 18,
        primaryStage: MoodStage.gloomy,
        moodTags: ['gloomy'],
        textsByLang: {'eng': 'Gloomy'},
        reflectionsByLang: {'eng': 'Gloomy reflection'},
      );

      final growingVerse = TaggedVerse(
        id: 'GROWING.1',
        book: '2CO',
        chapter: 12,
        verse: 9,
        primaryStage: MoodStage.growing,
        moodTags: ['growing'],
        textsByLang: {'eng': 'Growing'},
        reflectionsByLang: {'eng': 'Growing reflection'},
      );

      final engine = MoodMatchingEngine(
        prefs: prefs,
        seedVerses: [gloomyVerse, growingVerse],
      );

      // Read growing verse
      await engine.getVerseForMood(stage: MoodStage.growing);
      var seen = prefs.getStringList(MoodMatchingEngine.seenVerseIdsKey) ?? [];
      expect(seen, contains('GROWING.1'));

      // Read gloomy verse (only 1 available, so read once)
      await engine.getVerseForMood(stage: MoodStage.gloomy);
      seen = prefs.getStringList(MoodMatchingEngine.seenVerseIdsKey) ?? [];
      expect(seen, containsAll(['GROWING.1', 'GLOOMY.1']));

      // Read gloomy again -> all gloomy read, so reset gloomy only!
      final result = await engine.getVerseForMood(stage: MoodStage.gloomy);
      expect(result.wasReset, isTrue);

      seen = prefs.getStringList(MoodMatchingEngine.seenVerseIdsKey) ?? [];
      // GROWING.1 must still be preserved in seen list
      expect(seen, contains('GROWING.1'));
      expect(seen, contains('GLOOMY.1'));
    });

    test('Returns humble reflection in selected language (eng, spa, hin, lus)', () async {
      final engine = MoodMatchingEngine(prefs: prefs);

      final engResult = await engine.getVerseForMood(
        stage: MoodStage.bright,
        langCode: 'eng',
      );
      expect(engResult.reflection, equals(engResult.verse.reflectionFor('eng')));
      expect(engResult.reflection, isNotEmpty);

      final spaResult = await engine.getVerseForMood(
        stage: MoodStage.bright,
        langCode: 'spa',
      );
      expect(spaResult.reflection, equals(spaResult.verse.reflectionFor('spa')));
      expect(spaResult.reflection, isNotEmpty);

      final hinResult = await engine.getVerseForMood(
        stage: MoodStage.bright,
        langCode: 'hin',
      );
      expect(hinResult.reflection, equals(hinResult.verse.reflectionFor('hin')));
      expect(hinResult.reflection, isNotEmpty);

      final lusResult = await engine.getVerseForMood(
        stage: MoodStage.bright,
        langCode: 'lus',
      );
      expect(lusResult.reflection, equals(lusResult.verse.reflectionFor('lus')));
      expect(lusResult.reflection, isNotEmpty);
    });
  });

  group('BibleApiService - Offline Caching & Universal ID Parsing', () {
    test('Parses universal ID correctly', () {
      final parsed = BibleApiService.parseUniversalId('PSA.34.18');
      expect(parsed, isNotNull);
      expect(parsed!.book, equals('PSA'));
      expect(parsed.chapter, equals(34));
      expect(parsed.verse, equals(18));

      final parsed2 = BibleApiService.parseUniversalId('2CO.12.9');
      expect(parsed2, isNotNull);
      expect(parsed2!.book, equals('2CO'));
      expect(parsed2.chapter, equals(12));
      expect(parsed2.verse, equals(9));

      expect(BibleApiService.parseUniversalId('INVALID'), isNull);
    });

    test('Extracts verse text from helloao chapter JSON structure', () {
      final service = BibleApiService(prefs: prefs);

      final sampleChapterJson = {
        'translation': {'id': 'BSB'},
        'book': {'id': 'PSA', 'name': 'Psalms'},
        'chapter': {
          'number': 34,
          'content': [
            {
              'type': 'verse',
              'number': 18,
              'content': [
                {'text': 'The LORD is near to the brokenhearted;', 'poem': 1},
                {'text': 'He saves the contrite in spirit.', 'poem': 2},
              ],
            },
          ],
        },
      };

      final text = service.extractVerseFromChapter(sampleChapterJson, 18);
      expect(text, equals('The LORD is near to the brokenhearted; He saves the contrite in spirit.'));
    });

    test('Caches chapter in SharedPreferences for offline reading', () async {
      final service = BibleApiService(prefs: prefs);

      final cacheKey = service.chapterCacheKey('BSB', 'PSA', 34);
      expect(await service.isChapterCached(book: 'PSA', chapter: 34), isFalse);

      // Simulate cached chapter in SharedPreferences
      await prefs.setString(
        cacheKey,
        '''{
          "chapter": {
            "content": [
              {
                "type": "verse",
                "number": 18,
                "content": ["The Lord is close to the brokenhearted."]
              }
            ]
          }
        }''',
      );

      expect(await service.isChapterCached(book: 'PSA', chapter: 34), isTrue);

      final text = await service.getVerseText(
        universalId: 'PSA.34.18',
        langOrTranslation: 'eng',
      );

      expect(text, equals('The Lord is close to the brokenhearted.'));
    });
  });

  group('Seed Verses JSON Asset Verification', () {
    test('Contains 12 starter verses across all 4 mood stages with full translations', () async {
      // Load file from asset bundle
      final jsonStr = await rootBundle.loadString('assets/seed_verses.json');
      final list = jsonDecode(jsonStr) as List;

      expect(list.length, equals(12));

      final verses = list.map((e) => TaggedVerse.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      final gloomy = verses.where((v) => v.primaryStage == MoodStage.gloomy).toList();
      final growing = verses.where((v) => v.primaryStage == MoodStage.growing).toList();
      final bright = verses.where((v) => v.primaryStage == MoodStage.bright).toList();
      final humble = verses.where((v) => v.primaryStage == MoodStage.humble).toList();

      expect(gloomy.length, equals(3));
      expect(growing.length, equals(3));
      expect(bright.length, equals(3));
      expect(humble.length, equals(3));

      // Key requested verses
      final verseIds = verses.map((v) => v.id).toList();
      expect(verseIds, contains('PSA.34.18'));
      expect(verseIds, contains('ECC.7.3'));
      expect(verseIds, contains('ROM.5.3'));
      expect(verseIds, contains('PSA.118.24'));
      expect(verseIds, contains('MIC.6.8'));

      // Check all 4 languages for reflections
      for (final v in verses) {
        expect(v.reflectionFor('eng'), isNotEmpty);
        expect(v.reflectionFor('lus'), isNotEmpty);
        expect(v.reflectionFor('hin'), isNotEmpty);
        expect(v.reflectionFor('spa'), isNotEmpty);
      }
    });
  });
}
