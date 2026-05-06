import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Offline storage utility for caching data locally
class OfflineStorage {
  static const String _menuKey = 'offline_menu';
  static const String _ordersKey = 'offline_orders';
  static const String _hotelsKey = 'offline_hotels';
  static const String _lastUpdateKey = 'last_update_';
  
  /// Save menu for offline use
  static Future<void> saveMenu(List<dynamic> foods) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_menuKey, jsonEncode(foods));
      await prefs.setString('$_lastUpdateKey$_menuKey', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving menu: $e');
    }
  }
  
  /// Get cached menu
  static Future<List<dynamic>?> getMenu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_menuKey);
      if (data != null) {
        return jsonDecode(data) as List<dynamic>;
      }
    } catch (e) {
      print('Error getting menu: $e');
    }
    return null;
  }
  
  /// Save orders for offline use
  static Future<void> saveOrders(List<dynamic> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ordersKey, jsonEncode(orders));
      await prefs.setString('$_lastUpdateKey$_ordersKey', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving orders: $e');
    }
  }
  
  /// Get cached orders
  static Future<List<dynamic>?> getOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_ordersKey);
      if (data != null) {
        return jsonDecode(data) as List<dynamic>;
      }
    } catch (e) {
      print('Error getting orders: $e');
    }
    return null;
  }
  
  /// Save hotels for offline use
  static Future<void> saveHotels(List<dynamic> hotels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_hotelsKey, jsonEncode(hotels));
      await prefs.setString('$_lastUpdateKey$_hotelsKey', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving hotels: $e');
    }
  }
  
  /// Get cached hotels
  static Future<List<dynamic>?> getHotels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_hotelsKey);
      if (data != null) {
        return jsonDecode(data) as List<dynamic>;
      }
    } catch (e) {
      print('Error getting hotels: $e');
    }
    return null;
  }
  
  /// Check if cached data is fresh (less than 5 minutes old)
  static Future<bool> isCacheFresh(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString('$_lastUpdateKey$key');
      if (lastUpdate != null) {
        final updateTime = DateTime.parse(lastUpdate);
        final difference = DateTime.now().difference(updateTime);
        return difference.inMinutes < 5;
      }
    } catch (e) {
      print('Error checking cache freshness: $e');
    }
    return false;
  }
  
  /// Clear all cached data
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_menuKey);
      await prefs.remove(_ordersKey);
      await prefs.remove(_hotelsKey);
      await prefs.remove('$_lastUpdateKey$_menuKey');
      await prefs.remove('$_lastUpdateKey$_ordersKey');
      await prefs.remove('$_lastUpdateKey$_hotelsKey');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
  
  /// Generic save method for custom keys
  static Future<void> save(String key, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, data);
      await prefs.setString('$_lastUpdateKey$key', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving data for key $key: $e');
    }
  }
  
  /// Generic get method for custom keys
  static Future<String?> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      print('Error getting data for key $key: $e');
      return null;
    }
  }
}
