import 'dart:typed_data';

/// Stub implementation for non-web platforms.
void downloadWebFile(Uint8List bytes, String filename) {
  // No-op on mobile / desktop platforms (handled via share_plus or file saving)
}
