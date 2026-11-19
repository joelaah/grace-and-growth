import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Contemplative text-to-speech service with gentle pacing.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  TtsService._internal() {
    _flutterTts = FlutterTts();
    _init();
  }

  late FlutterTts _flutterTts;

  @visibleForTesting
  set flutterTts(FlutterTts client) {
    _flutterTts = client;
  }

  @visibleForTesting
  FlutterTts get flutterTts => _flutterTts;

  /// Holds the ID of the item currently being read aloud, or null if idle.
  final ValueNotifier<String?> currentlySpeakingId = ValueNotifier<String?>(null);

  /// Calibrated contemplative speech rate (0.85 on Web, 0.44 on mobile/desktop).
  static double get calibratedSpeechRate => kIsWeb ? 0.85 : 0.44;

  /// Calculates speech rate given an [isWeb] flag.
  static double speechRateFor({required bool isWeb}) => isWeb ? 0.85 : 0.44;

  Future<void> _init() async {
    try {
      await _flutterTts.setSpeechRate(calibratedSpeechRate);
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
  ///
  /// For Mizo ('lus'), checks if a native Mizo synthetic voice pack is available.
  /// If unavailable, it offers [englishFallbackText] (BSB translation) or issues a respectful [onNotice].
  Future<bool> speak({
    required String id,
    required String text,
    String langCode = 'eng',
    String? englishFallbackText,
    void Function(String message)? onNotice,
  }) async {
    if (currentlySpeakingId.value == id) {
      await stop();
      return false;
    }

    try {
      await stop();
      await _flutterTts.setSpeechRate(calibratedSpeechRate);

      if (langCode == 'lus') {
        bool mizoAvailable = false;
        try {
          final res = await _flutterTts.isLanguageAvailable('lus');
          mizoAvailable = res == true || res == 1;
        } catch (_) {}

        if (mizoAvailable) {
          await _flutterTts.setLanguage('lus');
          currentlySpeakingId.value = id;
          await _flutterTts.speak(text);
          return true;
        } else if (englishFallbackText != null && englishFallbackText.isNotEmpty) {
          onNotice?.call(
            'Mizo synthetic audio voice is unavailable on this device. Listening to English reflection.',
          );
          await _flutterTts.setLanguage('en-US');
          currentlySpeakingId.value = id;
          await _flutterTts.speak(englishFallbackText);
          return true;
        } else {
          onNotice?.call(
            'Mizo synthetic audio voice is not currently installed on this device.',
          );
          currentlySpeakingId.value = null;
          return false;
        }
      }

      final locale = switch (langCode) {
        'spa' => 'es-ES',
        'hin' => 'hi-IN',
        _ => 'en-US',
      };
      await _flutterTts.setLanguage(locale);
      currentlySpeakingId.value = id;
      await _flutterTts.speak(text);
      return true;
    } catch (_) {
      currentlySpeakingId.value = null;
      return false;
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
