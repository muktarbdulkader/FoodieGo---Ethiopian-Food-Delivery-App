import 'package:flutter/foundation.dart';
import '../../data/models/food.dart';
import '../../data/models/user.dart';
import '../../data/repositories/food_repository.dart';

/// Food Provider
/// Manages food list state using ChangeNotifier
class FoodProvider extends ChangeNotifier {
  final FoodRepository _foodRepository = FoodRepository();

  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  List<Hotel> _hotels = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Food> get foods => _foods;
  List<Food> get filteredFoods => _filteredFoods;
  List<Hotel> get hotels => _hotels;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
