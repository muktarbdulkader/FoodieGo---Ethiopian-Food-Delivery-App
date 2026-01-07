import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

/// Order Repository
/// Handles order-related API operations
class OrderRepository {
  /// Get all orders for current user
  Future<List<Order>> getAllOrders() async {
    final response = await ApiService.get(ApiConstants.orders);

    final List<dynamic> ordersJson = response['data'] ?? [];
    return ordersJson.map((json) => Order.fromJson(json)).toList();
  }

  /// Create a new order with payment & delivery
  Future<Order> createOrder({
    required List<CartItem> items,
    required double subtotal,
    double deliveryFee = 2.99,
    double tax = 0,
    double tip = 0,
    double discount = 0,
    required double totalPrice,
    DeliveryAddress? deliveryAddress,
    Payment? payment,
    Delivery? delivery,
    String? notes,
    String? promoCode,
  }) async {
    final response = await ApiService.post(ApiConstants.orders, {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'tip': tip,
      'discount': discount,
      'totalPrice': totalPrice,
      'deliveryAddress': deliveryAddress?.toJson(),
      'payment': payment?.toJson(),
      'delivery': delivery?.toJson(),
      'notes': notes,
      'promoCode': promoCode,
    });

    return Order.fromJson(response['data']);
  }

  /// Get order by ID
  Future<Order> getOrderById(String id) async {
    final response = await ApiService.get('${ApiConstants.orders}/$id');
    return Order.fromJson(response['data']);
  }

  /// Cancel order
  Future<Order> cancelOrder(String id, {String? reason}) async {
    final response = await ApiService.put('${ApiConstants.orders}/$id/cancel', {
      'reason': reason ?? 'Cancelled by user',
    });
    return Order.fromJson(response['data']);
  }
}
