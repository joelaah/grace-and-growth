import 'package:bible_glory/services/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      switch (call.method) {
        case 'isLanguageAvailable':
          if (call.arguments == 'lus') {
            return 0; // Mizo voice pack not installed
          }
          return 1;
        case 'setSpeechRate':
        case 'setPitch':
        case 'setVolume':
        case 'setLanguage':
        case 'speak':
        case 'stop':
          return 1;
        default:
          return 1;
      }
    });
  });

  group('TtsService Unit Tests', () {
    late TtsService ttsService;

    setUp(() {
      ttsService = TtsService();
      ttsService.stop();
    });

    test('Speech rate calibration respects platform rules', () {
      expect(TtsService.speechRateFor(isWeb: true), equals(0.85));
      expect(TtsService.speechRateFor(isWeb: false), equals(0.44));
      expect(
        TtsService.calibratedSpeechRate,
        equals(kIsWeb ? 0.85 : 0.44),
      );
    });

    test('Initial currentlySpeakingId is null and stop() keeps it null', () async {
      expect(ttsService.currentlySpeakingId.value, isNull);
      await ttsService.stop();
      expect(ttsService.currentlySpeakingId.value, isNull);
    });

    test('Mizo (lus) gracefully issues notice when voice is not installed without fallback', () async {
      String? noticeReceived;
      final result = await ttsService.speak(
        id: 'verse_mizo_1',
        text: 'LALPA chu ka chawmtu a ni a.',
        langCode: 'lus',
        onNotice: (msg) => noticeReceived = msg,
      );

      // In unit test environment without Mizo TTS installed:
      expect(noticeReceived, isNotNull);
      expect(noticeReceived, contains('Mizo'));
      // Since no fallback was provided and synthetic voice is unavailable, it reports false
      expect(result, isFalse);
      expect(ttsService.currentlySpeakingId.value, isNull);
    });

    test('Mizo (lus) falls back to English reflection with respectful notice', () async {
      String? noticeReceived;
      final result = await ttsService.speak(
        id: 'verse_mizo_2',
        text: 'LALPA chu ka chawmtu a ni a.',
        langCode: 'lus',
        englishFallbackText: 'The Lord is my shepherd.',
        onNotice: (msg) => noticeReceived = msg,
      );

      expect(noticeReceived, isNotNull);
      expect(noticeReceived, contains('Mizo synthetic audio voice is unavailable'));
      // Falls back to speaking the English text
      expect(result, isTrue);
      expect(ttsService.currentlySpeakingId.value, equals('verse_mizo_2'));

      // Toggling the same ID should stop speech
      await ttsService.speak(
        id: 'verse_mizo_2',
        text: 'The Lord is my shepherd.',
      );
      expect(ttsService.currentlySpeakingId.value, isNull);
    });

    test('Mizo (lus) falls back to English quote text when available', () async {
      String? noticeReceived;
      final result = await ttsService.speak(
        id: 'quote_mizo_1',
        text: 'Mizo text',
        langCode: 'lus',
        englishFallbackText: 'Peace begins with a smile.',
        onNotice: (msg) => noticeReceived = msg,
      );

      expect(noticeReceived, contains('Mizo synthetic audio voice is unavailable'));
      expect(result, isTrue);
      expect(ttsService.currentlySpeakingId.value, equals('quote_mizo_1'));
      await ttsService.stop();
    });

    test('Toggling speech stops playback immediately', () async {
      await ttsService.speak(
        id: 'test_verse_toggle',
        text: 'Be still, and know that I am God.',
        langCode: 'eng',
      );
      expect(ttsService.currentlySpeakingId.value, equals('test_verse_toggle'));

      // Speak again with same id
      await ttsService.speak(
        id: 'test_verse_toggle',
        text: 'Be still, and know that I am God.',
        langCode: 'eng',
      );
      expect(ttsService.currentlySpeakingId.value, isNull);
    });
  });
}
