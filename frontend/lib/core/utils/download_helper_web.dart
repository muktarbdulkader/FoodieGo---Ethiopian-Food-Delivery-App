// Web-specific implementation using package:web
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadFile(Uint8List bytes, String filename) {
  // Create a blob from the bytes
  final blob = web.Blob([bytes.toJS].toJS);
  
  // Create a URL for the blob
  final url = web.URL.createObjectURL(blob);
  
  // Create an anchor element and trigger download
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  
  // Clean up the URL
  web.URL.revokeObjectURL(url);
}
