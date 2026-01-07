/// User Model - Extended for Hotel Management with Location
class UserLocation {
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;

  UserLocation({this.latitude, this.longitude, this.address, this.city});

  factory UserLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserLocation();
    return UserLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
      };
}

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final UserLocation? location;
  // Hotel fields (for admin)
  final String? hotelName;
  final String? hotelAddress;
  final String? hotelPhone;
  final String? hotelDescription;
  final String? hotelImage;
  final String? hotelCategory;
  final double? hotelRating;
  final bool? isOpen;
  final double? deliveryFee;
  final double? minOrderAmount;
  final double? deliveryRadius;
  // Status
  final bool isActive;
  final bool isVerified;
  final int totalOrders;
  final double totalSpent;
  final double totalRevenue;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.location,
    this.hotelName,
    this.hotelAddress,
    this.hotelPhone,
    this.hotelDescription,
    this.hotelImage,
    this.hotelCategory,
    this.hotelRating,
    this.isOpen,
    this.deliveryFee,
    this.minOrderAmount,
    this.deliveryRadius,
    this.isActive = true,
    this.isVerified = false,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.totalRevenue = 0,
    this.lastLogin,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      phone: json['phone'],
      address: json['address'],
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'])
          : null,
      hotelName: json['hotelName'],
      hotelAddress: json['hotelAddress'],
      hotelPhone: json['hotelPhone'],
      hotelDescription: json['hotelDescription'],
      hotelImage: json['hotelImage'],
      hotelCategory: json['hotelCategory'],
      hotelRating: (json['hotelRating'] as num?)?.toDouble(),
      isOpen: json['isOpen'],
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(),
      deliveryRadius: (json['deliveryRadius'] as num?)?.toDouble(),
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      totalOrders: json['totalOrders'] ?? json['orderCount'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'address': address,
      'location': location?.toJson(),
      'hotelName': hotelName,
      'hotelAddress': hotelAddress,
      'hotelPhone': hotelPhone,
      'hotelDescription': hotelDescription,
      'hotelCategory': hotelCategory,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}

/// Hotel model for listing hotels to users
class Hotel {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? description;
  final String? image;
  final String? category;
  final double rating;
  final bool isOpen;
  final double deliveryFee;
  final double minOrderAmount;
  final int foodCount;

  Hotel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.description,
    this.image,
    this.category,
    this.rating = 4.5,
    this.isOpen = true,
    this.deliveryFee = 50,
    this.minOrderAmount = 0,
    this.foodCount = 0,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['hotelName'] ?? json['name'] ?? '',
      address: json['hotelAddress'] ?? json['address'],
      phone: json['hotelPhone'] ?? json['phone'],
      description: json['hotelDescription'] ?? json['description'],
      image: json['hotelImage'] ?? json['image'],
      category: json['hotelCategory'] ?? json['category'],
      rating: (json['hotelRating'] ?? json['rating'] ?? 4.5).toDouble(),
      isOpen: json['isOpen'] ?? true,
      deliveryFee: (json['deliveryFee'] ?? 50).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      foodCount: json['foodCount'] ?? 0,
    );
  }
}
