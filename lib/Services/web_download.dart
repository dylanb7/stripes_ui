import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Downloads a text file in the browser
void downloadFile(String content, String filename, String mimeType) {
  final bytes = utf8.encode(content);
  downloadBytes(bytes, filename, mimeType);
}

/// Downloads a binary file in the browser
void downloadBytes(List<int> bytes, String filename, String mimeType) {
  // Create a Blob from the bytes
  final jsArray = Uint8List.fromList(bytes).toJS;
  final blob = web.Blob([jsArray].toJS, web.BlobPropertyBag(type: mimeType));

  // Create object URL
  final url = web.URL.createObjectURL(blob);

  // Create anchor element and trigger download
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);

  // Clean up
  web.URL.revokeObjectURL(url);
}
