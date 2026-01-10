import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/food.dart';
import '../../../data/models/user.dart';
import '../../../data/services/api_service.dart';
import '../../../state/food/food_provider.dart';
import '../../../state/cart/cart_provider.dart';
import '../food/food_detail_page.dart';
import '../home/hotel_foods_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Hotel> _favoriteHotels = [];
  bool _loadingHotels = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().loadFavorites();
      _loadFavoriteHotels();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteHotels() async {
    setState(() => _loadingHotels = true);
    try {
      final response = await ApiService.get('/auth/favorites/hotels');
      final List<dynamic> data = response['data'] ?? [];
      if (mounted) {
        setState(() {
          _favoriteHotels = data.map((h) => Hotel.fromJson(h)).toList();
          _loadingHotels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingHotels = false);
      }
    }
  }

  Future<void> _removeFavoriteHotel(Hotel hotel) async {
    try {
      await ApiService.post('/auth/favorites/hotels', {'hotelId': hotel.id});
      if (mounted) {
        setState(() {
          _favoriteHotels.removeWhere((h) => h.id == hotel.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppTheme.textSecondary,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.fastfood, size: 18), text: 'Foods'),
            Tab(icon: Icon(Icons.store, size: 18), text: 'Hotels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFoodFavorites(),
          _buildHotelFavorites(),
        ],
      ),
    );
  }

  Widget _buildFoodFavorites() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, _) {
        if (foodProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = foodProvider.favorites;

        if (favorites.isEmpty) {
          return _buildEmptyState('No favorite foods yet', Icons.fastfood);
        }

        return RefreshIndicator(
          onRefresh: () => context.read<FoodProvider>().loadFavorites(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) => _buildFoodCard(favorites[index]),
          ),
        );
      },
    );
  }

  Widget _buildHotelFavorites() {
    if (_loadingHotels) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteHotels.isEmpty) {
      return _buildEmptyState('No favorite hotels yet', Icons.store);
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteHotels,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteHotels.length,
        itemBuilder: (context, index) =>
            _buildHotelCard(_favoriteHotels[index]),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.red.shade300),
          ),
          const SizedBox(height: 16),
          Text(message,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Start adding your favorites!',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Food food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodDetailPage(food: food)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: food.image.isNotEmpty
                    ? Image.network(food.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholder(Icons.fastfood))
                    : _buildPlaceholder(Icons.fastfood),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(food.hotelName,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                        '${AppConstants.currency}${food.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        context.read<FoodProvider>().toggleFavorite(food),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.red, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      context.read<CartProvider>().addToCart(food);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${food.name} added to cart'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_shopping_cart,
                          color: AppTheme.primaryColor, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HotelFoodsPage(hotel: hotel)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (hotel.image != null && hotel.image!.isNotEmpty)
                    ? Image.network(hotel.image!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholder(Icons.store))
                    : _buildPlaceholder(Icons.store),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFBBF24), size: 14),
                        const SizedBox(width: 2),
                        Text(hotel.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hotel.isOpen
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hotel.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: hotel.isOpen
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hotel.address != null) ...[
                      const SizedBox(height: 4),
                      Text(hotel.address!,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _removeFavoriteHotel(hotel),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.grey),
    );
  }
}
