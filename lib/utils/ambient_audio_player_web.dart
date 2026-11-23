// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

/// Web implementation interfacing with window.SanctumAudio Web Audio synthesizer.
void startPadWeb(double volume) {
  try {
    final sanctumAudio = js_util.getProperty(html.window, 'SanctumAudio');
    if (sanctumAudio != null) {
      js_util.callMethod(sanctumAudio, 'startPad', [volume]);
    }
  } catch (_) {}
}

/// Web implementation stopping window.SanctumAudio ambient drone.
void stopPadWeb(bool smooth) {
  try {
    final sanctumAudio = js_util.getProperty(html.window, 'SanctumAudio');
    if (sanctumAudio != null) {
      js_util.callMethod(sanctumAudio, 'stopPad', [smooth]);
    }
  } catch (_) {}
}
