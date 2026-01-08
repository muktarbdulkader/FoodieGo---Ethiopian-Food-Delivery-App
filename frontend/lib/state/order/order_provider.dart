import 'package:flutter/foundation.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

/// Order Provider
/// Manages order history state using ChangeNotifier
class OrderProvider extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all orders for current user
  Future<void> fetchOrders({bool silent = false}) async {
    // Prevent notifyListeners during build by using silent mode
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      _isLoading = true;
      _error = null;
    }

    try {
      _orders = await _orderRepository.getAllOrders();
      _isLoading = false;
      _hasFetched = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _hasFetched = true;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state (for logout)
  void reset() {
    _orders = [];
    _isLoading = false;
    _error = null;
    _hasFetched = false;
  }
}
