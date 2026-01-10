import '../models/review.dart';
import '../services/api_service.dart';

/// Review Repository
class ReviewRepository {
  /// Get reviews for a food item
  Future<List<Review>> getReviewsByFood(String foodId) async {
    final response = await ApiService.get('/reviews?foodId=$foodId');
    final List<dynamic> reviewsJson = response['data'] ?? [];
    return reviewsJson.map((json) => Review.fromJson(json)).toList();
  }

  /// Get reviews for a restaurant
  Future<List<Review>> getReviewsByRestaurant(String restaurantId) async {
    final response =
        await ApiService.get('/reviews?restaurantId=$restaurantId');
    final List<dynamic> reviewsJson = response['data'] ?? [];
    return reviewsJson.map((json) => Review.fromJson(json)).toList();
  }

  /// Create a new review
  Future<Review> createReview({
    required String foodId,
    String? restaurantId,
    String? orderId,
    required int rating,
    required String comment,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{
      'foodId': foodId,
      'rating': rating,
      'comment': comment,
    };
    if (restaurantId != null) body['restaurantId'] = restaurantId;
    if (orderId != null) body['orderId'] = orderId;
    if (images != null && images.isNotEmpty) body['images'] = images;

    final response = await ApiService.post('/reviews', body);
    return Review.fromJson(response['data']);
  }
}
