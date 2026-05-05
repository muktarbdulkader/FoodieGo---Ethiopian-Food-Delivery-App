import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Delivery Map Widget - Visual representation of driver location
/// Shows route from restaurant to customer with driver position
class DeliveryMapWidget extends StatefulWidget {
  final dynamic driverLocation; // DriverLocation object or Map with 'lat', 'lng'
  final dynamic restaurantLocation; // PickupLocation or Map
  final dynamic customerLocation; // DeliveryAddress or Map with 'latitude', 'longitude'
  final String? driverName;
  final String? status;
  final double? distance;
  final int? estimatedMinutes;

  const DeliveryMapWidget({
    super.key,
    this.driverLocation,
    this.restaurantLocation,
    this.customerLocation,
    this.driverName,
    this.status,
    this.distance,
    this.estimatedMinutes,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _animationTimer;
  double _driverProgress = 0.0;

  // Extract coordinates from various location object types
  double? get driverLat {
    if (widget.driverLocation == null) return null;
    if (widget.driverLocation is Map) {
      return (widget.driverLocation['lat'] ?? widget.driverLocation['latitude'])?.toDouble();
    }
    // DriverLocation model
    return widget.driverLocation.latitude?.toDouble();
  }

  double? get driverLng {
    if (widget.driverLocation == null) return null;
    if (widget.driverLocation is Map) {
      return (widget.driverLocation['lng'] ?? widget.driverLocation['longitude'])?.toDouble();
    }
    return widget.driverLocation.longitude?.toDouble();
  }

  double? get restaurantLat {
    if (widget.restaurantLocation == null) return null;
    if (widget.restaurantLocation is Map) {
      return widget.restaurantLocation['lat']?.toDouble() ??
             widget.restaurantLocation['latitude']?.toDouble();
    }
    return widget.restaurantLocation.latitude?.toDouble();
  }

  double? get restaurantLng {
    if (widget.restaurantLocation == null) return null;
    if (widget.restaurantLocation is Map) {
      return widget.restaurantLocation['lng']?.toDouble() ??
             widget.restaurantLocation['longitude']?.toDouble();
    }
    return widget.restaurantLocation.longitude?.toDouble();
  }

  double? get customerLat {
    if (widget.customerLocation == null) return null;
    if (widget.customerLocation is Map) {
      return widget.customerLocation['lat']?.toDouble() ??
             widget.customerLocation['latitude']?.toDouble();
    }
    return widget.customerLocation.latitude?.toDouble();
  }

  double? get customerLng {
    if (widget.customerLocation == null) return null;
    if (widget.customerLocation is Map) {
      return widget.customerLocation['lng']?.toDouble() ??
             widget.customerLocation['longitude']?.toDouble();
    }
    return widget.customerLocation.longitude?.toDouble();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _calculateProgress();
  }

  @override
  void didUpdateWidget(covariant DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (driverLat != null &&
        (driverLat != _extractCoord(oldWidget.driverLocation, 'lat') ||
         driverLng != _extractCoord(oldWidget.driverLocation, 'lng'))) {
      _calculateProgress();
    }
  }

  double? _extractCoord(dynamic location, String key) {
    if (location == null) return null;
    if (location is Map) {
      return location[key]?.toDouble() ?? location['${key}itude']?.toDouble();
    }
    return key == 'lat' ? location.latitude?.toDouble() : location.longitude?.toDouble();
  }

  void _calculateProgress() {
    // Calculate driver's progress along the route
    if (restaurantLat != null &&
        restaurantLng != null &&
        customerLat != null &&
        customerLng != null &&
        driverLat != null &&
        driverLng != null) {
      final totalDistance = _calculateDistance(
        restaurantLat!,
        restaurantLng!,
        customerLat!,
        customerLng!,
      );
      final driverToCustomer = _calculateDistance(
        driverLat!,
        driverLng!,
        customerLat!,
        customerLng!,
      );
      setState(() {
        _driverProgress = 1.0 - (driverToCustomer / totalDistance).clamp(0.0, 1.0);
      });
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  @override
  void dispose() {
    _pulseController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Map background with grid pattern
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE0F2FE),
                    const Color(0xFFDBEAFE),
                  ],
                ),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: MapGridPainter(),
              ),
            ),

            // Route line
            if (restaurantLat != null && customerLat != null)
              CustomPaint(
                size: Size.infinite,
                painter: RouteLinePainter(
                  progress: _driverProgress,
                  hasDriver: driverLat != null,
                ),
              ),

            // Restaurant marker
            if (restaurantLat != null)
              Positioned(
                left: 20,
                top: 80,
                child: _buildMarker(
                  icon: Icons.store,
                  color: const Color(0xFF8B5CF6),
                  label: 'Restaurant',
                  isPulsing: false,
                ),
              ),

            // Customer marker
            if (customerLat != null)
              Positioned(
                right: 20,
                bottom: 80,
                child: _buildMarker(
                  icon: Icons.home,
                  color: const Color(0xFF10B981),
                  label: 'You',
                  isPulsing: false,
                ),
              ),

            // Driver marker (animated along route)
            if (driverLat != null)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Positioned(
                    left: 20 + (MediaQuery.of(context).size.width - 72) * _driverProgress,
                    top: 80 + (160 * _driverProgress),
                    child: _buildDriverMarker(),
                  );
                },
              ),

            // Status overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.estimatedMinutes != null)
                            Text(
                              'Arriving in ${widget.estimatedMinutes} min',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.distance != null)
                      Text(
                        '${widget.distance!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Distance indicator
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDistanceDot('Restaurant', const Color(0xFF8B5CF6), true),
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B5CF6),
                              _driverProgress > 0.5
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _buildDistanceDot('You', const Color(0xFF10B981), _driverProgress >= 0.95),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker({
    required IconData icon,
    required Color color,
    required String label,
    required bool isPulsing,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.2);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.driverName ?? 'Driver',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDistanceDot(String label, Color color, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? color : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case 'assigned':
        return const Color(0xFF3B82F6);
      case 'picked_up':
        return const Color(0xFF8B5CF6);
      case 'on_the_way':
        return const Color(0xFFF59E0B);
      case 'arrived':
        return const Color(0xFF10B981);
      case 'delivered':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case 'assigned':
        return Icons.person_pin;
      case 'picked_up':
        return Icons.shopping_bag;
      case 'on_the_way':
        return Icons.delivery_dining;
      case 'arrived':
        return Icons.location_on;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case 'assigned':
        return 'Driver assigned';
      case 'picked_up':
        return 'Order picked up';
      case 'on_the_way':
        return 'On the way';
      case 'arrived':
        return 'Driver arrived!';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Tracking...';
    }
  }
}

/// Map Grid Painter - Draws a subtle grid pattern
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..strokeWidth = 0.5;

    const gridSize = 40.0;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some decorative "roads"
    final roadPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Main road
    final path = Path()
      ..moveTo(40, 120)
      ..lineTo(size.width - 40, 200);
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Route Line Painter - Draws the delivery route line
class RouteLinePainter extends CustomPainter {
  final double progress;
  final bool hasDriver;

  RouteLinePainter({required this.progress, required this.hasDriver});

  @override
  void paint(Canvas canvas, Size size) {
    // Completed route (restaurant to driver)
    final completedPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Remaining route (driver to customer)
    final remainingPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startX = 40.0;
    final startY = 120.0;
    final endX = size.width - 40;
    final endY = 200.0;

    // Calculate current driver position
    final currentX = startX + (endX - startX) * progress;
    final currentY = startY + (endY - startY) * progress;

    // Draw completed part
    if (progress > 0) {
      final completedPath = Path()
        ..moveTo(startX, startY)
        ..lineTo(currentX, currentY);
      canvas.drawPath(completedPath, completedPaint);
    }

    // Draw remaining part
    final remainingPath = Path()
      ..moveTo(currentX, currentY)
      ..lineTo(endX, endY);
    canvas.drawPath(remainingPath, remainingPaint);
  }

  @override
  bool shouldRepaint(covariant RouteLinePainter oldDelegate) =>
      progress != oldDelegate.progress || hasDriver != oldDelegate.hasDriver;
}
