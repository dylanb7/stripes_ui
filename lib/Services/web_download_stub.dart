// Stub implementation for non-web platforms
// These functions should never be called on non-web platforms

void downloadFile(String content, String filename, String mimeType) {
  throw UnsupportedError('downloadFile is only available on web');
}

void downloadBytes(List<int> bytes, String filename, String mimeType) {
  throw UnsupportedError('downloadBytes is only available on web');
}
