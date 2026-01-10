import 'package:flutter/material.dart';
import '../../data/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AnimatedFoodCard extends StatefulWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final int index;

  const AnimatedFoodCard({
    super.key,
    required this.food,
    required this.onTap,
    required this.onAddToCart,
    this.index = 0,
  });

  @override
  State<AnimatedFoodCard> createState() => _AnimatedFoodCardState();
}

class _AnimatedFoodCardState extends State<AnimatedFoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentYellow.withValues(alpha: 0.3),
            AppTheme.accentYellow.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant_menu,
            size: 40, color: AppTheme.accentYellow.withValues(alpha: 0.6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageHeight = constraints.maxHeight * 0.58;
                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Section
                        SizedBox(
                          height: imageHeight,
                          child: Stack(
                            children: [
                              Hero(
                                tag: 'food_${widget.food.id}',
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: widget.food.image.isNotEmpty
                                      ? Image.network(
                                          widget.food.image,
                                          width: double.infinity,
                                          height: imageHeight,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildPlaceholder(),
                                        )
                                      : _buildPlaceholder(),
                                ),
                              ),
                              // Discount Badge
                              if (widget.food.discount > 0)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${widget.food.discount.toInt()}% Off',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Content Section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Price Row
                                Row(
                                  children: [
                                    Text(
                                      '${widget.food.finalPrice.toStringAsFixed(0)} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      AppConstants.currency,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Add Button
                                    GestureDetector(
                                      onTap: widget.onAddToCart,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.accentYellow,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: AppTheme.accentYellow,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.food.discount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${widget.food.price.toStringAsFixed(0)} ${AppConstants.currency}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                // Food Name
                                Text(
                                  widget.food.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
