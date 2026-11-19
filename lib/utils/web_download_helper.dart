import 'dart:typed_data';
import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper_web.dart' as helper;

/// Cross-platform helper to trigger direct browser file downloads on Flutter Web.
class WebDownloadHelper {
  WebDownloadHelper._();

  /// Downloads [bytes] as a file with [filename] in Web browsers.
  /// Safely does nothing on native platforms where native share/file IO is used instead.
  static void download(Uint8List bytes, String filename) {
    helper.downloadWebFile(bytes, filename);
  }
}
