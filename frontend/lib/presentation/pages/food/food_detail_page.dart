import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/food.dart';
import '../../../data/models/review.dart';
import '../../../data/repositories/food_repository.dart';
import '../../../data/repositories/review_repository.dart';
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
  final ReviewRepository _reviewRepo = ReviewRepository();

  List<Review> _reviews = [];
  bool _loadingReviews = false;

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

    _incrementView();
    _loadReviews();
  }

  Future<void> _incrementView() async {
    try {
      await _foodRepo.incrementView(widget.food.id);
      if (mounted) setState(() => _viewCount++);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final reviews = await _reviewRepo.getReviewsByFood(widget.food.id);
      if (mounted) setState(() => _reviews = reviews);
    } catch (e) {
      // Ignore
    }
    if (mounted) setState(() => _loadingReviews = false);
  }

  Future<void> _toggleLike() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please login to like foods'),
            backgroundColor: AppTheme.warningColor),
      );
      return;
    }

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
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  void _showWriteReviewDialog() {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please login to write a review'),
            backgroundColor: AppTheme.warningColor),
      );
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Write a Review',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Rating',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                    5,
                    (i) => GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedRating = i + 1),
                          child: Icon(
                            i < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFBBF24),
                            size: 36,
                          ),
                        )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your review...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(modalContext);
                    try {
                      await _reviewRepo.createReview(
                        foodId: widget.food.id,
                        rating: selectedRating,
                        comment: commentController.text.trim(),
                      );
                      _loadReviews();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Review submitted!'),
                              backgroundColor: AppTheme.accentGreen),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.errorColor),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Review',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
              SliverToBoxAdapter(child: _buildReviewsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
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
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
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
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: _isLiked ? Colors.red : AppTheme.textPrimary),
                if (_likeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                      _likeCount > 999
                          ? '${(_likeCount / 1000).toStringAsFixed(1)}k'
                          : '$_likeCount',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isLiked ? Colors.red : AppTheme.textPrimary)),
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
              widget.food.image.isNotEmpty
                  ? Image.network(widget.food.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder())
                  : _buildPlaceholder(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3)
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
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
                            colors: [Color(0xFFEF4444), Color(0xFFF87171)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${widget.food.discount.toInt()}% OFF',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withValues(alpha: 0.3),
          AppTheme.primaryLight.withValues(alpha: 0.1)
        ]),
      ),
      child: const Icon(Icons.restaurant, size: 80, color: Colors.white54),
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.food.name,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.store_outlined,
                                  size: 16, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(widget.food.hotelName,
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text(widget.food.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildTag(widget.food.category, AppTheme.primaryColor),
                  if (widget.food.isVegetarian)
                    _buildTag('Vegetarian', AppTheme.accentGreen),
                  if (widget.food.isSpicy)
                    _buildTag('Spicy 🌶️', AppTheme.errorColor),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _buildInfoCard(
                      Icons.timer_outlined,
                      '${widget.food.preparationTime}',
                      'Minutes',
                      AppTheme.accentBlue),
                  const SizedBox(width: 12),
                  _buildInfoCard(
                      Icons.visibility_outlined,
                      _viewCount > 999
                          ? '${(_viewCount / 1000).toStringAsFixed(1)}k'
                          : '$_viewCount',
                      'Views',
                      AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  _buildInfoCard(
                      Icons.favorite_outline,
                      _likeCount > 999
                          ? '${(_likeCount / 1000).toStringAsFixed(1)}k'
                          : '$_likeCount',
                      'Likes',
                      Colors.red),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Description',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Text(widget.food.description,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 15, height: 1.6)),
              const SizedBox(height: 28),
              _buildPriceSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withValues(alpha: 0.05),
          AppTheme.primaryLight.withValues(alpha: 0.02)
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Price',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '${AppConstants.currency}${widget.food.finalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                  if (widget.food.discount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                        '${AppConstants.currency}${widget.food.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough)),
                  ],
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow),
            child: Row(
              children: [
                _buildQuantityButton(Icons.remove, () {
                  if (_quantity > 1) setState(() => _quantity--);
                }),
                SizedBox(
                    width: 40,
                    child: Text('$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                _buildQuantityButton(
                    Icons.add, () => setState(() => _quantity++)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor)),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reviews (${_reviews.length})',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              TextButton.icon(
                onPressed: _showWriteReviewDialog,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Write Review'),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: Text('No reviews yet. Be the first to review!',
                      style: TextStyle(color: AppTheme.textSecondary))),
            )
          else
            ...(_reviews.take(5).map((r) => _buildReviewCard(r))),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow),
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
                          size: 18,
                        )),
              ),
              const Spacer(),
              Text(_formatDate(review.createdAt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
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
              offset: const Offset(0, -5))
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
                boxShadow: AppTheme.buttonShadow),
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
                        fontSize: 17)),
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
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
              child: Text('$_quantity x ${widget.food.name} added to cart')),
        ]),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    Navigator.pop(context);
  }
}
