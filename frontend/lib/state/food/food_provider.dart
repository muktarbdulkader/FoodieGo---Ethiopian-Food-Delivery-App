import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/food.dart';
import '../../data/models/user.dart';
import '../../data/models/promotion.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/services/api_service.dart';

/// Food Provider
/// Manages food list state using ChangeNotifier
class FoodProvider extends ChangeNotifier {
  final FoodRepository _foodRepository = FoodRepository();
  static const String _favoritesKey = 'favorite_foods';

  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  List<Hotel> _hotels = [];
  List<Food> _favorites = [];
  List<Promotion> _promotions = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Food> get foods => _foods;
  List<Food> get filteredFoods => _filteredFoods;
  List<Hotel> get hotels => _hotels;
  List<Food> get favorites => _favorites;
  List<Promotion> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if food is favorite
  bool isFavorite(String foodId) => _favoriteIds.contains(foodId);

  /// Load favorites from local storage
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteIds = favoritesJson.toSet();

      // If foods not loaded yet, fetch them first
      if (_foods.isEmpty) {
        _foods = await _foodRepository.getAllFoods();
      }

      // Filter foods that are in favorites
      _favorites = _foods.where((f) => _favoriteIds.contains(f.id)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Food food) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_favoriteIds.contains(food.id)) {
        _favoriteIds.remove(food.id);
        _favorites.removeWhere((f) => f.id == food.id);
      } else {
        _favoriteIds.add(food.id);
        _favorites.add(food);
      }

      await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  /// Fetch all foods from API
  Future<void> fetchFoods() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _foods = await _foodRepository.getAllFoods();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all hotels (admin users with hotel info)
  Future<List<Hotel>> fetchHotels() async {
    try {
      _hotels = await _foodRepository.getAllHotels();
      notifyListeners();
      return _hotels;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Fetch all active promotions
  Future<List<Promotion>> fetchPromotions() async {
    try {
      final response = await ApiService.get('/promotions');
      final List<dynamic> data = response['data'] ?? [];
      _promotions = data.map((json) => Promotion.fromJson(json)).toList();
      // Filter only active promotions
      _promotions = _promotions
          .where((p) => p.isActive && p.endDate.isAfter(DateTime.now()))
          .toList();
      notifyListeners();
      return _promotions;
    } catch (e) {
      debugPrint('Error fetching promotions: $e');
      return [];
    }
  }

  /// Fetch foods by hotel ID
  Future<List<Food>> fetchFoodsByHotel(String hotelId) async {
    try {
      return await _foodRepository.getFoodsByHotel(hotelId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Search foods by name
  void searchFoods(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Apply all filters
  void _applyFilters() {
    _filteredFoods = _foods.where((food) {
      final matchesSearch = _searchQuery.isEmpty ||
          food.name.toLowerCase().contains(_searchQuery) ||
          food.hotelName.toLowerCase().contains(_searchQuery) ||
          food.description.toLowerCase().contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == 'All' || food.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _filteredFoods = List.from(_foods);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
