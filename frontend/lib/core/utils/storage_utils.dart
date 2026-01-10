import 'package:shared_preferences/shared_preferences.dart';

/// Session type enum to distinguish different user sessions
enum SessionType { user, admin, delivery }

/// Storage Utils
/// Handles local storage operations for auth token and user data
/// Supports separate storage for user, admin (restaurant), and delivery sessions
class StorageUtils {
  static SharedPreferences? _prefs;
  static SessionType _currentSessionType = SessionType.user;

  // Storage keys for each session type
  static const String _userTokenKey = 'user_token';
  static const String _userDataKey = 'user_data';
  static const String _adminTokenKey = 'admin_token';
  static const String _adminDataKey = 'admin_data';
  static const String _deliveryTokenKey = 'delivery_token';
  static const String _deliveryDataKey = 'delivery_data';
  static const String _lastSessionKey = 'last_session_type';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Restore last session type
    final lastSession = _prefs?.getString(_lastSessionKey);
    if (lastSession != null) {
      _currentSessionType = SessionType.values.firstWhere(
        (e) => e.name == lastSession,
        orElse: () => SessionType.user,
      );
    }
  }

  /// Set the current session type (call this based on route)
  static void setSessionType(SessionType type) {
    _currentSessionType = type;
    _prefs?.setString(_lastSessionKey, type.name);
  }

  /// Get current session type
  static SessionType get currentSessionType => _currentSessionType;

  /// Get the appropriate token key based on session type
  static String _getTokenKey([SessionType? type]) {
    final sessionType = type ?? _currentSessionType;
    switch (sessionType) {
      case SessionType.admin:
        return _adminTokenKey;
      case SessionType.delivery:
        return _deliveryTokenKey;
      case SessionType.user:
        return _userTokenKey;
    }
  }

  /// Get the appropriate user data key based on session type
  static String _getUserKey([SessionType? type]) {
    final sessionType = type ?? _currentSessionType;
    switch (sessionType) {
      case SessionType.admin:
        return _adminDataKey;
      case SessionType.delivery:
        return _deliveryDataKey;
      case SessionType.user:
        return _userDataKey;
    }
  }

  /// Save auth token for current session type
  static Future<void> saveToken(String token, [SessionType? type]) async {
    await _prefs?.setString(_getTokenKey(type), token);
  }

  /// Get auth token for current session type
  static String? getToken([SessionType? type]) {
    return _prefs?.getString(_getTokenKey(type));
  }

  /// Save user data as JSON string for current session type
  static Future<void> saveUser(String userJson, [SessionType? type]) async {
    await _prefs?.setString(_getUserKey(type), userJson);
  }

  /// Get user data JSON string for current session type
  static String? getUser([SessionType? type]) {
    return _prefs?.getString(_getUserKey(type));
  }

  /// Clear stored data for current session type only (logout)
  static Future<void> clear([SessionType? type]) async {
    await _prefs?.remove(_getTokenKey(type));
    await _prefs?.remove(_getUserKey(type));
  }

  /// Clear all sessions (user, admin, and delivery)
  static Future<void> clearAll() async {
    await _prefs?.remove(_userTokenKey);
    await _prefs?.remove(_userDataKey);
    await _prefs?.remove(_adminTokenKey);
    await _prefs?.remove(_adminDataKey);
    await _prefs?.remove(_deliveryTokenKey);
    await _prefs?.remove(_deliveryDataKey);
  }

  /// Check if user is logged in for current session type
  static bool isLoggedIn([SessionType? type]) {
    return getToken(type) != null;
  }

  /// Check if any session is logged in
  static bool isAnySessionLoggedIn() {
    return isLoggedIn(SessionType.user) ||
        isLoggedIn(SessionType.admin) ||
        isLoggedIn(SessionType.delivery);
  }
}
