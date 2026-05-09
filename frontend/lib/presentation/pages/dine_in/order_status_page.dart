import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../state/websocket/websocket_provider.dart';
import '../../../state/language/language_provider.dart';

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

  void _showCancellationDialog(String orderNumber, {String? reason}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[400], size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Order Cancelled',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your order #$orderNumber has been cancelled by the kitchen.',
              style: const TextStyle(fontSize: 16),
            ),
            if (reason != null && reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(reason),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Please contact the waiter for assistance or place a new order.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _goToMenu();
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Place New Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
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

  void _showNotificationDialog(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'info';
    final message = notification['message'] ?? '';

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case 'success':
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'error':
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      default:
        backgroundColor = Colors.blue;
        icon = Icons.info;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: backgroundColor, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Order Update',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markNotificationRead();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: Text(loc.orderStatus),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _onRefreshPressed,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrderStatus,
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.noActiveOrder,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.placeOrderFirst,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildOrderStatus(),
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
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Table $tableNumber',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isCancelled
            ? Column(
                children: [
                  Icon(
                    Icons.cancel,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your order was rejected by the kitchen',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _goToMenu,
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Place New Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _callWaiter,
                    child: const Text('Call Waiter for Help'),
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status['icon'] as IconData,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              status['label'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (index < statuses.length - 1)
                        Container(
                          margin: const EdgeInsets.only(
                              left: 23, top: 4, bottom: 4),
                          width: 2,
                          height: 32,
                          color: isActive
                              ? AppTheme.primaryColor
                              : Colors.grey[300],
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
