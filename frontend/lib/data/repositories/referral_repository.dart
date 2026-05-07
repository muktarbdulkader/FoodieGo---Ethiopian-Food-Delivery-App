import '../models/referral.dart';
import '../services/api_service.dart';

class ReferralRepository {
  /// Get user's referral stats and code
  Future<ReferralStats> getReferralStats() async {
    try {
      final response = await ApiService.get('/referrals/stats');
      if (response['success'] == true) {
        return ReferralStats.fromJson(response['data']);
      }
      throw Exception(response['message'] ?? 'Failed to get referral stats');
    } catch (e) {
      throw Exception('Failed to get referral stats: $e');
    }
  }

  /// Get all referrals made by user
  Future<List<Referral>> getMyReferrals() async {
    try {
      final response = await ApiService.get('/referrals/my-referrals');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((r) => Referral.fromJson(r)).toList();
      }
      throw Exception(response['message'] ?? 'Failed to get referrals');
    } catch (e) {
      throw Exception('Failed to get referrals: $e');
    }
  }

  /// Apply referral code during registration
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final response = await ApiService.post('/referrals/apply', {
        'referralCode': code,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to apply referral code: $e');
    }
  }

  /// Get referral leaderboard (top referrers)
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await ApiService.get('/referrals/leaderboard');
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Claim referral rewards
  Future<bool> claimRewards() async {
    try {
      final response = await ApiService.post('/referrals/claim', {});
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
