import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Session type enum to distinguish admin and user sessions
enum SessionType { user, admin }

/// Storage Utils
/// Handles local storage operations for auth token and user data
/// Supports separate storage for admin and user sessions
class StorageUtils {
  static SharedPreferences? _prefs;
  static SessionType _currentSessionType = SessionType.user;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Set the current session type (call this based on route)
  static void setSessionType(SessionType type) {
    _currentSessionType = type;
  }

  /// Get current session type
  static SessionType get currentSessionType => _currentSessionType;

  /// Get the appropriate token key based on session type
  static String _getTokenKey([SessionType? type]) {
    final sessionType = type ?? _currentSessionType;
    return sessionType == SessionType.admin
        ? AppConstants.adminTokenKey
        : AppConstants.userTokenKey;
  }

  /// Get the appropriate user data key based on session type
  static String _getUserKey([SessionType? type]) {
    final sessionType = type ?? _currentSessionType;
    return sessionType == SessionType.admin
        ? AppConstants.adminDataKey
        : AppConstants.userDataKey;
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

  /// Clear all sessions (both admin and user)
  static Future<void> clearAll() async {
    await _prefs?.remove(AppConstants.userTokenKey);
    await _prefs?.remove(AppConstants.userDataKey);
    await _prefs?.remove(AppConstants.adminTokenKey);
    await _prefs?.remove(AppConstants.adminDataKey);
  }

  /// Check if user is logged in for current session type
  static bool isLoggedIn([SessionType? type]) {
    return getToken(type) != null;
  }
}
