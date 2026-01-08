import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.05),
              blurRadius: _isPressed ? 15 : 25,
              offset: Offset(0, _isPressed ? 5 : 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: _getStatusGradient(widget.order.status),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(widget.order.status),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.orderNumber.isNotEmpty
                              ? '#${widget.order.orderNumber}'
                              : '#${widget.order.id.substring(widget.order.id.length - 6).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.order.createdAt != null)
                          Text(
                            _formatDate(widget.order.createdAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildStatusChip(widget.order.status),
                  ),
                ],
              ),
            ),
            // Order items
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  ...widget.order.items.take(3).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    AppTheme.primaryLight
                                        .withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}x',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.hotelName.isNotEmpty)
                                    Text(
                                      item.hotelName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${AppConstants.currency}${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (widget.order.items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+${widget.order.items.length - 3} more items',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Payment & Delivery info
                  if (widget.order.payment != null ||
                      widget.order.delivery != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          if (widget.order.payment != null) ...[
                            _buildInfoBadge(
                              _getPaymentIcon(widget.order.payment!.method),
                              _getPaymentLabel(widget.order.payment!.method),
                              AppTheme.accentGreen,
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (widget.order.delivery != null)
                            _buildInfoBadge(
                              widget.order.delivery!.type == 'pickup'
                                  ? Icons.store_outlined
                                  : Icons.delivery_dining_outlined,
                              widget.order.delivery!.type == 'pickup'
                                  ? 'Pickup'
                                  : 'Delivery',
                              AppTheme.accentBlue,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Total row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${AppConstants.currency}${widget.order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  // Track button for active orders
                  if (widget.order.status != 'delivered' &&
                      widget.order.status != 'cancelled') ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Track Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status) {
      case 'delivered':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        );
      case 'preparing':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        );
      case 'out_for_delivery':
        return const LinearGradient(
          colors: [Color(0xFF6B35FF), Color(0xFF8A5CFF)],
        );
      case 'confirmed':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        );
      case 'cancelled':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
        );
      default:
        return AppTheme.primaryGradient;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant_outlined;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'confirmed':
        return Icons.thumb_up_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'telebirr':
        return Icons.phone_android;
      case 'mpesa':
        return Icons.phone_android;
      case 'cbe':
        return Icons.account_balance;
      default:
        return Icons.money;
    }
  }

  String _getPaymentLabel(String method) {
    switch (method) {
      case 'card':
        return 'Card';
      case 'telebirr':
        return 'Telebirr';
      case 'mpesa':
        return 'M-Pesa';
      case 'cbe':
        return 'CBE Birr';
      default:
        return 'Cash';
    }
  }

  Widget _buildStatusChip(String status) {
    String label;
    switch (status) {
      case 'delivered':
        label = 'Delivered';
        break;
      case 'preparing':
        label = 'Preparing';
        break;
      case 'out_for_delivery':
        label = 'On the way';
        break;
      case 'confirmed':
        label = 'Confirmed';
        break;
      case 'cancelled':
        label = 'Cancelled';
        break;
      default:
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} • ${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}
