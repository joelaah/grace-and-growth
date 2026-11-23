import 'ambient_audio_player_stub.dart'
    if (dart.library.html) 'ambient_audio_player_web.dart' as ambient;

/// Ambient cathedral soundscape controller.
///
/// Layers a warm ambient pad (Web Audio API on Web, graceful stub on native)
/// beneath contemplative Scripture text-to-speech.
class AmbientAudioPlayer {
  AmbientAudioPlayer._();

  /// Starts the warm cathedral pad drone with exponential attack.
  static void startPad([double volume = 0.06]) {
    ambient.startPadWeb(volume);
  }

  /// Gently fades out the cathedral pad drone with exponential release.
  static void stopPad([bool smooth = true]) {
    ambient.stopPadWeb(smooth);
  }
}
