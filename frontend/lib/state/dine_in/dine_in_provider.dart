import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/table.dart';
import '../../data/repositories/table_repository.dart';

class DineInProvider extends ChangeNotifier {
  final TableRepository _tableRepository = TableRepository();
  final Uuid _uuid = const Uuid();

  TableModel? _currentTable;
  String? _currentRestaurantId;
  String? _guestSessionId; // Unique ID for each guest
  bool _isLoading = false;
  String? _error;

  TableModel? get currentTable => _currentTable;
  String? get currentRestaurantId => _currentRestaurantId;
  String? get guestSessionId => _guestSessionId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDineInMode => _currentTable != null;

  Future<void> loadTableData(String restaurantId, String tableId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentTable = await _tableRepository.getTableByQRCode(restaurantId, tableId);
      _currentRestaurantId = restaurantId;
      
      // Generate or retrieve guest session ID
      await _initializeGuestSession(tableId);
      
      // Try to start table session if user is logged in
      // If not logged in, skip session start (user can still view menu)
      try {
        await _tableRepository.startTableSession(tableId);
      } catch (e) {
        debugPrint('Could not start table session (user may not be logged in): $e');
        // Continue anyway - user can view menu without session
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _initializeGuestSession(String tableId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = 'guest_session_$tableId';
    
    // Check if there's an existing session for this table
    String? existingSession = prefs.getString(sessionKey);
    
    if (existingSession != null) {
      // Check if session is still valid (less than 4 hours old)
      final sessionTimestampKey = 'guest_session_timestamp_$tableId';
      final timestamp = prefs.getInt(sessionTimestampKey);
      
      if (timestamp != null) {
        final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(sessionTime);
        
        // If session is less than 4 hours old, reuse it
        if (difference.inHours < 4) {
          _guestSessionId = existingSession;
          debugPrint('[DINE-IN] Reusing existing guest session: $_guestSessionId');
          return;
        }
      }
    }
    
    // Generate new session ID
    _guestSessionId = _uuid.v4();
    await prefs.setString(sessionKey, _guestSessionId!);
    await prefs.setInt('guest_session_timestamp_$tableId', DateTime.now().millisecondsSinceEpoch);
    
    debugPrint('[DINE-IN] Created new guest session: $_guestSessionId');
  }

  Future<void> callWaiter(String message) async {
    if (_currentTable == null) {
      throw Exception('No active table session');
    }

    try {
      await _tableRepository.callWaiter(_currentTable!.id, message);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearDineInSession() {
    _currentTable = null;
    _currentRestaurantId = null;
    _guestSessionId = null;
    _error = null;
    notifyListeners();
  }

  Future<void> endSession() async {
    if (_currentTable == null) return;

    try {
      await _tableRepository.endTableSession(_currentTable!.id);
      
      // Clear guest session from storage
      await clearGuestSession(_currentTable!.id);
      
      clearDineInSession();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearGuestSession(String tableId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_session_$tableId');
    await prefs.remove('guest_session_timestamp_$tableId');
    _guestSessionId = null;
    notifyListeners();
    debugPrint('[DINE-IN] Guest session cleared for table $tableId');
  }

  String? getTableNumber() {
    return _currentTable?.tableNumber;
  }

  String? getTableLocation() {
    return _currentTable?.location;
  }
}
