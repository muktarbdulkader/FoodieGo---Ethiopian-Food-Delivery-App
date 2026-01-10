/// App Constants
/// Contains general application configuration values
class AppConstants {
  static const String appName = 'FoodieGo';
  static const String currency = 'ETB ';

  // Storage keys - separate for admin and user sessions
  // User session keys
  static const String userTokenKey = 'user_auth_token';
  static const String userDataKey = 'user_user_data';

  // Admin session keys
  static const String adminTokenKey = 'admin_auth_token';
  static const String adminDataKey = 'admin_user_data';

  // Session type key (to remember which portal was last used)
  static const String sessionTypeKey = 'session_type';

  // Language key
  static const String languageKey = 'app_language';
}
