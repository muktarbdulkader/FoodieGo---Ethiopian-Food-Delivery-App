import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/food.dart';
import '../../data/models/user.dart';
import '../../data/models/promotion.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/services/api_service.dart';
import '../../core/utils/offline_storage.dart';

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

  /// Fetch all foods from API with offline caching for instant load
  Future<void> fetchFoods() async {
    _error = null;

    // Try to load from cache first for instant display
    final cachedFoods = await OfflineStorage.getMenu();
    if (cachedFoods != null && cachedFoods.isNotEmpty) {
      _foods = cachedFoods.map((json) => Food.fromJson(json)).toList();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      debugPrint('[FOOD PROVIDER] Loaded ${_foods.length} foods from cache');
    } else {
      _isLoading = true;
      notifyListeners();
    }

    // Then fetch fresh data in background
    try {
      final freshFoods = await _foodRepository.getAllFoods();

      // Only update if we got new data
      if (freshFoods.isNotEmpty) {
        _foods = freshFoods;
        _applyFilters();

        // Save to offline storage
        await OfflineStorage.saveMenu(_foods.map((f) => f.toJson()).toList());
        debugPrint(
            '[FOOD PROVIDER] Loaded ${_foods.length} fresh foods from API');
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[FOOD PROVIDER] Error fetching foods: $e');

      // If we have cached data, don't show error
      if (cachedFoods != null && cachedFoods.isNotEmpty) {
        _error = null;
        debugPrint('[FOOD PROVIDER] Using cached foods due to error');
      } else {
        _error = e.toString().contains('timed out')
            ? 'Server is waking up. Please wait...'
            : e.toString();
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all hotels (admin users with hotel info)
  /// Optionally pass user location to get nearby restaurants sorted by distance
  Future<List<Hotel>> fetchHotels({double? lat, double? lng}) async {
    // Try to load from cache first for instant display
    final cachedHotels = await OfflineStorage.getHotels();
    if (cachedHotels != null && cachedHotels.isNotEmpty) {
      _hotels = cachedHotels.map((json) => Hotel.fromJson(json)).toList();
      _isLoading = false;
      _error = null;
      notifyListeners();
      debugPrint('[FOOD PROVIDER] Loaded ${_hotels.length} hotels from cache');
    } else {
      _isLoading = true;
      notifyListeners();
    }

    // Then fetch fresh data in background
    try {
      final freshHotels =
          await _foodRepository.getAllHotels(lat: lat, lng: lng);

      // Only update if we got new data
      if (freshHotels.isNotEmpty) {
        _hotels = freshHotels;

        // Save to offline storage
        await OfflineStorage.saveHotels(
            _hotels.map((h) => h.toJson()).toList());

        debugPrint(
            '[FOOD PROVIDER] Loaded ${_hotels.length} fresh hotels from API');
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
      return _hotels;
    } catch (e) {
      debugPrint('[FOOD PROVIDER] Error fetching hotels: $e');

      // If we have cached data, don't show error
      if (cachedHotels != null && cachedHotels.isNotEmpty) {
        _error = null;
        debugPrint('[FOOD PROVIDER] Using cached hotels due to error');
        _isLoading = false;
        notifyListeners();
        return _hotels;
      } else {
        _error = e.toString().contains('timed out')
            ? 'Server is waking up. Please wait...'
            : e.toString();
        _isLoading = false;
        notifyListeners();
        return [];
      }
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

  /// Fetch foods by hotel ID with optional menu type filter
  Future<List<Food>> fetchFoodsByHotel(String hotelId,
      {String? menuType}) async {
    // Try to load from cache first for instant display
    final cachedFoods = await OfflineStorage.getMenu();
    if (cachedFoods != null && cachedFoods.isNotEmpty) {
      final List<Food> tempFoods =
          cachedFoods.map((json) => Food.fromJson(json)).toList();

      // Only use cache if it belongs to the same hotel
      if (tempFoods.isNotEmpty && tempFoods.first.hotelId == hotelId) {
        _foods = tempFoods;
        _applyFilters();
        _isLoading = false;
        _error = null;
        notifyListeners();
        debugPrint('[FOOD PROVIDER] Loaded ${_foods.length} foods from cache');
      } else {
        // Different hotel or empty cache, clear current foods and show loading
        _foods = [];
        _isLoading = true;
        notifyListeners();
        debugPrint('[FOOD PROVIDER] Cache is for different hotel, loading fresh');
      }
    } else {
      _foods = [];
      _isLoading = true;
      notifyListeners();
    }

    // Then fetch fresh data in background
    try {
      final freshFoods =
          await _foodRepository.getFoodsByHotel(hotelId, menuType: menuType);

      // Only update if we got new data
      if (freshFoods.isNotEmpty) {
        _foods = freshFoods;

        // Save to offline storage
        await OfflineStorage.saveMenu(_foods.map((f) => f.toJson()).toList());

        _applyFilters();
        _error = null;
        debugPrint(
            '[FOOD PROVIDER] Loaded ${_foods.length} fresh foods from API');
      }

      _isLoading = false;
      notifyListeners();
      return _foods;
    } catch (e) {
      debugPrint('[FOOD PROVIDER] Error fetching foods: $e');

      // If we have cached data, just show a subtle message
      if (cachedFoods != null && cachedFoods.isNotEmpty) {
        _error = null; // Don't show error if we have cached data
        debugPrint('[FOOD PROVIDER] Using cached data due to error');
      } else {
        _error = e.toString().contains('timed out')
            ? 'Server is waking up. Please wait...'
            : e.toString();
      }

      _isLoading = false;
      notifyListeners();
      return _foods;
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
