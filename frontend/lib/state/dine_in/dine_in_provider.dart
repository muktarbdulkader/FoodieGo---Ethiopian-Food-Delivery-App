import 'package:flutter/material.dart';
import '../../data/models/table.dart';
import '../../data/repositories/table_repository.dart';

class DineInProvider extends ChangeNotifier {
  final TableRepository _tableRepository = TableRepository();

  TableModel? _currentTable;
  String? _currentRestaurantId;
  bool _isLoading = false;
  String? _error;

  TableModel? get currentTable => _currentTable;
  String? get currentRestaurantId => _currentRestaurantId;
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
    _error = null;
    notifyListeners();
  }

  Future<void> endSession() async {
    if (_currentTable == null) return;

    try {
      await _tableRepository.endTableSession(_currentTable!.id);
      clearDineInSession();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  String? getTableNumber() {
    return _currentTable?.tableNumber;
  }

  String? getTableLocation() {
    return _currentTable?.location;
  }
}
