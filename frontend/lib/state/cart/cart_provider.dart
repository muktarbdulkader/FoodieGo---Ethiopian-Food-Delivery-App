import 'package:flutter/foundation.dart';
import '../../data/models/food.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

/// Cart Provider
/// Manages shopping cart state using ChangeNotifier
class CartProvider extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();

  final List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Calculate total price
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.total);

  /// Add food to cart
  void addToCart(Food food) {
    final existingIndex = _items.indexWhere((item) => item.foodId == food.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem.fromFood(food));
    }
    notifyListeners();
  }

  /// Remove item from cart
  void removeFromCart(String foodId) {
    _items.removeWhere((item) => item.foodId == foodId);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(String foodId, int quantity) {
    final index = _items.indexWhere((item) => item.foodId == foodId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  /// Clear cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Place order (simple)
  Future<Order?> placeOrder() async {
    if (_items.isEmpty) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _orderRepository.createOrder(
        items: _items,
        subtotal: totalPrice,
        totalPrice: totalPrice + 2.99,
      );
      _items.clear();
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Place order with full details (payment, delivery, address)
  Future<Order?> placeOrderWithDetails({
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required double tip,
    required double totalPrice,
    DeliveryAddress? deliveryAddress,
    Payment? payment,
    Delivery? delivery,
  }) async {
    if (_items.isEmpty) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _orderRepository.createOrder(
        items: _items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        tax: tax,
        tip: tip,
        totalPrice: totalPrice,
        deliveryAddress: deliveryAddress,
        payment: payment,
        delivery: delivery,
      );
      _items.clear();
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
