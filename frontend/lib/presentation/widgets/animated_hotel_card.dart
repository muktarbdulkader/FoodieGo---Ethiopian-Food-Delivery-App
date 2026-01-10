import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AnimatedHotelCard extends StatefulWidget {
  final Hotel hotel;
  final VoidCallback onTap;
  final int index;

  const AnimatedHotelCard({
    super.key,
    required this.hotel,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<AnimatedHotelCard> createState() => _AnimatedHotelCardState();
}

class _AnimatedHotelCardState extends State<AnimatedHotelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 180,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with yellow pattern background like Klik
                  Stack(
                    children: [
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentYellow,
                        ),
                        child: widget.hotel.image != null &&
                                widget.hotel.image!.isNotEmpty
                            ? Image.network(
                                widget.hotel.image!,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPatternBg(),
                              )
                            : _buildPatternBg(),
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
                          child: Icon(
                            Icons.favorite_border,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                        ),
                      ),
                      // Logo/Icon
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.hotel.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.star_outline,
                                    color: AppTheme.accentYellow, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  widget.hotel.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.hotel.address ?? 'Restaurant',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '50 Mins',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.delivery_dining,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.hotel.deliveryFee.toInt()} ${AppConstants.currency}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(${widget.hotel.foodCount} Reviews)',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 9,
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
      ),
    );
  }

  Widget _buildPatternBg() {
    return Container(
      height: 100,
      width: double.infinity,
      color: AppTheme.accentYellow,
      child: CustomPaint(
        painter: _PatternPainter(),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw food-related doodles pattern
    for (var i = 0; i < size.width; i += 40) {
      for (var j = 0; j < size.height; j += 40) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
