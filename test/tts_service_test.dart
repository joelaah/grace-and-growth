import 'package:bible_glory/services/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? lastSpokenText;
  double? lastSpeechRate;
  double? lastPitch;
  Map<dynamic, dynamic>? lastVoiceSet;

  final sampleVoices = [
    {'name': 'Microsoft David Desktop', 'locale': 'en-US'},
    {'name': 'en-us-x-sfg#female_natural-en-US', 'locale': 'en-US'},
    {'name': 'en-US-JennyNeural', 'locale': 'en-US'},
    {'name': 'en-US-GuyNeural', 'locale': 'en-US'},
  ];
  List<Map<String, String>> currentVoices = sampleVoices;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
      switch (call.method) {
        case 'isLanguageAvailable':
          if (call.arguments == 'lus') {
            return 0; // Mizo voice pack not installed
          }
          return 1;
        case 'getVoices':
          return currentVoices;
        case 'getDefaultVoice':
          return {'name': 'Microsoft David Desktop', 'locale': 'en-US'};
        case 'setSpeechRate':
          lastSpeechRate = (call.arguments as num?)?.toDouble();
          return 1;
        case 'setPitch':
          lastPitch = (call.arguments as num?)?.toDouble();
          return 1;
        case 'setVoice':
          if (call.arguments is Map) {
            lastVoiceSet = call.arguments as Map<dynamic, dynamic>;
          }
          return 1;
        case 'setVolume':
        case 'setLanguage':
          return 1;
        case 'speak':
          lastSpokenText = call.arguments?.toString();
          return 1;
        case 'stop':
          return 1;
        default:
          return 1;
      }
    });
  });

  group('TtsService Unit Tests', () {
    late TtsService ttsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      currentVoices = sampleVoices;
      ttsService = TtsService();
      await ttsService.stop();
      lastSpokenText = null;
      lastSpeechRate = null;
      lastPitch = null;
      lastVoiceSet = null;
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

    test('Contemplative breath pauses format attribution with pause ellipses', () async {
      await ttsService.speak(
        id: 'test_prosody',
        text: 'The Lord is my light and my salvation.',
        attribution: 'Psalm 27:1',
        langCode: 'eng',
      );

      expect(lastSpokenText, equals('The Lord is my light and my salvation. ... ... Psalm 27:1.'));
      await ttsService.stop();
    });

    test('Prosodic formatting leaves text plain when attribution is omitted or empty', () async {
      await ttsService.speak(
        id: 'test_plain',
        text: 'I can do all things through Christ.',
        langCode: 'eng',
      );

      expect(lastSpokenText, equals('I can do all things through Christ.'));
      await ttsService.stop();
    });

    test('Voice persona switches pitch and persists preference', () async {
      // Seraph persona (warm female, pitch 1.0)
      await ttsService.setPersona(VoicePersona.seraph);
      expect(ttsService.persona, equals(VoicePersona.seraph));
      expect(lastPitch, equals(1.0));
      expect(lastVoiceSet?['name'], contains('JennyNeural'));

      // Shepherd persona (reverent baritone, pitch 0.88)
      await ttsService.setPersona(VoicePersona.shepherd);
      expect(ttsService.persona, equals(VoicePersona.shepherd));
      expect(lastPitch, equals(0.88));
      expect(lastVoiceSet?['name'], contains('GuyNeural'));

      // System persona (standard natural, pitch 0.98)
      await ttsService.setPersona(VoicePersona.system);
      expect(ttsService.persona, equals(VoicePersona.system));
      expect(lastPitch, equals(0.98));
      expect(lastVoiceSet?['name'], equals('Microsoft David Desktop'));

      // SharedPreferences persistence verification
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sanctum_voice_persona'), equals('system'));
    });

    test('Voice persona scoring avoids selecting male voice with natural keyword for Seraph and female for Shepherd', () async {
      currentVoices = [
        {'name': 'Microsoft Guy (Natural)', 'locale': 'en-US'},
        {'name': 'Microsoft Jenny', 'locale': 'en-US'},
      ];

      // For Seraph, Jenny must be chosen over Guy even though Guy has "Natural"
      await ttsService.setPersona(VoicePersona.seraph);
      expect(lastVoiceSet?['name'], equals('Microsoft Jenny'));

      // For Shepherd, David must be chosen over Jenny even though Jenny has "Natural"
      currentVoices = [
        {'name': 'Microsoft Jenny (Natural)', 'locale': 'en-US'},
        {'name': 'Microsoft David', 'locale': 'en-US'},
      ];
      await ttsService.setPersona(VoicePersona.shepherd);
      expect(lastVoiceSet?['name'], equals('Microsoft David'));
    });

    test('Prosodic phrasing handles attributions with whitespace or periods gracefully', () async {
      await ttsService.speak(
        id: 'test_attr_period',
        text: 'The Lord is my shepherd.',
        attribution: 'Psalm 23:1.',
        langCode: 'eng',
      );
      expect(lastSpokenText, equals('The Lord is my shepherd. ... ... Psalm 23:1.'));
      await ttsService.stop();

      await ttsService.speak(
        id: 'test_attr_spaces',
        text: 'Come unto me.',
        attribution: '   ',
        langCode: 'eng',
      );
      expect(lastSpokenText, equals('Come unto me.'));
      await ttsService.stop();
    });

    test('Ambient pad toggle updates notifier and persists', () async {
      expect(ttsService.ambientPadEnabled, isTrue);

      await ttsService.setAmbientPadEnabled(false);
      expect(ttsService.ambientPadEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sanctum_ambient_pad_enabled'), isFalse);

      await ttsService.setAmbientPadEnabled(true);
      expect(ttsService.ambientPadEnabled, isTrue);
    });

    test('Cadence rate adjusts effective speech rate and persists', () async {
      await ttsService.setCadenceRate(0.75);
      expect(ttsService.cadenceRate, equals(0.75));

      final base = TtsService.speechRateFor(isWeb: kIsWeb);
      expect(ttsService.effectiveSpeechRate, closeTo(base * 0.75, 0.001));
      expect(lastSpeechRate, closeTo(ttsService.effectiveSpeechRate, 0.001));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('sanctum_cadence_rate'), equals(0.75));
    });

    test('Preview Sanctum Voice speaks sacred sample and toggles off on second tap', () async {
      final started = await ttsService.previewSanctumVoice();
      expect(started, isTrue);
      expect(ttsService.currentlySpeakingId.value, equals('preview_sanctum_sample'));
      expect(lastSpokenText, contains('The Lord is my shepherd, I shall not want.'));
      expect(lastSpokenText, contains('Psalm 23:1.'));

      // Second tap should toggle stop
      final stopped = await ttsService.previewSanctumVoice();
      expect(stopped, isFalse);
      expect(ttsService.currentlySpeakingId.value, isNull);
    });
  });
}
