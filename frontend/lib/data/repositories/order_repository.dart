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

  /// Delete order (user can delete delivered/cancelled orders)
  Future<void> deleteOrder(String id) async {
    await ApiService.delete('${ApiConstants.orders}/$id');
  }

  /// Get available delivery orders (for delivery persons)
  Future<List<Order>> getAvailableDeliveryOrders() async {
    final response =
        await ApiService.get('${ApiConstants.orders}/delivery/available');
    final List<dynamic> ordersJson = response['data'] ?? [];
    return ordersJson.map((json) => Order.fromJson(json)).toList();
  }

  /// Accept delivery order (delivery person claims the order)
  Future<Order> acceptDeliveryOrder(String id) async {
    final response =
        await ApiService.put('${ApiConstants.orders}/delivery/accept/$id', {});
    return Order.fromJson(response['data']);
  }

  /// Get pending delivery orders (for restaurant)
  Future<List<Order>> getPendingDeliveryOrders() async {
    final response = await ApiService.get(
        '${ApiConstants.orders}/restaurant/pending-delivery');
    final List<dynamic> ordersJson = response['data'] ?? [];
    return ordersJson.map((json) => Order.fromJson(json)).toList();
  }

  /// Update order status (restaurant)
  Future<Order> updateOrderStatus(String id, String status) async {
    final response = await ApiService.put(
        '${ApiConstants.orders}/$id/status', {'status': status});
    return Order.fromJson(response['data']);
  }

  /// Assign driver to order (restaurant)
  Future<Order> assignDriver(
      String id, String driverName, String driverPhone) async {
    final response =
        await ApiService.put('${ApiConstants.orders}/$id/delivery', {
      'driverName': driverName,
      'driverPhone': driverPhone,
      'trackingStatus': 'assigned',
    });
    return Order.fromJson(response['data']);
  }

  /// Update delivery status (delivery person)
  Future<Order> updateDeliveryStatus(String id, String trackingStatus) async {
    final response =
        await ApiService.put('${ApiConstants.orders}/$id/delivery', {
      'trackingStatus': trackingStatus,
    });
    return Order.fromJson(response['data']);
  }
}
