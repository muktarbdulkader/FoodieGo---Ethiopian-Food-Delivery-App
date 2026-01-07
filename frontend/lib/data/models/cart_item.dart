import 'food.dart';

/// Cart Item Model
/// Represents a food item in the shopping cart with quantity and hotel info
class CartItem {
  final String foodId;
  final String name;
  final double price;
  final String hotelId;
  final String hotelName;
  final String image;
  int quantity;

  CartItem({
    required this.foodId,
    required this.name,
    required this.price,
    required this.hotelId,
    required this.hotelName,
    required this.image,
    this.quantity = 1,
  });

  /// Create CartItem from Food
  factory CartItem.fromFood(Food food) {
    return CartItem(
      foodId: food.id,
      name: food.name,
      price: food.finalPrice,
      hotelId: food.hotelId,
      hotelName: food.hotelName,
      image: food.image,
      quantity: 1,
    );
  }

  /// Create CartItem from JSON map
  factory CartItem.fromJson(Map<String, dynamic> json) {
    String foodId = '';
    if (json['food'] is Map) {
      foodId = json['food']['_id'] ?? json['food']['id'] ?? '';
    } else {
      foodId = json['food']?.toString() ?? json['foodId']?.toString() ?? '';
    }

    return CartItem(
      foodId: foodId,
      name: json['name']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      hotelId: json['hotelId']?.toString() ?? '',
      hotelName: json['hotelName']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  /// Convert CartItem to JSON map
  Map<String, dynamic> toJson() {
    return {
      'food': foodId,
      'name': name,
      'price': price,
      'hotelId': hotelId,
      'hotelName': hotelName,
      'image': image,
      'quantity': quantity,
    };
  }

  /// Calculate total price for this item
  double get total => price * quantity;
}
