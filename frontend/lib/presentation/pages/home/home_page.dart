import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../state/food/food_provider.dart';
import '../../../state/cart/cart_provider.dart';
import '../../../data/models/user.dart';
import '../../../data/models/food.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/error_recovery_widget.dart';
import '../cart/cart_page.dart';
import '../orders/orders_page.dart';
import '../profile/profile_page.dart';
import '../food/food_detail_page.dart';
import '../location/location_picker_page.dart';
import '../events/event_booking_page.dart';
import 'hotel_foods_page.dart';
import '../promotions/promotions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  List<Hotel> _hotels = [];
  bool _isLoadingHotels = true;
  String? _errorMessage;
  bool _isNetworkError = false;
  final PageController _bannerController = PageController();
  List<String> _categories = ['All'];

  final List<Map<String, dynamic>> _topServices = [
    {'emoji': '🍔', 'color': const Color(0xFFFFEBEE), 'label': 'Food'},
    {'emoji': '🍕', 'color': const Color(0xFFFFF3E0), 'label': 'Pizza'},
    {'emoji': '🎉', 'color': const Color(0xFFE8F5E9), 'label': 'Events'},
    {'emoji': '🎂', 'color': const Color(0xFFFCE4EC), 'label': 'Birthday'},
    {'emoji': '💒', 'color': const Color(0xFFE3F2FD), 'label': 'Wedding'},
  ];

  // Category emoji mapping
  final Map<String, String> _categoryEmojis = {
    'All': '🍽️',
    'General': '🍴',
    'Bakery': '🥐',
    'Pasta': '🍝',
    'Pizza': '🍕',
    'Indian': '🍛',
    'Drinks': '🥤',
    'Burger': '🍔',
    'Dessert': '🍰',
    'Fast Food': '🍟',
    'Salad': '🥗',
    'Seafood': '🦐',
    'Soup': '🍲',
    'Breakfast': '🥞',
    'Coffee': '☕',
    'Sandwich': '🥪',
    'Chicken': '🍗',
    'Rice': '🍚',
    'Noodles': '🍜',
    'Steak': '🥩',
    'Vegetarian': '🥬',
    'Mexican': '🌮',
    'Chinese': '🥡',
    'Japanese': '🍱',
    'Thai': '🍜',
    'Italian': '🍝',
    'Ethiopian': '🍲',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _isNetworkError = false;
    });
    try {
      final foodProvider = context.read<FoodProvider>();
      await foodProvider.fetchFoods();
      await foodProvider.fetchPromotions(); // Load promotions
      if (!mounted) return;
      // Extract unique categories from foods
      final foods = foodProvider.foods;
      final uniqueCategories = foods.map((f) => f.category).toSet().toList();
      uniqueCategories.sort();
      setState(() {
        _categories = ['All', ...uniqueCategories];
      });
      await _loadHotels();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isNetworkError = e.isNetworkError;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data';
          _isNetworkError = false;
        });
      }
    }
  }

  Future<void> _loadHotels() async {
    if (!mounted) return;
    setState(() => _isLoadingHotels = true);
    try {
      // Get user location if available
      final authProvider = context.read<AuthProvider>();
      final userLocation = authProvider.user?.location;

      final hotels = await context.read<FoodProvider>().fetchHotels(
            lat: userLocation?.latitude,
            lng: userLocation?.longitude,
          );
      if (mounted) {
        setState(() {
          _hotels = hotels;
          _isLoadingHotels = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHotels = false);
    }
  }

  void _addToCart(Food food) {
    context.read<CartProvider>().addToCart(food);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} added to cart'),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onServiceTap(String label) {
    if (label == 'Events' || label == 'Birthday' || label == 'Wedding') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EventBookingPage()),
      );
    } else if (label == 'Food' || label == 'Pizza') {
      // Filter by category
      final category = label == 'Pizza' ? 'Pizza' : 'All';
      setState(() => _selectedCategory = category);
      context.read<FoodProvider>().filterByCategory(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          _buildRestaurantsTab(),
          const OrdersPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<FoodProvider>(
      builder: (context, foodProvider, _) {
        if (_errorMessage != null && _isNetworkError) {
          return ErrorRecoveryWidget(
              message: _errorMessage!, onRetry: _loadData);
        }
        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 12),
                _buildTopServices(),
                const SizedBox(height: 16),
                _buildLocationBar(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildCategories(),
                const SizedBox(height: 20),
                _buildPromoBanner(),
                // Show promotions if available
                if (foodProvider.promotions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildPromotionsSection(foodProvider),
                ],
                const SizedBox(height: 24),
                _buildOffersSection(foodProvider),
                const SizedBox(height: 24),
                _buildRestaurantsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topServices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final service = _topServices[index];
                  return GestureDetector(
                    onTap: () => _onServiceTap(service['label']),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: service['color'],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                          child: Text(service['emoji'],
                              style: const TextStyle(fontSize: 28))),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartPage())),
            child: Consumer<CartProvider>(
              builder: (context, cart, _) => Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        size: 26, color: Colors.black87),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle),
                        child: Text('${cart.itemCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final location = auth.user?.location;
        final city = location?.city ?? 'Select Location';
        final address = location?.address ??
            auth.user?.address ??
            'Tap to set your location';

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (_) => LocationPickerPage(
                  initialLat: location?.latitude,
                  initialLng: location?.longitude,
                ),
              ),
            );
            if (result != null && mounted) {
              // Update user location in provider
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location set to ${result['name']}'),
                  backgroundColor: AppTheme.accentGreen,
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade400, size: 22),
            const SizedBox(width: 12),
            Text('Search cuisines',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final categoryName = _categories[index];
          final emoji = _categoryEmojis[categoryName] ?? '🍽️';
          final isSelected = _selectedCategory == categoryName;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = categoryName);
              context.read<FoodProvider>().filterByCategory(categoryName);
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 140,
      child: Stack(
        children: [
          // Yellow background with pattern
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFE082)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: _KlikPatternPainter(),
                size: Size(MediaQuery.of(context).size.width - 32, 140),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('ENJOY',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'FREE',
                        style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                            height: 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('DELIVERY',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                // Fox mascot
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: Text('🦊', style: TextStyle(fontSize: 50))),
                ),
              ],
            ),
          ),
          // Dots indicator
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppTheme.primaryColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionsSection(FoodProvider foodProvider) {
    final promotions = foodProvider.promotions;
    if (promotions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_offer,
                      color: AppTheme.primaryColor, size: 22),
                  SizedBox(width: 8),
                  Text('Active Promotions',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PromotionsPage()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text('See All',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return _buildPromotionCard(promo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(promotion) {
    return GestureDetector(
      onTap: () {
        // Copy promo code to clipboard
        Clipboard.setData(ClipboardData(text: promotion.code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Promo code "${promotion.code}" copied!'),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        promotion.promoTypeIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (promotion.hotelName != null &&
                                promotion.hotelName.isNotEmpty)
                              Text(
                                promotion.hotelName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                promotion.discountText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.local_offer, color: Colors.white, size: 22),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy,
                              size: 12, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            promotion.code,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tap to copy',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(FoodProvider foodProvider) {
    // Use filteredFoods when a category is selected, otherwise show all foods
    final foods = _selectedCategory == 'All'
        ? foodProvider.foods.take(8).toList()
        : foodProvider.filteredFoods.take(8).toList();
    if (foods.isEmpty && !foodProvider.isLoading) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
              _selectedCategory == 'All' ? 'Offers for you' : _selectedCategory,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ),
        const SizedBox(height: 14),
        if (foodProvider.isLoading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()))
        else
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: foods.length,
              itemBuilder: (context, index) =>
                  _buildFoodOfferCard(foods[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildFoodOfferCard(Food food) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => FoodDetailPage(food: food))),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: food.image.isNotEmpty
                      ? Image.network(
                          food.image,
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 105,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: const Center(
                                child: Icon(Icons.fastfood,
                                    color: Colors.grey, size: 36)),
                          ),
                        )
                      : Container(
                          height: 105,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: const Center(
                              child: Icon(Icons.fastfood,
                                  color: Colors.grey, size: 36)),
                        ),
                ),
                if (food.discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${food.discount.toInt()}% Off',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${food.finalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 3),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 1),
                          child: Text('ETB',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _addToCart(food),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppTheme.accentYellow, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                color: AppTheme.accentYellow, size: 16),
                          ),
                        ),
                      ],
                    ),
                    if (food.discount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${food.price.toStringAsFixed(0)} ETB',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      food.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Restaurants Near You',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ),
        const SizedBox(height: 14),
        if (_isLoadingHotels)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()))
        else if (_hotels.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
                child: Text('No restaurants available',
                    style: TextStyle(color: Colors.grey.shade500))),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _hotels.length > 6 ? 6 : _hotels.length,
              itemBuilder: (context, index) =>
                  _buildRestaurantCard(_hotels[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildRestaurantCard(Hotel hotel) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HotelFoodsPage(hotel: hotel))),
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          children: [
            // Yellow pattern background
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(
                    painter: _KlikPatternPainter(), size: const Size(170, 200)),
              ),
            ),
            // Image overlay
            if (hotel.image != null && hotel.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  hotel.image!,
                  height: 200,
                  width: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            // Favorite button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border,
                    color: AppTheme.primaryColor, size: 20),
              ),
            ),
            // Bottom info card
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 3),
                        Text(hotel.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 10),
                        if (hotel.distanceText != null) ...[
                          Icon(Icons.location_on,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Text(hotel.distanceText!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ] else ...[
                          Icon(Icons.access_time,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text('30 min',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsTab() {
    return RefreshIndicator(
      onRefresh: _loadHotels,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 8),
              child: const Text('Restaurants',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
            ),

            if (_isLoadingHotels)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))
            else if (_hotels.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No restaurants found',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else ...[
              // Trending this week section
              _buildRestaurantSection(
                icon: '🔥',
                title: 'Trending this week',
                hotels: _hotels.take(5).toList(),
              ),

              const SizedBox(height: 24),

              // Fastest delivery section
              _buildRestaurantSection(
                icon: '🚀',
                title: 'Fastest delivery',
                hotels: _hotels.skip(2).take(5).toList(),
              ),

              const SizedBox(height: 24),

              // Nearby offers section
              _buildRestaurantSection(
                icon: '💰',
                title: 'Nearby offers',
                hotels: _hotels.reversed.take(5).toList(),
              ),

              const SizedBox(height: 100),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantSection({
    required String icon,
    required String title,
    required List<Hotel> hotels,
  }) {
    if (hotels.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: hotels.length,
            itemBuilder: (context, index) =>
                _buildKlikRestaurantCard(hotels[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildKlikRestaurantCard(Hotel hotel) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HotelFoodsPage(hotel: hotel))),
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Yellow pattern image area
            Stack(
              children: [
                Container(
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD54F),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: _KlikPatternPainter(),
                          size: const Size(180, 130),
                        ),
                        if (hotel.image != null && hotel.image!.isNotEmpty)
                          Image.network(
                            hotel.image!,
                            height: 130,
                            width: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                      ],
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        color: AppTheme.primaryColor, size: 18),
                  ),
                ),
                // Restaurant icon badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant_menu,
                        color: AppTheme.primaryColor, size: 18),
                  ),
                ),
              ],
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hotel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_outline,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                hotel.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel.address ?? 'Restaurant',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (hotel.distanceText != null) ...[
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            hotel.distanceText!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                          Text('•',
                              style: TextStyle(color: Colors.grey.shade400)),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.delivery_dining,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${hotel.deliveryFee.toInt()} ETB',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(0 Reviews)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.restaurant_menu_outlined,
                  Icons.restaurant_menu, 'Restaurants'),
              _buildNavItem(
                  2, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 24 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _KlikPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = -20.0; i < size.width + 40; i += 35) {
      for (var j = -20.0; j < size.height + 40; j += 35) {
        canvas.drawCircle(Offset(i, j), 5, paint);
        if ((i.toInt() + j.toInt()) % 70 == 0) {
          canvas.drawCircle(Offset(i + 17, j + 17), 3, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
