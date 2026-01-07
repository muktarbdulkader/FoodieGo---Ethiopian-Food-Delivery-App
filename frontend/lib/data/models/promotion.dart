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
    );
  }

  String get discountText {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}% OFF';
    }
    return '\$${discountValue.toStringAsFixed(2)} OFF';
  }
}
