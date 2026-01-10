import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/food.dart';
import '../../../data/repositories/food_repository.dart';
import '../../../state/cart/cart_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class FoodDetailPage extends StatefulWidget {
  final Food food;
  const FoodDetailPage({super.key, required this.food});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage>
    with TickerProviderStateMixin {
  int _quantity = 1;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLiked = false;
  int _likeCount = 0;
  int _viewCount = 0;
  final FoodRepository _foodRepo = FoodRepository();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.food.isLiked;
    _likeCount = widget.food.likeCount;
    _viewCount = widget.food.viewCount;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _slideController.forward();
    _scaleController.forward();

    // Increment view count
    _incrementView();
  }

  Future<void> _incrementView() async {
    try {
      await _foodRepo.incrementView(widget.food.id);
      if (mounted) {
        setState(() => _viewCount++);
      }
    } catch (e) {
      // Ignore view count errors
    }
  }

  Future<void> _toggleLike() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like foods'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      final result = await _foodRepo.toggleLike(widget.food.id);
      if (mounted) {
        setState(() {
          _isLiked = result['isLiked'] ?? _isLiked;
          _likeCount = result['likeCount'] ?? _likeCount;
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildContent()),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppTheme.textPrimary),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _toggleLike,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(_isLiked),
                    size: 20,
                    color: _isLiked ? Colors.red : AppTheme.textPrimary,
                  ),
                ),
                if (_likeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    _likeCount > 999
                        ? '${(_likeCount / 1000).toStringAsFixed(1)}k'
                        : '$_likeCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isLiked ? Colors.red : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'food_${widget.food.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.food.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.3),
                        AppTheme.primaryLight.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.restaurant,
                      size: 80, color: Colors.white54),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Discount badge
              if (widget.food.discount > 0)
                Positioned(
                  top: 100,
                  left: 20,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.food.discount.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and rating row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.food.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.store_outlined,
                                    size: 16, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.food.hotelName,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFBBF24).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            widget.food.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tags
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildAnimatedTag(
                        widget.food.category, AppTheme.primaryColor, 0),
                    if (widget.food.isVegetarian)
                      _buildAnimatedTag('Vegetarian', AppTheme.accentGreen, 1),
                    if (widget.food.isSpicy)
                      _buildAnimatedTag('Spicy 🌶️', AppTheme.errorColor, 2),
                  ],
                ),
                const SizedBox(height: 28),
                // Info cards
                Row(
                  children: [
                    _buildInfoCard(
                      Icons.timer_outlined,
                      '${widget.food.preparationTime}',
                      'Minutes',
                      AppTheme.accentBlue,
                      0,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoCard(
                      Icons.visibility_outlined,
                      _viewCount > 999 ? '${(_viewCount / 1000).toStringAsFixed(1)}k' : '$_viewCount',
                      'Views',
                      AppTheme.primaryColor,
                      1,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoCard(
                      Icons.favorite_outline,
                      _likeCount > 999 ? '${(_likeCount / 1000).toStringAsFixed(1)}k' : '$_likeCount',
                      'Likes',
                      Colors.red,
                      2,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.food.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                // Price section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.05),
                        AppTheme.primaryLight.withValues(alpha: 0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${AppConstants.currency}${widget.food.finalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (widget.food.discount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${AppConstants.currency}${widget.food.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      // Quantity selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              Icons.remove,
                              () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                    scale: animation, child: child);
                              },
                              child: SizedBox(
                                width: 40,
                                child: Text(
                                  '$_quantity',
                                  key: ValueKey(_quantity),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              Icons.add,
                              () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTag(String text, Color color, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String value, String label, Color color, int index) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 500 + (index * 100)),
        curve: Curves.easeOutBack,
        builder: (context, animValue, child) {
          return Transform.scale(scale: animValue, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 20, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalPrice = widget.food.finalPrice * _quantity;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: _addToCart,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Add to Cart  •  ${AppConstants.currency}${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addToCart() {
    for (int i = 0; i < _quantity; i++) {
      context.read<CartProvider>().addToCart(widget.food);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$_quantity x ${widget.food.name} added to cart'),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }
}
