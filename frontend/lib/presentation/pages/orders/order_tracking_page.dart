import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import 'order_chat_page.dart';

class OrderTrackingPage extends StatefulWidget {
  final Order order;

  const OrderTrackingPage({super.key, required this.order});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final OrderRepository _orderRepo = OrderRepository();

  int _driverRating = 0;
  final _reviewController = TextEditingController();
  bool _hasConfirmedDelivery = false;
  bool _hasSubmittedReview = false;

  // Live tracking data
  Map<String, dynamic>? _trackingData;
  Timer? _trackingTimer;
  Timer? _countdownTimer;
  int _estimatedMinutes = 30;
  bool _isLoadingTracking = false;

  @override
  void initState() {
    super.initState();
    _estimatedMinutes = widget.order.delivery?.estimatedTime ?? 30;
    _startLiveTracking();
    _startCountdown();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _trackingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startLiveTracking() {
    _loadTrackingData();
    // Refresh tracking every 10 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (['assigned', 'picked_up', 'on_the_way', 'arrived']
          .contains(widget.order.delivery?.trackingStatus)) {
        _loadTrackingData();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_estimatedMinutes > 0 && widget.order.status != 'delivered') {
        setState(() => _estimatedMinutes--);
      }
    });
  }

  Future<void> _loadTrackingData() async {
    if (_isLoadingTracking) return;
    setState(() => _isLoadingTracking = true);
    try {
      final data = await _orderRepo.getDriverLocation(widget.order.id);
      if (mounted) {
        setState(() {
          _trackingData = data;
          _isLoadingTracking = false;
          if (data['estimatedTime'] != null) {
            _estimatedMinutes = data['estimatedTime'];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTracking = false);
    }
  }

  Future<void> _submitDriverRating() async {
    if (_driverRating == 0) return;
    try {
      await _orderRepo.rateDriver(
        widget.order.id,
        _driverRating,
        review: _reviewController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for rating your driver! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        setState(() => _hasSubmittedReview = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildOrderInfo(),
                    const SizedBox(height: 24),
                    if (widget.order.status == 'delivered' &&
                        !_hasConfirmedDelivery)
                      _buildDeliveryCompletionSection(),
                    if (_hasConfirmedDelivery && !_hasSubmittedReview)
                      _buildDriverRatingSection(),
                    if (_hasSubmittedReview) _buildThankYouSection(),
                    if (widget.order.status != 'delivered' ||
                        _hasSubmittedReview) ...[
                      _buildLiveTrackingCard(),
                      const SizedBox(height: 24),
                      _buildTrackingTimeline(),
                      const SizedBox(height: 24),
                    ],
                    _buildDriverInfo(),
                    const SizedBox(height: 24),
                    _buildDeliveryAddress(),
                    const SizedBox(height: 24),
                    _buildOrderItems(),
                    const SizedBox(height: 24),
                    if (widget.order.status == 'delivered')
                      _buildReorderButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrackingCard() {
    final delivery = widget.order.delivery;
    if (delivery == null || delivery.type != 'delivery')
      return const SizedBox.shrink();

    final hasDriver =
        delivery.driverName != null && delivery.driverName!.isNotEmpty;
    final isActive = ['assigned', 'picked_up', 'on_the_way', 'arrived']
        .contains(delivery.trackingStatus);

    if (!hasDriver || !isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Tracking',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_getTrackingStatusText(delivery.trackingStatus),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_isLoadingTracking)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Estimated time countdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                    'Estimated', '$_estimatedMinutes min', Icons.timer),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildTimeInfo(
                    'Distance',
                    '${(delivery.distance ?? 2.5).toStringAsFixed(1)} km',
                    Icons.route),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OrderChatPage(order: widget.order)),
                  ),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (delivery.driverPhone != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Call: ${delivery.driverPhone}'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  String _getTrackingStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'Driver on the way to restaurant';
      case 'picked_up':
        return 'Order picked up';
      case 'on_the_way':
        return 'On the way to you';
      case 'arrived':
        return 'Driver has arrived!';
      default:
        return 'Tracking...';
    }
  }

  Widget _buildDeliveryCompletionSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF34D399)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 60),
          const SizedBox(height: 16),
          const Text('🎉 Order Delivered!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Your food has arrived. Enjoy your meal!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _hasConfirmedDelivery = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Receipt & Rate Driver',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRatingSection() {
    final driverName = widget.order.delivery?.driverName ?? 'Driver';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Rate Your Driver',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          // Driver info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driverName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Delivered your order',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('How was your delivery experience?',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _driverRating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _driverRating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF59E0B),
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
              child: Text(_getDriverRatingText(),
                  style: TextStyle(
                      color: _driverRating > 0
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500))),
          const SizedBox(height: 20),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience with the driver (optional)',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _driverRating > 0 ? _submitDriverRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Rating',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _hasSubmittedReview = true),
              child: const Text('Skip for now'),
            ),
          ),
        ],
      ),
    );
  }

  String _getDriverRatingText() {
    switch (_driverRating) {
      case 1:
        return '😞 Poor';
      case 2:
        return '😐 Fair';
      case 3:
        return '🙂 Good';
      case 4:
        return '😊 Very Good';
      case 5:
        return '🤩 Excellent!';
      default:
        return 'Tap to rate';
    }
  }

  Widget _buildThankYouSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.favorite, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Thank You!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('We appreciate your feedback. See you again soon!',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReorderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Items added to cart!'),
                backgroundColor: AppTheme.primaryColor),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        icon: const Icon(Icons.replay, color: Colors.white),
        label: const Text('Order Again',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Track Order',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Order #${widget.order.orderNumber}',
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.order.status == 'delivered'
                ? const Color(0xFF10B981)
                : AppTheme.primaryColor,
            widget.order.status == 'delivered'
                ? const Color(0xFF34D399)
                : AppTheme.primaryColor.withValues(alpha: 0.8)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.order.status == 'delivered'
                        ? 'Delivered'
                        : 'Estimated Delivery',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.order.status == 'delivered'
                        ? '✓ Complete'
                        : '$_estimatedMinutes min',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(widget.order.statusDisplay,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final steps = [
      {
        'status': 'pending',
        'title': 'Order Placed',
        'icon': Icons.receipt_long
      },
      {
        'status': 'confirmed',
        'title': 'Order Confirmed',
        'icon': Icons.check_circle
      },
      {'status': 'preparing', 'title': 'Preparing', 'icon': Icons.restaurant},
      {'status': 'ready', 'title': 'Ready', 'icon': Icons.takeout_dining},
      {
        'status': 'out_for_delivery',
        'title': 'Out for Delivery',
        'icon': Icons.delivery_dining
      },
      {'status': 'delivered', 'title': 'Delivered', 'icon': Icons.home},
    ];

    final currentIndex =
        steps.indexWhere((s) => s['status'] == widget.order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: AppTheme.primaryColor, width: 3)
                            : null,
                      ),
                      child: Icon(step['icon'] as IconData,
                          color: isCompleted ? Colors.white : Colors.grey,
                          size: 20),
                    ),
                    if (index < steps.length - 1)
                      Container(
                          width: 2,
                          height: 40,
                          color: isCompleted
                              ? AppTheme.primaryColor
                              : Colors.grey.shade200),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step['title'] as String,
                            style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCompleted
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary)),
                        if (isCurrent && widget.order.status != 'delivered')
                          const Text('In progress...',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.primaryColor)),
                        if (isCurrent && widget.order.status == 'delivered')
                          const Text('Completed ✓',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    final delivery = widget.order.delivery;
    if (delivery == null || delivery.type != 'delivery')
      return const SizedBox.shrink();

    final hasDriver =
        delivery.driverName != null && delivery.driverName!.isNotEmpty;

    if (!hasDriver) {
      if (['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery']
          .contains(widget.order.status)) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining,
                    color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Driver',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      widget.order.status == 'pending' ||
                              widget.order.status == 'confirmed'
                          ? 'Will be assigned soon'
                          : 'Finding driver...',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (widget.order.status != 'pending' &&
                  widget.order.status != 'confirmed')
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.person,
                    color: AppTheme.primaryColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(delivery.driverName!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      widget.order.status == 'delivered'
                          ? 'Delivered your order'
                          : 'Your delivery driver',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    if (delivery.driverPhone != null &&
                        delivery.driverPhone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(delivery.driverPhone!,
                            style: const TextStyle(
                                color: AppTheme.primaryColor, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (widget.order.status != 'delivered') ...[
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OrderChatPage(order: widget.order))),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat, color: Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (delivery.driverPhone != null &&
                  delivery.driverPhone!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Call driver: ${delivery.driverPhone}'),
                          backgroundColor: AppTheme.successColor),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.phone, color: AppTheme.successColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    if (widget.order.deliveryAddress == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.location_on, color: AppTheme.secondaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.order.deliveryAddress!.label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.order.deliveryAddress!.fullAddress,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                if (widget.order.deliveryAddress!.instructions != null &&
                    widget.order.deliveryAddress!.instructions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        'Note: ${widget.order.deliveryAddress!.instructions}',
                        style: const TextStyle(
                            color: AppTheme.primaryColor, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...widget.order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${item.quantity}x',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.name)),
                    Text(
                        '${AppConstants.currency}${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                  '${AppConstants.currency}${widget.order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }
}
