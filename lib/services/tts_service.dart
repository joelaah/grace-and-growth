import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/ambient_audio_player.dart';

/// Available sacred voice personas for contemplative Scripture reflection.
enum VoicePersona {
  /// Warm, gentle, and contemplative female voice.
  seraph,

  /// Deep, calm, and reverent baritone voice.
  shepherd,

  /// Standard natural system voice pack.
  system,
}

/// Contemplative text-to-speech service with ambient soundscape layering and gentle pacing.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  static const String _keyPersona = 'sanctum_voice_persona';
  static const String _keyAmbientPad = 'sanctum_ambient_pad_enabled';
  static const String _keyCadenceRate = 'sanctum_cadence_rate';

  TtsService._internal() {
    _flutterTts = FlutterTts();
    _init();
  }

  late FlutterTts _flutterTts;
  SharedPreferences? _prefs;
  String? _lastLocale;

  @visibleForTesting
  set flutterTts(FlutterTts client) {
    _flutterTts = client;
  }

  @visibleForTesting
  FlutterTts get flutterTts => _flutterTts;

  @visibleForTesting
  set preferences(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Holds the ID of the item currently being read aloud, or null if idle.
  final ValueNotifier<String?> currentlySpeakingId = ValueNotifier<String?>(null);

  /// Active voice persona notifier.
  final ValueNotifier<VoicePersona> personaNotifier =
      ValueNotifier<VoicePersona>(VoicePersona.seraph);

  /// Ambient pad enabled state notifier.
  final ValueNotifier<bool> ambientPadNotifier = ValueNotifier<bool>(true);

  /// Contemplative cadence rate multiplier notifier.
  final ValueNotifier<double> cadenceRateNotifier = ValueNotifier<double>(0.85);

  /// Active voice persona.
  VoicePersona get persona => personaNotifier.value;

  /// Whether the ambient cathedral pad drone is enabled.
  bool get ambientPadEnabled => ambientPadNotifier.value;

  /// Current contemplative cadence multiplier (0.75x, 0.85x, 1.0x).
  double get cadenceRate => cadenceRateNotifier.value;

  /// Calibrated contemplative base speech rate (0.85 on Web, 0.44 on mobile/desktop).
  static double get calibratedSpeechRate => kIsWeb ? 0.85 : 0.44;

  /// Calculates base speech rate given an [isWeb] flag.
  static double speechRateFor({required bool isWeb}) => isWeb ? 0.85 : 0.44;

  /// Effective speech rate multiplying platform base by contemplative cadence multiplier.
  double get effectiveSpeechRate =>
      (speechRateFor(isWeb: kIsWeb) * cadenceRateNotifier.value).clamp(0.1, 1.0);

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;

      final personaStr = prefs.getString(_keyPersona);
      if (personaStr != null) {
        if (personaStr == 'shepherd') {
          personaNotifier.value = VoicePersona.shepherd;
        } else if (personaStr == 'system') {
          personaNotifier.value = VoicePersona.system;
        } else {
          personaNotifier.value = VoicePersona.seraph;
        }
      }

      final ambient = prefs.getBool(_keyAmbientPad);
      if (ambient != null) {
        ambientPadNotifier.value = ambient;
      }

      final cadence = prefs.getDouble(_keyCadenceRate);
      if (cadence != null && cadence > 0) {
        cadenceRateNotifier.value = cadence;
      }
    } catch (_) {}
  }

  Future<void> _init() async {
    try {
      await _loadPersistedSettings();
      await _flutterTts.setSpeechRate(effectiveSpeechRate);
      await _applyVoiceConfiguration('en-US');
      await _flutterTts.setVolume(1.0);

      _flutterTts.setCompletionHandler(() {
        currentlySpeakingId.value = null;
        AmbientAudioPlayer.stopPad(true);
      });

      _flutterTts.setCancelHandler(() {
        currentlySpeakingId.value = null;
        AmbientAudioPlayer.stopPad(true);
      });

      _flutterTts.setErrorHandler((_) {
        currentlySpeakingId.value = null;
        AmbientAudioPlayer.stopPad(true);
      });
    } catch (_) {
      // Web or unsupported platform safety
    }
  }

  /// Sets and persists the sacred voice persona.
  Future<void> setPersona(VoicePersona newPersona) async {
    personaNotifier.value = newPersona;
    try {
      final prefs = await _getPrefs();
      await prefs?.setString(_keyPersona, newPersona.name);
    } catch (_) {}
    await _applyVoiceConfiguration(_lastLocale ?? 'en-US');
  }

  /// Sets and persists whether the ambient cathedral drone plays behind Scripture.
  Future<void> setAmbientPadEnabled(bool enabled) async {
    ambientPadNotifier.value = enabled;
    try {
      final prefs = await _getPrefs();
      await prefs?.setBool(_keyAmbientPad, enabled);
    } catch (_) {}

    if (!enabled) {
      AmbientAudioPlayer.stopPad(true);
    } else if (currentlySpeakingId.value != null) {
      AmbientAudioPlayer.startPad(0.06);
    }
  }

  /// Sets and persists the contemplative cadence multiplier.
  Future<void> setCadenceRate(double rate) async {
    cadenceRateNotifier.value = rate;
    try {
      final prefs = await _getPrefs();
      await prefs?.setDouble(_keyCadenceRate, rate);
    } catch (_) {}
    try {
      await _flutterTts.setSpeechRate(effectiveSpeechRate);
    } catch (_) {}
  }

  /// Applies pitch, tone, and selects the highest-scoring natural voice pack matching [locale] and persona.
  Future<void> _applyVoiceConfiguration(String locale) async {
    try {
      final pitch = switch (personaNotifier.value) {
        VoicePersona.seraph => 1.0,
        VoicePersona.shepherd => 0.88,
        VoicePersona.system => 0.98,
      };
      await _flutterTts.setPitch(pitch);

      if (personaNotifier.value == VoicePersona.system) {
        // Reset to system default voice pack
        try {
          final dynamic defaultVoice = await _flutterTts.getDefaultVoice;
          if (defaultVoice is Map && defaultVoice['name'] != null) {
            await _flutterTts.setVoice({
              'name': defaultVoice['name'].toString(),
              'locale': (defaultVoice['locale'] ?? locale).toString(),
            });
            return;
          }
        } catch (_) {}
        try {
          await _flutterTts.setVoice({
            'name': '',
            'locale': locale,
          });
        } catch (_) {}
        return;
      }

      final dynamic voicesRaw = await _flutterTts.getVoices;
      if (voicesRaw is List && voicesRaw.isNotEmpty) {
        final voices = voicesRaw.whereType<Map>().toList();
        final langPrefix = locale.split('-').first.toLowerCase();
        final localeVoices = voices.where((v) {
          final loc = (v['locale'] ?? v['lang'] ?? '').toString().toLowerCase();
          return loc.startsWith(langPrefix) || loc.contains(langPrefix);
        }).toList();

        final candidates = localeVoices.isNotEmpty ? localeVoices : voices;

        final isSeraph = personaNotifier.value == VoicePersona.seraph;
        final personaKeywords = isSeraph
            ? const [
                'jenny', 'aria', 'samantha', 'ava', 'victoria',
                'karen', 'zira', 'female',
              ]
            : const [
                'guy', 'christopher', 'daniel', 'david', 'male',
              ];

        final oppositeKeywords = isSeraph
            ? const [
                'guy', 'christopher', 'daniel', 'david', 'male',
              ]
            : const [
                'jenny', 'aria', 'samantha', 'ava', 'victoria',
                'karen', 'zira', 'female',
              ];

        final qualityKeywords = const [
          'natural', 'neural', 'online', 'google',
        ];

        Map? bestVoice;
        int bestScore = -1;

        for (final voice in candidates) {
          final name = (voice['name'] ?? voice['voiceURI'] ?? '').toString().toLowerCase();
          final gender = (voice['gender'] ?? '').toString().toLowerCase();
          final descriptor = '$name $gender';

          int score = 0;

          // Reward matching persona gender/names
          for (int i = 0; i < personaKeywords.length; i++) {
            if (descriptor.contains(personaKeywords[i])) {
              score += 30 + (personaKeywords.length - i);
            }
          }

          // Penalize conflicting opposite persona markers to prevent gender confusion
          for (int i = 0; i < oppositeKeywords.length; i++) {
            if (descriptor.contains(oppositeKeywords[i])) {
              score -= 50;
            }
          }

          // Quality bonuses (natural, neural, online, google)
          for (int i = 0; i < qualityKeywords.length; i++) {
            if (descriptor.contains(qualityKeywords[i])) {
              score += 10 + (qualityKeywords.length - i);
            }
          }

          if (score > bestScore) {
            bestScore = score;
            bestVoice = voice;
          }
        }

        if (bestVoice != null && bestScore > 0) {
          final voiceName = (bestVoice['name'] ?? bestVoice['voiceURI'])?.toString();
          final voiceLocale = (bestVoice['locale'] ?? bestVoice['lang'] ?? locale)?.toString();
          if (voiceName != null) {
            await _flutterTts.setVoice({
              'name': voiceName,
              'locale': voiceLocale ?? locale,
            });
          }
        }
      }
    } catch (_) {}
  }

  /// Formats contemplative breath pauses before an optional scripture attribution.
  String _formatSpokenText(String content, String? attribution) {
    final cleanContent = content.trim();
    if (attribution == null || attribution.trim().isEmpty) {
      return cleanContent;
    }
    final cleanAttr = attribution.trim();
    final formattedAttr = cleanAttr.endsWith('.') ? cleanAttr : '$cleanAttr.';
    return '$cleanContent ... ... $formattedAttr';
  }

  /// Speaks a short sacred sample to immediately preview the active voice persona & ambient soundscape.
  Future<bool> previewSanctumVoice() async {
    const previewId = 'preview_sanctum_sample';
    if (currentlySpeakingId.value == previewId) {
      await stop();
      return false;
    }
    return speak(
      id: previewId,
      text: 'The Lord is my shepherd, I shall not want.',
      attribution: 'Psalm 23:1',
      langCode: 'eng',
    );
  }

  /// Speaks the provided [text] for card [id] in a calm, paced cadence.
  ///
  /// Contemplative breath pauses are introduced when [attribution] is provided.
  /// For Mizo ('lus'), checks if a native Mizo synthetic voice pack is available.
  /// If unavailable, it offers [englishFallbackText] (BSB translation) or issues a respectful [onNotice].
  Future<bool> speak({
    required String id,
    required String text,
    String langCode = 'eng',
    String? englishFallbackText,
    String? attribution,
    void Function(String message)? onNotice,
  }) async {
    if (currentlySpeakingId.value == id) {
      await stop();
      return false;
    }

    try {
      await stop();
      await _flutterTts.setSpeechRate(effectiveSpeechRate);

      if (langCode == 'lus') {
        bool mizoAvailable = false;
        try {
          final res = await _flutterTts.isLanguageAvailable('lus');
          mizoAvailable = res == true || res == 1;
        } catch (_) {}

        if (mizoAvailable) {
          _lastLocale = 'lus';
          await _flutterTts.setLanguage('lus');
          await _applyVoiceConfiguration('lus');
          currentlySpeakingId.value = id;
          if (ambientPadNotifier.value) {
            AmbientAudioPlayer.startPad(0.06);
          }
          final spoken = _formatSpokenText(text, attribution);
          await _flutterTts.speak(spoken);
          return true;
        } else if (englishFallbackText != null && englishFallbackText.isNotEmpty) {
          onNotice?.call(
            'Mizo synthetic audio voice is unavailable on this device. Listening to English reflection.',
          );
          _lastLocale = 'en-US';
          await _flutterTts.setLanguage('en-US');
          await _applyVoiceConfiguration('en-US');
          currentlySpeakingId.value = id;
          if (ambientPadNotifier.value) {
            AmbientAudioPlayer.startPad(0.06);
          }
          final spoken = _formatSpokenText(englishFallbackText, attribution);
          await _flutterTts.speak(spoken);
          return true;
        } else {
          onNotice?.call(
            'Mizo synthetic audio voice is not currently installed on this device.',
          );
          currentlySpeakingId.value = null;
          AmbientAudioPlayer.stopPad(true);
          return false;
        }
      }

      final locale = switch (langCode) {
        'spa' => 'es-ES',
        'hin' => 'hi-IN',
        _ => 'en-US',
      };
      _lastLocale = locale;
      await _flutterTts.setLanguage(locale);
      await _applyVoiceConfiguration(locale);
      currentlySpeakingId.value = id;
      if (ambientPadNotifier.value) {
        AmbientAudioPlayer.startPad(0.06);
      }
      final spoken = _formatSpokenText(text, attribution);
      await _flutterTts.speak(spoken);
      return true;
    } catch (_) {
      currentlySpeakingId.value = null;
      AmbientAudioPlayer.stopPad(true);
      return false;
    }
  }

  /// Stops any currently active speech and fades out ambient soundscape.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    currentlySpeakingId.value = null;
    AmbientAudioPlayer.stopPad(true);
  }
}
