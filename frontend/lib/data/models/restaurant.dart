class Restaurant {
  final String id;
  final String name;
  final String description;
  final String image;
  final String address;
  final String phone;
  final double rating;
  final int totalRatings;
  final List<String> cuisine;
  final double deliveryFee;
  final double minOrder;
  final bool isActive;
  final bool isFeatured;
  final String openingHours;

  Restaurant({
    required this.id,
    required this.name,
    this.description = '',
    this.image = '',
    required this.address,
    this.phone = '',
    this.rating = 0,
    this.totalRatings = 0,
    this.cuisine = const [],
    this.deliveryFee = 2.99,
    this.minOrder = 10,
    this.isActive = true,
    this.isFeatured = false,
    this.openingHours = '09:00 - 22:00',
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      cuisine: List<String>.from(json['cuisine'] ?? []),
      deliveryFee: (json['deliveryFee'] ?? 2.99).toDouble(),
      minOrder: (json['minOrder'] ?? 10).toDouble(),
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      openingHours:
          '${json['openingHours']?['open'] ?? '09:00'} - ${json['openingHours']?['close'] ?? '22:00'}',
    );
  }
}
