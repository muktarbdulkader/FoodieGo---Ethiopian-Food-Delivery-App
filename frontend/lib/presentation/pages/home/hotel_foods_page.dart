import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user.dart';
import '../../../data/models/food.dart';
import '../../../data/models/review.dart';
import '../../../state/cart/cart_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../data/services/api_service.dart';
import '../../../data/repositories/review_repository.dart';
import '../food/food_detail_page.dart';
import '../cart/cart_page.dart';
import '../events/event_booking_page.dart';

class HotelFoodsPage extends StatefulWidget {
  final Hotel hotel;

  const HotelFoodsPage({super.key, required this.hotel});

  @override
  State<HotelFoodsPage> createState() => _HotelFoodsPageState();
}

class _HotelFoodsPageState extends State<HotelFoodsPage> {
  List<Food> _foods = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<Review> _reviews = [];
  bool _loadingReviews = false;
  bool _isFavorite = false;
  final ReviewRepository _reviewRepo = ReviewRepository();

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadReviews();
    _checkFavorite();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService.get('/foods/hotels/${widget.hotel.id}/foods');
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _foods = data.map((f) => Food.fromJson(f)).toList();
        _categories = ['All', ..._foods.map((f) => f.category).toSet()];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await _reviewRepo.getReviewsByRestaurant(widget.hotel.id);
      if (mounted) {
        setState(() => _reviews = reviews);
      }
    } catch (e) {
      // Ignore
    }
    if (mounted) {
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _checkFavorite() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      return;
    }
    try {
      final response =
          await ApiService.get('/auth/favorites/hotels/${widget.hotel.id}');
      if (mounted) {
        setState(() => _isFavorite = response['data']?['isFavorite'] ?? false);
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add favorites'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    // Optimistic update
    setState(() => _isFavorite = !_isFavorite);

    try {
      final response = await ApiService.post('/auth/favorites/hotels', {
        'hotelId': widget.hotel.id,
      });
      if (mounted) {
        final isFav = response['data']?['isFavorite'] ?? _isFavorite;
        setState(() => _isFavorite = isFav);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(isFav ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor:
                isFav ? const Color(0xFF10B981) : AppTheme.textSecondary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    }
  }

  List<Food> get _filteredFoods {
    if (_selectedCategory == 'All') return _foods;
    return _foods.where((f) => f.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHotelInfo()),
          SliverToBoxAdapter(child: _buildReviewsSection()),
          SliverToBoxAdapter(child: _buildCategories()),
          if (_isLoading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (_foods.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No menu items available',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildFoodCard(_filteredFoods[index]),
                  childCount: _filteredFoods.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomSheet: _buildCartBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppTheme.textPrimary),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : AppTheme.primaryColor,
            ),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHotelBannerImage(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelBannerImage() {
    final imageUrl = widget.hotel.image;

    // Check if image is base64
    if (imageUrl != null && imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultBanner(),
        );
      } catch (e) {
        return _buildDefaultBanner();
      }
    }

    // Regular URL image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultBanner(),
      );
    }

    return _buildDefaultBanner();
  }

  Widget _buildDefaultBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            Text(
              widget.hotel.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.hotel.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.hotel.isOpen
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 8,
                                  color: widget.hotel.isOpen
                                      ? const Color(0xFF10B981)
                                      : Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                widget.hotel.isOpen ? 'Open Now' : 'Closed',
                                style: TextStyle(
                                  color: widget.hotel.isOpen
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star,
                            color: Color(0xFFFBBF24), size: 18),
                        const SizedBox(width: 4),
                        Text(widget.hotel.rating.toStringAsFixed(1),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text('(${_reviews.length})',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // Call button
              if (widget.hotel.phone != null && widget.hotel.phone!.isNotEmpty)
                GestureDetector(
                  onTap: () => _showContactDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone,
                        color: Color(0xFF10B981), size: 22),
                  ),
                ),
            ],
          ),
          if (widget.hotel.address != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(widget.hotel.address!,
                        style: const TextStyle(color: AppTheme.textSecondary))),
              ],
            ),
          ],
          if (widget.hotel.phone != null && widget.hotel.phone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(widget.hotel.phone!,
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ],
          if (widget.hotel.description != null) ...[
            const SizedBox(height: 8),
            Text(widget.hotel.description!,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.delivery_dining,
                  '${AppConstants.currency}${widget.hotel.deliveryFee.toStringAsFixed(0)}'),
              _buildInfoChip(Icons.timer, '20-30 min'),
              _buildInfoChip(Icons.restaurant_menu, '${_foods.length} items'),
              if (widget.hotel.category != null)
                _buildInfoChip(Icons.category, widget.hotel.category!),
            ],
          ),
          const SizedBox(height: 16),
          // Event Booking Button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EventBookingPage(preselectedHotel: widget.hotel),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Book for Event (Wedding, Birthday...)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store,
                  color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.hotel.name,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.hotel.phone != null &&
                widget.hotel.phone!.isNotEmpty) ...[
              _buildContactRow(Icons.phone, 'Phone', widget.hotel.phone!),
              const SizedBox(height: 12),
            ],
            if (widget.hotel.address != null &&
                widget.hotel.address!.isNotEmpty) ...[
              _buildContactRow(
                  Icons.location_on, 'Address', widget.hotel.address!),
              const SizedBox(height: 12),
            ],
            _buildContactRow(Icons.star, 'Rating',
                '${widget.hotel.rating.toStringAsFixed(1)} ⭐'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.delivery_dining, 'Delivery Fee',
                '${AppConstants.currency}${widget.hotel.deliveryFee.toStringAsFixed(0)}'),
            if (widget.hotel.minOrderAmount > 0) ...[
              const SizedBox(height: 12),
              _buildContactRow(Icons.shopping_bag, 'Min Order',
                  '${AppConstants.currency}${widget.hotel.minOrderAmount.toStringAsFixed(0)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_loadingReviews) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 6),
                  Text(
                    widget.hotel.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${_reviews.length} reviews)',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              if (_reviews.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllReviews(),
                  child: const Text('See All'),
                ),
            ],
          ),
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No reviews yet',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            ...(_reviews.take(2).map((r) => _buildReviewCard(r))),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Stars rating
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFBBF24),
                          size: 16,
                        )),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inMinutes}m ago';
  }

  void _showAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.hotel.rating.toStringAsFixed(1)} • ${_reviews.length} Reviews',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _reviews.length,
                itemBuilder: (context, index) =>
                    _buildReviewCard(_reviews[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFoodCard(Food food) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => FoodDetailPage(food: food))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxHeight * 0.5;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: food.image.isNotEmpty
                            ? Image.network(
                                food.image,
                                height: imageHeight,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: imageHeight,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood,
                                      color: Colors.grey),
                                ),
                              )
                            : Container(
                                height: imageHeight,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.fastfood,
                                    color: Colors.grey),
                              ),
                      ),
                      if (food.discount > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text('${food.discount.toInt()}% OFF',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (!food.isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: const Center(
                                child: Text('Unavailable',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(food.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFBBF24), size: 11),
                            const SizedBox(width: 2),
                            Text(food.rating.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10)),
                            const Spacer(),
                            Text('${food.preparationTime}m',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${AppConstants.currency}${food.finalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppTheme.primaryColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (food.discount > 0)
                                    Text(
                                      '${AppConstants.currency}${food.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade400,
                                          decoration:
                                              TextDecoration.lineThrough),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: food.isAvailable
                                  ? () {
                                      context
                                          .read<CartProvider>()
                                          .addToCart(food);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('${food.name} added'),
                                            backgroundColor:
                                                AppTheme.successColor,
                                            duration:
                                                const Duration(seconds: 1)),
                                      );
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: food.isAvailable
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartBar() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.itemCount == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4))
            ],
          ),
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CartPage())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${cart.itemCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Text('View Cart',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    Text(
                        '${AppConstants.currency}${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
