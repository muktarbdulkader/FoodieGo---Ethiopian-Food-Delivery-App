// Conditional export based on platform
export 'download_helper_web.dart' if (dart.library.io) 'download_helper_mobile.dart';
