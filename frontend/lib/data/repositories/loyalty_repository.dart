import '../models/loyalty_points.dart';
import '../services/api_service.dart';

class LoyaltyRepository {
  /// Get user's loyalty points and stats
  Future<LoyaltyPoints> getLoyaltyPoints() async {
    try {
      final response = await ApiService.get('/loyalty/points');
      if (response['success'] == true) {
        return LoyaltyPoints.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to get loyalty points');
    } catch (e) {
      throw Exception('Failed to get loyalty points: $e');
    }
  }

  /// Get point transaction history
  Future<List<PointTransaction>> getTransactions() async {
    try {
      final response = await ApiService.get('/loyalty/transactions');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((t) => PointTransaction.fromJson(t)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Redeem points for a reward
  Future<Map<String, dynamic>> redeemPoints(
    String redemptionId,
    int pointsCost,
  ) async {
    try {
      final response = await ApiService.post('/loyalty/redeem', {
        'redemptionId': redemptionId,
        'points': pointsCost,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to redeem points: $e');
    }
  }

  /// Apply points discount to order
  Future<Map<String, dynamic>> applyPointsDiscount(
    String orderId,
    int points,
  ) async {
    try {
      final response = await ApiService.post('/loyalty/apply-discount', {
        'orderId': orderId,
        'points': points,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to apply discount: $e');
    }
  }

  /// Calculate points for an order amount
  int calculatePoints(double orderAmount, String tier) {
    double multiplier = 1.0;
    switch (tier) {
      case 'Silver':
        multiplier = 1.5;
        break;
      case 'Gold':
        multiplier = 2.0;
        break;
      case 'Platinum':
        multiplier = 3.0;
        break;
    }
    return (orderAmount / 10 * multiplier).floor();
  }

  /// Get available redemption options
  List<RedemptionOption> getRedemptionOptions() {
    return RedemptionOption.defaultOptions;
  }
}
