import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_glory/services/quote_api_service.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('QuoteApiService - Keyword Mood Classification', () {
    test('Classifies gloomy keywords accurately', () {
      expect(
        QuoteApiService.classifyMood('There is deep sorrow and pain in grief.'),
        equals(MoodStage.gloomy),
      );
      expect(
        QuoteApiService.classifyMood('A heavy heart carrying tears in the dark.'),
        equals(MoodStage.gloomy),
      );
    });

    test('Classifies growing keywords accurately', () {
      expect(
        QuoteApiService.classifyMood('Growth requires patience, endurance, and quiet progress.'),
        equals(MoodStage.growing),
      );
      expect(
        QuoteApiService.classifyMood('A seed must learn to overcome the dark soil on its journey.'),
        equals(MoodStage.growing),
      );
    });

    test('Classifies bright keywords accurately', () {
      expect(
        QuoteApiService.classifyMood('Joy and gratitude bring radiant sunshine and delight.'),
        equals(MoodStage.bright),
      );
      expect(
        QuoteApiService.classifyMood('Celebrate the light with a cheerful smile and thankful heart.'),
        equals(MoodStage.bright),
      );
    });

    test('Classifies humble keywords accurately', () {
      expect(
        QuoteApiService.classifyMood('Silence and stillness teach us to walk gently with humility.'),
        equals(MoodStage.humble),
      );
      expect(
        QuoteApiService.classifyMood('In quiet simplicity, true wisdom rests in mercy and peace.'),
        equals(MoodStage.humble),
      );
    });
  });

  group('QuoteApiService - Primary & Fallback API Fetching', () {
    test('Fetches from ZenQuotes primary API when successful', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == QuoteApiService.zenQuotesUrl) {
          final json = [
            {'q': 'The cure for pain is in the pain.', 'a': 'Rumi'},
            {'q': 'Joy is the simplest form of gratitude.', 'a': 'Karl Barth'},
          ];
          return http.Response(jsonEncode(json), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = QuoteApiService(prefs: prefs, httpClient: mockClient);
      final quotes = await service.getQuotes(forceRefresh: true);

      expect(quotes.length, equals(2));
      expect(quotes[0].quote, equals('The cure for pain is in the pain.'));
      expect(quotes[0].author, equals('Rumi'));
      expect(quotes[0].stage, equals(MoodStage.gloomy));
      expect(quotes[1].quote, equals('Joy is the simplest form of gratitude.'));
      expect(quotes[1].author, equals('Karl Barth'));
      expect(quotes[1].stage, equals(MoodStage.bright));

      // Verifies quotes were cached in SharedPreferences
      expect(prefs.containsKey(QuoteApiService.cacheKey), isTrue);
    });

    test('Falls back to DummyJSON API when ZenQuotes fails', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == QuoteApiService.zenQuotesUrl) {
          return http.Response('Internal Error', 500);
        }
        if (request.url.toString() == QuoteApiService.dummyJsonQuotesUrl) {
          final json = {
            'quotes': [
              {
                'id': 101,
                'quote': 'Patience is quiet strength in endurance and growth.',
                'author': 'Joyce Meyer',
              },
            ],
          };
          return http.Response(jsonEncode(json), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = QuoteApiService(prefs: prefs, httpClient: mockClient);
      final quotes = await service.getQuotes(forceRefresh: true);

      expect(quotes.length, equals(1));
      expect(quotes[0].id, equals('dj_101'));
      expect(quotes[0].quote, contains('Patience is quiet strength'));
      expect(quotes[0].author, equals('Joyce Meyer'));
      expect(quotes[0].stage, equals(MoodStage.growing));
    });

    test('Falls back to SharedPreferences cache when network calls fail', () async {
      // Pre-seed cache
      final cachedJson = [
        {
          'id': 'cached_1',
          'quote': 'Offline wisdom is precious.',
          'author': 'Sage',
          'stage': 'humble',
          'category': 'Quiet Walk',
          'sub_tag': 'Peace',
          'reflection': 'Rest peacefully offline.',
          'prompt': 'Breathe gently.',
        }
      ];
      await prefs.setString(QuoteApiService.cacheKey, jsonEncode(cachedJson));

      final mockClient = MockClient((request) async {
        throw Exception('No network');
      });

      final service = QuoteApiService(prefs: prefs, httpClient: mockClient);
      final quotes = await service.getQuotes();

      expect(quotes.length, equals(1));
      expect(quotes[0].id, equals('cached_1'));
      expect(quotes[0].quote, equals('Offline wisdom is precious.'));
      expect(quotes[0].stage, equals(MoodStage.humble));
    });

    test('Falls back to curated seed quotes when cache and network are unavailable', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Offline');
      });

      final service = QuoteApiService(prefs: prefs, httpClient: mockClient);
      final quotes = await service.getQuotes(forceRefresh: true);

      expect(quotes.isNotEmpty, isTrue);
      expect(quotes.any((q) => q.stage == MoodStage.gloomy), isTrue);
      expect(quotes.any((q) => q.stage == MoodStage.growing), isTrue);
      expect(quotes.any((q) => q.stage == MoodStage.bright), isTrue);
      expect(quotes.any((q) => q.stage == MoodStage.humble), isTrue);
    });
  });
}
