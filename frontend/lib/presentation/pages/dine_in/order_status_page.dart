import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../state/websocket/websocket_provider.dart';
import '../../../state/language/language_provider.dart';
import '../../../state/dine_in/dine_in_provider.dart';
import '../../widgets/notification_dialog.dart';

class OrderStatusPage extends StatefulWidget {
  final String tableId;
  final String restaurantId;
  final String? guestSessionId; // NEW: Guest session ID

  const OrderStatusPage({
    super.key,
    required this.tableId,
    required this.restaurantId,
    this.guestSessionId, // NEW
  });

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _error;
  WebSocketProvider? _webSocketProvider;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrderStatus();

    // Setup WebSocket listener (for authenticated users)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWebSocket();
    });

    // Auto-refresh every 5 seconds for faster updates (WebSocket fallback)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadOrderStatus();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _webSocketProvider?.removeListener(_onWebSocketStateChanged);
    
    // Leave room and remove listeners
    if (_webSocketProvider != null) {
      final roomName = 'table:${widget.tableId}';
      _webSocketProvider!.leaveRoom(roomName);
      _webSocketProvider!.off('order:updated');
      _webSocketProvider!.off('order:created');
      _webSocketProvider!.off('notification:new');
    }
    
    super.dispose();
  }

  void _setupWebSocket() async {
    _webSocketProvider = Provider.of<WebSocketProvider>(context, listen: false);

    // If not connected, connect as guest (backend now supports guest connections)
    if (!_webSocketProvider!.isConnected) {
      debugPrint('[ORDER STATUS] Connecting as guest to WebSocket...');
      await _webSocketProvider!.connect('guest_token'); 
    }

    // Join table room
    _joinTableRoom();

    // Listen for order updates
    _webSocketProvider!.on('order:updated', _handleOrderUpdate);
    _webSocketProvider!.on('order:created', _handleOrderUpdate);
    _webSocketProvider!.on('notification:new', (data) {
      debugPrint('[ORDER STATUS] Received manual notification: $data');
      if (data['notification'] != null && mounted) {
        _showNotificationDialog(data['notification']);
      }
    });

    // Listen for connection changes to rejoin room if needed
    _webSocketProvider!.addListener(_onWebSocketStateChanged);
  }

  void _onWebSocketStateChanged() {
    if (_webSocketProvider!.isConnected && mounted) {
      debugPrint('[ORDER STATUS] WebSocket reconnected, rejoining table room');
      _joinTableRoom();
    }
  }

  void _joinTableRoom() {
    if (_webSocketProvider == null) return;
    final roomName = 'table:${widget.tableId}';
    _webSocketProvider!.joinRoom(roomName);
    debugPrint('[ORDER STATUS] Requested to join room: $roomName');
  }

  void _handleOrderUpdate(dynamic data) {
    debugPrint('[ORDER STATUS] Received update: $data');

    final status = data['status'];
    final orderNumber = data['orderNumber'] ?? 'N/A';

    // Show manual notification if present in the update
    if (data['notification'] != null && mounted) {
      _showNotificationDialog(data['notification']);
    }

    // Use message from kitchen if available, otherwise generate locally
    final message =
        data['message'] ?? _getStatusUpdateMessage(status, orderNumber);
    final backgroundColor = _getStatusColor(status);

    // Show snackbar for status updates
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_getStatusIcon(status), color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Trigger vibration for important status changes
    if (status == 'ready') {
      _vibratePattern(); // Order ready - pattern vibration
    } else if (status == 'cancelled') {
      _vibrateLong(); // Order cancelled - long vibration
      // Show dialog for cancellation if not already showing notification dialog
      if (mounted) {
        _showCancellationDialog(orderNumber, reason: data['reason'] ?? data['message']);
      }
    }

    // Reload order status to get latest data
    _loadOrderStatus();
  }

  void _showNotificationDialog(dynamic notification) {
    if (!mounted) return;
    
    // Extract message properly from nested structure if needed
    final message = notification['message'] ?? 
                  (notification is Map ? notification['text'] : null) ?? 
                  'Your order has been updated';

    NotificationDialog.show(
      context: context,
      title: notification['title'] ?? 'Kitchen Update',
      message: message,
      buttonText: 'Got it',
      icon: _getNotificationIcon(notification['type']),
      iconColor: AppTheme.premiumGold,
    );
    
    // Automatically mark as read
    _markNotificationRead();
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'success': return Icons.check_circle_outline;
      case 'error': return Icons.error_outline;
      case 'warning': return Icons.warning_amber_rounded;
      default: return Icons.info_outline;
    }
  }

  void _showCancellationDialog(String orderNumber, {String? reason}) {
    if (!mounted) return;

    NotificationDialog.show(
      context: context,
      title: 'Order Cancelled',
      message: reason ?? 'Your order #$orderNumber has been cancelled by the kitchen. Please contact the waiter for more information.',
      buttonText: 'Place New Order',
      onButtonPressed: () {
        Navigator.pop(context); // Close dialog
        _goToMenu(); // Redirect to menu
      },
      icon: Icons.cancel_outlined,
      iconColor: Colors.redAccent,
    );
  }

  String _getStatusUpdateMessage(String status, String orderNumber) {
    switch (status) {
      case 'confirmed':
        return 'Order #$orderNumber has been accepted by the kitchen!';
      case 'preparing':
        return 'Your order #$orderNumber is being prepared';
      case 'ready':
        return 'Order #$orderNumber is ready! Please collect from counter';
      case 'completed':
        return 'Order #$orderNumber has been served. Enjoy your meal!';
      case 'cancelled':
        return 'Order #$orderNumber has been cancelled';
      default:
        return 'Order #$orderNumber status updated to $status';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'completed':
        return Icons.celebration;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _vibratePattern() async {
    // Pattern: 200ms on, 100ms off, 200ms on
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }

  Future<void> _vibrateLong() async {
    // Long vibration: 500ms
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 500);
    }
  }

  /// Navigate back to menu page to place a new order
  void _goToMenu() async {
    // Clear the current guest session to allow a fresh start
    // since the backend has already freed the table
    try {
      await context.read<DineInProvider>().clearGuestSession(widget.tableId);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/dine-in-menu',
        arguments: {
          'restaurantId': widget.restaurantId,
          'tableId': widget.tableId,
        },
      );
    }
  }

  Future<void> _loadOrderStatus() async {
    try {
      // Build URL with guestSessionId query parameter if available
      String url = '${ApiConstants.orders}/table/${widget.tableId}/status';
      if (widget.guestSessionId != null) {
        url += '?guestSessionId=${widget.guestSessionId}';
      }

      final response = await ApiService.getPublic(url);

      if (mounted) {
        setState(() {
          _orderData = response['data'];
          _isLoading = false;
          _error = null;
        });

        // Show notification if there's a new unread one
        if (_orderData != null &&
            _orderData!['notification'] != null &&
            _orderData!['notification']['isRead'] == false) {
          _showNotificationDialog(_orderData!['notification']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markNotificationRead() async {
    if (_orderData == null) return;

    try {
      await ApiService.putPublic(
        '${ApiConstants.orders}/${_orderData!['orderId']}/notification/read',
        {},
      );

      // Reload to get updated data
      _loadOrderStatus();
    } catch (e) {
      // Error marking notification as read - silently fail
      debugPrint('Error marking notification as read: $e');
    }
  }

  bool _isRefreshing = false;

  Future<void> _onRefreshPressed() async {
    setState(() => _isRefreshing = true);
    await _loadOrderStatus();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(loc.orderStatus, style: const TextStyle(color: AppTheme.premiumGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.premiumGold),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.premiumGold),
                  )
                : const Icon(Icons.refresh, color: AppTheme.premiumGold),
            onPressed: _isRefreshing ? null : _onRefreshPressed,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.premiumGold))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrderStatus,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.premiumGold),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _orderData == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: AppTheme.premiumGold.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.noActiveOrder,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.placeOrderFirst,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildOrderStatus(),
      ),
    );
  }

  Widget _buildOrderStatus() {
    final status = _orderData!['status'] ?? 'pending';
    final orderNumber = _orderData!['orderNumber'] ?? 'N/A';
    final tableNumber = _orderData!['tableNumber'] ?? 'N/A';
    final items = _orderData!['items'] as List<dynamic>? ?? [];
    final totalPrice = (_orderData!['totalPrice'] ?? 0.0).toDouble();

    return RefreshIndicator(
      onRefresh: _loadOrderStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.premiumGold.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #$orderNumber',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.premiumGold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Table $tableNumber',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.premiumGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(status).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Timeline
            _buildStatusTimeline(status),

            const SizedBox(height: 24),

            // Order Items
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'ETB ${item['quantity']}x',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Text(
                                'ETB ${(item['price'] ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ETB ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Call Waiter Button
            if (status != 'completed' && status != 'cancelled')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _callWaiter,
                  icon: const Icon(Icons.notifications_active),
                  label: Text(context.read<LanguageProvider>().loc.callWaiter),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final loc = context.read<LanguageProvider>().loc;
    final statuses = [
      {'key': 'pending', 'label': loc.orderPlacedLabel, 'icon': Icons.receipt},
      {'key': 'confirmed', 'label': loc.accepted, 'icon': Icons.check_circle},
      {'key': 'preparing', 'label': loc.preparing, 'icon': Icons.restaurant},
      {'key': 'ready', 'label': loc.ready, 'icon': Icons.done_all},
      {'key': 'completed', 'label': loc.served, 'icon': Icons.celebration},
    ];

    final currentIndex = statuses.indexWhere((s) => s['key'] == currentStatus);
    final isCancelled = currentStatus == 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isCancelled
            ? Column(
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    size: 80,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ORDER REJECTED',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your order was rejected by the kitchen staff. Please try ordering another item or call the waiter for help.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _goToMenu,
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('EXPLORE MENU'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.premiumGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _callWaiter,
                    child: const Text('Need Help? Call Waiter', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              )
            : Column(
                children: List.generate(statuses.length, (index) {
                  final status = statuses[index];
                  final isActive = index <= currentIndex;
                  final isCurrent = index == currentIndex;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.premiumGold
                                  : Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: AppTheme.premiumGold.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                )
                              ] : null,
                            ),
                            child: Icon(
                              status['icon'] as IconData,
                              color: isActive ? Colors.black : Colors.white24,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status['label'] as String,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: isCurrent
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: isActive ? Colors.white : Colors.white24,
                                  ),
                                ),
                                if (isCurrent)
                                  Text(
                                    'Processing your order...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.premiumGold.withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            const Icon(Icons.hourglass_bottom, color: AppTheme.premiumGold, size: 20),
                        ],
                      ),
                      if (index < statuses.length - 1)
                        Container(
                          margin: const EdgeInsets.only(
                              left: 25, top: 8, bottom: 8),
                          width: 2,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                isActive ? AppTheme.premiumGold : Colors.white12,
                                (index + 1 <= currentIndex) ? AppTheme.premiumGold : Colors.white10,
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _callWaiter() async {
    final loc = context.read<LanguageProvider>().loc;
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(loc.callingWaiter)),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      await ApiService.postPublic(
        '${ApiConstants.orders}/dine-in/call-waiter',
        {
          'tableId': widget.tableId,
          'message': 'Customer needs assistance',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(loc.waiterNotified),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('${loc.failedCallWaiter}: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
