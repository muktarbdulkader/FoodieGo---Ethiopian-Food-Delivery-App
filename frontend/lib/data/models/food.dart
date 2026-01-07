/// Food Model with Hotel Reference
class Food {
  final String id;
  final String name;
  final String description;
  final double price;
  final String hotelId;
  final String hotelName;
  final String image;
  final String category;
  final bool isAvailable;
  final double rating;
  final int totalRatings;
  final int preparationTime;
  final int? calories;
  final bool isVegetarian;
  final bool isSpicy;
  final bool isFeatured;
  final double discount;
  // Hotel info (populated)
  final String? hotelImage;
  final double? hotelRating;
  final String? hotelAddress;
  final bool? hotelIsOpen;
  final double? hotelDeliveryFee;

  Food({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.hotelId,
    required this.hotelName,
    this.image = '',
    this.category = 'General',
    this.isAvailable = true,
    this.rating = 0,
    this.totalRatings = 0,
    this.preparationTime = 20,
    this.calories,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.isFeatured = false,
    this.discount = 0,
    this.hotelImage,
    this.hotelRating,
    this.hotelAddress,
    this.hotelIsOpen,
    this.hotelDeliveryFee,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    // Handle populated hotelId
    String hotelId = '';
    String? hotelImage;
    double? hotelRating;
    String? hotelAddress;
    bool? hotelIsOpen;
    double? hotelDeliveryFee;

    if (json['hotelId'] is Map) {
      final hotel = json['hotelId'] as Map<String, dynamic>;
      hotelId = hotel['_id'] ?? hotel['id'] ?? '';
      hotelImage = hotel['hotelImage'];
      hotelRating = (hotel['hotelRating'] as num?)?.toDouble();
      hotelAddress = hotel['hotelAddress'];
      hotelIsOpen = hotel['isOpen'];
      hotelDeliveryFee = (hotel['deliveryFee'] as num?)?.toDouble();
    } else {
      hotelId = json['hotelId']?.toString() ?? '';
    }

    return Food(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      hotelId: hotelId,
      hotelName: json['hotelName'] ?? json['restaurant'] ?? '',
      image: json['image'] ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      category: json['category'] ?? 'General',
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      preparationTime: json['preparationTime'] ?? 20,
      calories: json['calories'],
      isVegetarian: json['isVegetarian'] ?? false,
      isSpicy: json['isSpicy'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      discount: (json['discount'] ?? 0).toDouble(),
      hotelImage: hotelImage,
      hotelRating: hotelRating,
      hotelAddress: hotelAddress,
      hotelIsOpen: hotelIsOpen,
      hotelDeliveryFee: hotelDeliveryFee,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'isSpicy': isSpicy,
      'isFeatured': isFeatured,
      'discount': discount,
      'preparationTime': preparationTime,
    };
  }

  double get finalPrice => discount > 0 ? price * (1 - discount / 100) : price;

  // For backward compatibility
  String get restaurant => hotelName;
}
