/// Referral Model - Track user referrals
class Referral {
  final String id;
  final String referrerId;
  final String? referredUserId;
  final String referralCode;
  final String? referredUserName;
  final bool isSuccessful;
  final double rewardAmount;
  final DateTime createdAt;
  final DateTime? completedAt;

  Referral({
    required this.id,
    required this.referrerId,
    this.referredUserId,
    required this.referralCode,
    this.referredUserName,
    this.isSuccessful = false,
    this.rewardAmount = 0.0,
    required this.createdAt,
    this.completedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['_id'] ?? '',
      referrerId: json['referrer']?.toString() ?? '',
      referredUserId: json['referredUser']?['_id']?.toString(),
      referralCode: json['referralCode'] ?? '',
      referredUserName: json['referredUser']?['name'],
      isSuccessful: json['isSuccessful'] ?? false,
      rewardAmount: (json['rewardAmount'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
    );
  }
}

/// User Referral Stats
class ReferralStats {
  final String referralCode;
  final int totalReferrals;
  final int successfulReferrals;
  final double totalRewards;
  final double pendingRewards;
  final List<Referral> recentReferrals;

  ReferralStats({
    required this.referralCode,
    this.totalReferrals = 0,
    this.successfulReferrals = 0,
    this.totalRewards = 0.0,
    this.pendingRewards = 0.0,
    this.recentReferrals = const [],
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referralCode'] ?? '',
      totalReferrals: json['totalReferrals'] ?? 0,
      successfulReferrals: json['successfulReferrals'] ?? 0,
      totalRewards: (json['totalRewards'] ?? 0).toDouble(),
      pendingRewards: (json['pendingRewards'] ?? 0).toDouble(),
      recentReferrals: (json['recentReferrals'] as List?)
              ?.map((r) => Referral.fromJson(r))
              .toList() ??
          [],
    );
  }
}
