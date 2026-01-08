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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageHeight = constraints.maxHeight * 0.6;
                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image - fixed height based on container
                        SizedBox(
                          height: imageHeight,
                          child: Stack(
                            children: [
                              Hero(
                                tag: 'food_${widget.food.id}',
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Image.network(
                                    widget.food.image,
                                    width: double.infinity,
                                    height: imageHeight,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.2),
                                      child: const Icon(Icons.restaurant,
                                          size: 32, color: Colors.white54),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.food.discount > 0)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '-${widget.food.discount.toInt()}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          color: Color(0xFFFBBF24), size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                          widget.food.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content - takes remaining space
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.food.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.food.hotelName,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${AppConstants.currency}${widget.food.finalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.primaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (widget.food.discount > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.food.price.toStringAsFixed(0),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Add to cart button - positioned at the junction of image and content
                    Positioned(
                      right: 8,
                      top: imageHeight - 16,
                      child: GestureDetector(
                        onTap: widget.onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 16),
                        ),
                      ),
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
