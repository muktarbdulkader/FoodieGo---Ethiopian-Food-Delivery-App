class Promotion {
  final String id;
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  // Hotel info
  final String? hotelId;
  final String? hotelName;
  // Promo type/purpose
  final String promoType;

  Promotion({
    required this.id,
    required this.code,
    required this.description,
    this.discountType = 'percentage',
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.hotelId,
    this.hotelName,
    this.promoType = 'food_discount',
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      maxDiscount: json['maxDiscount']?.toDouble(),
      startDate:
          DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate:
          DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      hotelId: json['hotelId'],
      hotelName: json['hotelName'],
      promoType: json['promoType'] ?? 'food_discount',
    );
  }

  String get discountText {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}% OFF';
    }
    return 'ETB ${discountValue.toStringAsFixed(0)} OFF';
  }

  String get promoTypeLabel {
    switch (promoType) {
      case 'food_discount':
        return '🍔 Food Discount';
      case 'delivery_free':
        return '🚚 Free Delivery';
      case 'event_discount':
        return '🎉 Event Discount';
      case 'new_user':
        return '🆕 New User';
      case 'special_offer':
        return '⭐ Special Offer';
      default:
        return '🎁 Promotion';
    }
  }

  String get promoTypeIcon {
    switch (promoType) {
      case 'food_discount':
        return '🍔';
      case 'delivery_free':
        return '🚚';
      case 'event_discount':
        return '🎉';
      case 'new_user':
        return '🆕';
      case 'special_offer':
        return '⭐';
      default:
        return '🎁';
    }
  }
}
