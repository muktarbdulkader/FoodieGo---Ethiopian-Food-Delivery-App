// Mobile-specific implementation (stub for now)
import 'dart:typed_data';

void downloadFile(Uint8List bytes, String filename) {
  // On mobile, we would save to gallery or downloads folder
  // For now, this is a no-op since QR download is primarily for web
  // In a full implementation, you would use packages like:
  // - image_gallery_saver
  // - path_provider + permission_handler
  throw UnimplementedError('Download is only available on web platform');
}
