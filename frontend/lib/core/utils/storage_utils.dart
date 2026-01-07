import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Storage Utils
/// Handles local storage operations for auth token and user data
class StorageUtils {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save auth token
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(AppConstants.tokenKey, token);
  }

  /// Get auth token
  static String? getToken() {
    return _prefs?.getString(AppConstants.tokenKey);
  }

  /// Save user data as JSON string
  static Future<void> saveUser(String userJson) async {
    await _prefs?.setString(AppConstants.userKey, userJson);
  }

  /// Get user data JSON string
  static String? getUser() {
    return _prefs?.getString(AppConstants.userKey);
  }

  /// Clear all stored data (logout)
  static Future<void> clear() async {
    await _prefs?.remove(AppConstants.tokenKey);
    await _prefs?.remove(AppConstants.userKey);
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return getToken() != null;
  }
}
