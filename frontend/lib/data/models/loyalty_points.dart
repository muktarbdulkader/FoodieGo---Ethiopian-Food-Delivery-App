/// Loyalty Points Model - Track user reward points
class LoyaltyPoints {
  final String userId;
  final int totalPoints;
  final int availablePoints;
  final int lifetimePoints;
  final String tier;
  final double pointsValue;
  final List<PointTransaction> transactions;
  final List<TierBenefit> tierBenefits;

  LoyaltyPoints({
    required this.userId,
    this.totalPoints = 0,
    this.availablePoints = 0,
    this.lifetimePoints = 0,
    this.tier = 'Bronze',
    this.pointsValue = 0.0,
    this.transactions = const [],
    this.tierBenefits = const [],
  });

  factory LoyaltyPoints.fromJson(Map<String, dynamic> json) {
    return LoyaltyPoints(
      userId: json['user']?.toString() ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      availablePoints: json['availablePoints'] ?? 0,
      lifetimePoints: json['lifetimePoints'] ?? 0,
      tier: json['tier'] ?? 'Bronze',
      pointsValue: (json['pointsValue'] ?? 0).toDouble(),
      transactions: (json['transactions'] as List?)
              ?.map((t) => PointTransaction.fromJson(t))
              .toList() ??
          [],
      tierBenefits: (json['tierBenefits'] as List?)
              ?.map((b) => TierBenefit.fromJson(b))
              .toList() ??
          _defaultTierBenefits,
    );
  }

  static List<TierBenefit> get _defaultTierBenefits => [
        TierBenefit(
          name: 'Bronze',
          minPoints: 0,
          discount: 0,
          color: 0xFFCD7F32,
          benefits: ['Earn 1 point per 10 ETB spent'],
        ),
        TierBenefit(
          name: 'Silver',
          minPoints: 500,
          discount: 5,
          color: 0xFFC0C0C0,
          benefits: ['5% discount', 'Earn 1.5x points', 'Priority support'],
        ),
        TierBenefit(
          name: 'Gold',
          minPoints: 1500,
          discount: 10,
          color: 0xFFFFD700,
          benefits: ['10% discount', 'Earn 2x points', 'Free delivery', 'Priority support'],
        ),
        TierBenefit(
          name: 'Platinum',
          minPoints: 5000,
          discount: 15,
          color: 0xFFE5E4E2,
          benefits: ['15% discount', 'Earn 3x points', 'Free delivery', 'Exclusive offers', 'VIP support'],
        ),
      ];
}

/// Point Transaction History
class PointTransaction {
  final String id;
  final int points;
  final String type; // 'earned', 'redeemed', 'bonus'
  final String description;
  final String? orderId;
  final DateTime createdAt;

  PointTransaction({
    required this.id,
    required this.points,
    required this.type,
    required this.description,
    this.orderId,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['_id'] ?? '',
      points: json['points'] ?? 0,
      type: json['type'] ?? 'earned',
      description: json['description'] ?? '',
      orderId: json['order']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Tier Benefits
class TierBenefit {
  final String name;
  final int minPoints;
  final int discount;
  final int color;
  final List<String> benefits;

  TierBenefit({
    required this.name,
    required this.minPoints,
    required this.discount,
    required this.color,
    required this.benefits,
  });

  factory TierBenefit.fromJson(Map<String, dynamic> json) {
    return TierBenefit(
      name: json['name'] ?? '',
      minPoints: json['minPoints'] ?? 0,
      discount: json['discount'] ?? 0,
      color: json['color'] ?? 0xFFCD7F32,
      benefits: List<String>.from(json['benefits'] ?? []),
    );
  }
}

/// Redemption Option
class RedemptionOption {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final double value;
  final String type; // 'discount', 'free_delivery', 'free_item'
  final String? icon;

  RedemptionOption({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.value,
    required this.type,
    this.icon,
  });

  static List<RedemptionOption> get defaultOptions => [
        RedemptionOption(
          id: 'discount_50',
          name: '50 ETB Off',
          description: 'Get 50 ETB discount on your next order',
          pointsCost: 500,
          value: 50,
          type: 'discount',
          icon: 'discount',
        ),
        RedemptionOption(
          id: 'discount_100',
          name: '100 ETB Off',
          description: 'Get 100 ETB discount on your next order',
          pointsCost: 900,
          value: 100,
          type: 'discount',
          icon: 'discount',
        ),
        RedemptionOption(
          id: 'free_delivery',
          name: 'Free Delivery',
          description: 'Free delivery on your next 3 orders',
          pointsCost: 300,
          value: 0,
          type: 'free_delivery',
          icon: 'delivery',
        ),
        RedemptionOption(
          id: 'bonus_200',
          name: '200 Bonus Points',
          description: 'Get 200 bonus loyalty points',
          pointsCost: 0,
          value: 200,
          type: 'bonus',
          icon: 'stars',
        ),
      ];
}
