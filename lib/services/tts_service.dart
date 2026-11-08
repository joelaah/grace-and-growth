import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Contemplative text-to-speech service with gentle pacing.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  TtsService._internal() {
    _init();
  }

  final FlutterTts _flutterTts = FlutterTts();

  /// Holds the ID of the item currently being read aloud, or null if idle.
  final ValueNotifier<String?> currentlySpeakingId = ValueNotifier<String?>(null);

  Future<void> _init() async {
    try {
      await _flutterTts.setSpeechRate(0.44);
      await _flutterTts.setPitch(0.98);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setCompletionHandler(() {
        currentlySpeakingId.value = null;
      });

      _flutterTts.setCancelHandler(() {
        currentlySpeakingId.value = null;
      });

      _flutterTts.setErrorHandler((_) {
        currentlySpeakingId.value = null;
      });
    } catch (_) {
      // Web or unsupported platform safety
    }
  }

  /// Speaks the provided [text] for card [id] in a calm, paced cadence.
  Future<void> speak({
    required String id,
    required String text,
    String langCode = 'eng',
  }) async {
    if (currentlySpeakingId.value == id) {
      await stop();
      return;
    }

    try {
      await stop();
      final locale = switch (langCode) {
        'spa' => 'es-ES',
        'hin' => 'hi-IN',
        'lus' => 'en-US',
        _ => 'en-US',
      };
      await _flutterTts.setLanguage(locale);
      currentlySpeakingId.value = id;
      await _flutterTts.speak(text);
    } catch (_) {
      currentlySpeakingId.value = null;
    }
  }

  /// Stops any currently active speech.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    currentlySpeakingId.value = null;
  }
}
