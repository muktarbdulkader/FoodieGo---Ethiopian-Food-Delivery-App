import '../models/food.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';

/// Food Repository
/// Handles food-related API operations
class FoodRepository {
  /// Get all available foods
  Future<List<Food>> getAllFoods() async {
    final response = await ApiService.get(ApiConstants.foods);
    final List<dynamic> foodsJson = response['data'] ?? [];
    return foodsJson.map((json) => Food.fromJson(json)).toList();
  }

  /// Get food by ID
  Future<Food> getFoodById(String id) async {
    final response = await ApiService.get('${ApiConstants.foods}/$id');
    return Food.fromJson(response['data']);
  }

  /// Get all hotels (admin users with hotel info)
  Future<List<Hotel>> getAllHotels({double? lat, double? lng}) async {
    String url = '${ApiConstants.foods}/hotels';
    if (lat != null && lng != null) {
      url += '?lat=$lat&lng=$lng';
    }
    final response = await ApiService.get(url);
    final List<dynamic> hotelsJson = response['data'] ?? [];
    return hotelsJson.map((json) => Hotel.fromJson(json)).toList();
  }

  /// Get foods by hotel ID
  Future<List<Food>> getFoodsByHotel(String hotelId) async {
    final response =
        await ApiService.get('${ApiConstants.foods}/hotels/$hotelId/foods');
    final List<dynamic> foodsJson = response['data'] ?? [];
    return foodsJson.map((json) => Food.fromJson(json)).toList();
  }

  /// Get food categories
  Future<List<String>> getCategories() async {
    final response = await ApiService.get('${ApiConstants.foods}/categories');
    final List<dynamic> categoriesJson = response['data'] ?? [];
    return categoriesJson.map((c) => c.toString()).toList();
  }

  /// Toggle like on food
  Future<Map<String, dynamic>> toggleLike(String foodId) async {
    final response =
        await ApiService.post('${ApiConstants.foods}/$foodId/like', {});
    return response['data'];
  }

  /// Increment view count
  Future<void> incrementView(String foodId) async {
    await ApiService.post('${ApiConstants.foods}/$foodId/view', {});
  }

  /// Get popular foods
  Future<List<Food>> getPopularFoods({int limit = 10}) async {
    final response =
        await ApiService.get('${ApiConstants.foods}/popular?limit=$limit');
    final List<dynamic> foodsJson = response['data'] ?? [];
    return foodsJson.map((json) => Food.fromJson(json)).toList();
  }

  /// Get admin's custom categories
  Future<List<String>> getAdminCategories() async {
    final response =
        await ApiService.get('${ApiConstants.foods}/admin/categories');
    final List<dynamic> categoriesJson = response['data'] ?? [];
    return categoriesJson.map((c) => c.toString()).toList();
  }
}
