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

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all orders for current user
  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderRepository.getAllOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
