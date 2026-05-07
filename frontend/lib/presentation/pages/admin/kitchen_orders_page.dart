import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/kitchen_localizations.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../core/services/audio_service.dart';
import '../../../state/websocket/websocket_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../widgets/order_timer.dart';

class KitchenOrdersPage extends StatefulWidget {
  const KitchenOrdersPage({super.key});

  @override
  State<KitchenOrdersPage> createState() => _KitchenOrdersPageState();
}

class _KitchenOrdersPageState extends State<KitchenOrdersPage> {
  final OrderRepository _orderRepository = OrderRepository();
  final AudioService _audioService = AudioService();
  List<Order> _orders = [];
  List<Map<String, dynamic>> _waiterCalls = []; // Pending waiter calls
  bool _isLoading = true;
  bool _isRefreshing = false; // Track manual refresh state
  bool _showWaiterCalls = false; // Toggle to show waiter calls panel
  String _selectedFilter = 'pending'; // pending, confirmed, preparing, ready
  NotificationLanguage _notificationLanguage = NotificationLanguage.english;
  WebSocketProvider? _webSocketProvider;
  String? _restaurantId;
  Timer? _refreshTimer;
  Timer? _wsReconnectTimer; // Timer for retrying WebSocket room join
  DateTime? _lastUpdated;
  Set<String> _knownOrderIds = {}; // Track known orders to detect new ones
  bool _hasJoinedRoom = false; // Track if we've successfully joined the room

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadWaiterCalls();

    // Setup WebSocket listener after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWebSocket();
    });

    // Auto-refresh every 3 seconds for near-instant order detection
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _loadOrders();
        _loadWaiterCalls();
      }
    });
  }

  /// Attempt to join the kitchen room with retry logic
  void _joinKitchenRoom() {
    if (_restaurantId == null || _webSocketProvider == null) return;

    if (!_webSocketProvider!.isConnected) {
      debugPrint('[KITCHEN] WebSocket not connected yet, will retry...');
      _scheduleRoomJoinRetry();
      return;
    }

    // Join kitchen room
    final roomName = 'kitchen:$_restaurantId';
    _webSocketProvider!.joinRoom(roomName);
    _hasJoinedRoom = true;
    debugPrint('[KITCHEN] Joined room: $roomName');

    // Cancel any pending retry timer
    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = null;
  }

  /// Schedule a retry to join the room
  void _scheduleRoomJoinRetry() {
    _wsReconnectTimer?.cancel();
    _wsReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_hasJoinedRoom) {
        debugPrint('[KITCHEN] Retrying room join...');
        _joinKitchenRoom();
      }
    });
  }

  Future<void> _loadWaiterCalls() async {
    try {
      final calls = await _orderRepository.getPendingWaiterCalls();
      if (mounted) {
        setState(() {
          _waiterCalls = calls;
        });
      }
    } catch (e) {
      debugPrint('Error loading waiter calls: $e');
    }
  }

  Future<void> _acknowledgeWaiterCall(String callId) async {
    try {
      await _orderRepository.acknowledgeWaiterCall(callId);
      _loadWaiterCalls(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waiter call acknowledged'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to acknowledge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupWebSocket() async {
    _webSocketProvider = Provider.of<WebSocketProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get restaurant ID from auth provider
    _restaurantId = authProvider.user?.id;

    if (_restaurantId != null) {
      // Ensure WebSocket is connected - use admin token if needed
      if (!_webSocketProvider!.isConnected) {
        final adminToken = StorageUtils.getToken(SessionType.admin);
        if (adminToken != null) {
          debugPrint('[KITCHEN] Connecting WebSocket with admin token...');
          await _webSocketProvider!.connect(adminToken);
        } else {
          debugPrint('[KITCHEN] No admin token found, WebSocket not connected');
        }
      }

      // Listen for order events first (before connection)
      _webSocketProvider!.on('order:created', _handleNewOrder);
      _webSocketProvider!.on('order:updated', _handleOrderUpdate);
      _webSocketProvider!.on('waiter:called', _handleWaiterCall);

      // Listen to connection state changes to rejoin room on reconnection
      _webSocketProvider!.addListener(_onWebSocketStateChanged);

      // Try to join room immediately if already connected, or retry when connected
      _joinKitchenRoom();
    }
  }

  /// Handle WebSocket connection state changes
  void _onWebSocketStateChanged() {
    if (_webSocketProvider == null) return;

    if (_webSocketProvider!.isConnected && !_hasJoinedRoom) {
      debugPrint('[KITCHEN] WebSocket connected, joining room...');
      _joinKitchenRoom();
    } else if (!_webSocketProvider!.isConnected) {
      // Mark as not joined so we'll rejoin when reconnected
      _hasJoinedRoom = false;
    }
  }

  void _handleNewOrder(dynamic data) {
    debugPrint('[KITCHEN] New order received: $data');

    // Play sound alert
    _playNewOrderSound();

    // Reload orders
    _loadOrders();

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'New order #${data['orderNumber']} - Table ${data['tableNumber']}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleOrderUpdate(dynamic data) {
    debugPrint('[KITCHEN] Order updated: $data');

    // Reload orders
    _loadOrders();
  }

  void _handleWaiterCall(dynamic data) {
    debugPrint('[KITCHEN] Waiter called: $data');

    // Play waiter call sound with table number in selected language
    final tableNumber = data['tableNumber']?.toString();
    _playWaiterCallSound(tableNumber: tableNumber);

    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Text('Table ${data['tableNumber']?.toString() ?? 'Unknown'}'),
            ],
          ),
          content:
              Text(data['message']?.toString() ?? 'Customer needs assistance'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Play new order sound in the selected notification language
  Future<void> _playNewOrderSound() async {
    try {
      await _audioService.playNewOrderNotification(
        _notificationLanguage,
        orderNumber: '', // Will be set by the caller
      );
    } catch (e) {
      debugPrint('[KITCHEN] Error playing new order sound: $e');
    }
  }

  /// Play waiter call sound in the selected notification language
  Future<void> _playWaiterCallSound({String? tableNumber}) async {
    try {
      await _audioService.playWaiterCall(
        _notificationLanguage,
        tableNumber: tableNumber,
      );
    } catch (e) {
      debugPrint('[KITCHEN] Error playing waiter call sound: $e');
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _refreshTimer?.cancel();
    _wsReconnectTimer?.cancel();

    // Remove WebSocket state listener
    _webSocketProvider?.removeListener(_onWebSocketStateChanged);

    // Leave room and remove event listeners
    if (_webSocketProvider != null && _restaurantId != null) {
      final roomName = 'kitchen:$_restaurantId';
      _webSocketProvider!.leaveRoom(roomName);
      _webSocketProvider!.off('order:created');
      _webSocketProvider!.off('order:updated');
      _webSocketProvider!.off('waiter:called');
    }

    super.dispose();
  }

  Future<void> _loadOrders({int retryCount = 0}) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 5);

    try {
      final orders = await _orderRepository.getAllOrders();

      // Filter only dine-in orders
      final dineInOrders =
          orders.where((order) => order.type == 'dine_in').toList();

      // Sort by creation time (newest first)
      dineInOrders.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.now();
        final bTime = b.createdAt ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        // Detect brand-new orders (not seen before) that are pending
        final newOrders = dineInOrders
            .where((order) =>
                order.status == 'pending' && !_knownOrderIds.contains(order.id))
            .toList();

        // Update known IDs
        final allIds = dineInOrders.map((o) => o.id).toSet();

        // On first load, just seed the known IDs without alerting
        final isFirstLoad = _knownOrderIds.isEmpty;

        setState(() {
          _orders = dineInOrders;
          _isLoading = false;
          _isRefreshing = false;
          _lastUpdated = DateTime.now();
          _knownOrderIds = allIds;
        });

        // Alert for each new order (only after initial load)
        if (!isFirstLoad && newOrders.isNotEmpty) {
          for (final newOrder in newOrders) {
            _alertNewOrder(newOrder);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading kitchen orders: $e');

      // Retry logic for timeout errors (backend sleeping on Render free tier)
      if (e.toString().contains('timed out') && retryCount < maxRetries) {
        debugPrint('Retrying... Attempt ${retryCount + 1}/$maxRetries');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Server is waking up... Retry ${retryCount + 1}/$maxRetries'),
              backgroundColor: Colors.orange,
              duration: retryDelay,
            ),
          );
        }

        await Future.delayed(retryDelay);
        return _loadOrders(retryCount: retryCount + 1);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.toString().contains('timed out') ? 'Server is sleeping. Please wait and try again.' : e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadOrders(),
            ),
          ),
        );
      }
    }
  }

  /// Called when a new pending order is detected via polling
  void _alertNewOrder(Order order) {
    // Play sound
    _playNewOrderSound();

    // Switch to pending tab so the order is visible
    if (mounted && _selectedFilter != 'pending') {
      setState(() => _selectedFilter = 'pending');
    }

    // Show prominent banner
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🆕 New Order!',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '#${order.orderNumber} · Table ${order.tableNumber ?? order.tableId ?? 'N/A'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      _loadOrders(),
      _loadWaiterCalls(),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Orders refreshed'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<Order> get _filteredOrders {
    return _orders.where((order) => order.status == _selectedFilter).toList();
  }

  KitchenLocalizations get _loc =>
      KitchenLocalizations(_notificationLanguage.code);

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Notification Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...NotificationLanguage.values.map((lang) => ListTile(
                  leading: Radio<NotificationLanguage>(
                    value: lang,
                    groupValue: _notificationLanguage,
                    onChanged: (value) {
                      setState(() {
                        _notificationLanguage = value!;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  title: Text(lang.displayName),
                  onTap: () {
                    setState(() {
                      _notificationLanguage = lang;
                    });
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(Order order) async {
    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${_loc.get('order_accepted')} - #${order.orderNumber}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Update UI optimistically
    setState(() {
      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders[index] = Order(
          id: order.id,
          orderNumber: order.orderNumber,
          userId: order.userId,
          userName: order.userName,
          userEmail: order.userEmail,
          userPhone: order.userPhone,
          items: order.items,
          subtotal: order.subtotal,
          deliveryFee: order.deliveryFee,
          tax: order.tax,
          tip: order.tip,
          discount: order.discount,
          totalPrice: order.totalPrice,
          status: 'confirmed', // Optimistic update
          payment: order.payment,
          deliveryAddress: order.deliveryAddress,
          delivery: order.delivery,
          notes: order.notes,
          promoCode: order.promoCode,
          createdAt: order.createdAt,
          type: order.type,
          tableId: order.tableId,
          tableNumber: order.tableNumber,
          restaurantId: order.restaurantId,
          chatMessages: order.chatMessages,
        );
      }
    });

    // Then update on server in background
    try {
      await _orderRepository.updateOrderStatus(
        order.id,
        'confirmed',
      );

      // Send notification to customer
      _orderRepository
          .sendOrderNotification(
            orderId: order.id,
            tableId: order.tableId ?? '',
            status: 'confirmed',
            message: _loc.get('order_accepted'),
            languageCode: _notificationLanguage.code,
          )
          .catchError((e) => debugPrint('Notification error: $e'));

      // Emit WebSocket event for real-time update
      _webSocketProvider?.emit('order:updated', {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'tableId': order.tableId,
        'status': 'confirmed',
        'message': _loc.get('order_accepted'),
        'languageCode': _notificationLanguage.code,
      });

      // Reload to get fresh data
      _loadOrders();
    } catch (e) {
      // Revert optimistic update on error
      _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_loc.get('failed_accept')}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(Order order) async {
    // Show rejection dialog with reason
    final TextEditingController reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_loc.get('reject_order')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_loc.get('reject_confirmation')),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: _loc.get('reject_reason'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_loc.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(_loc.get('reject_order')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Use updateOrderStatus to set status to cancelled (restaurant can do this)
      await _orderRepository.updateOrderStatus(
        order.id,
        'cancelled',
      );

      // Send notification to customer
      await _orderRepository.sendOrderNotification(
        orderId: order.id,
        tableId: order.tableId ?? '',
        status: 'cancelled',
        message: reasonController.text.isNotEmpty
            ? '${_loc.get('order_rejected')}: ${reasonController.text}'
            : _loc.get('order_rejected'),
        languageCode: _notificationLanguage.code,
      );

      // Emit WebSocket event
      _webSocketProvider?.emit('order:updated', {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'tableId': order.tableId,
        'status': 'cancelled',
        'message': _loc.get('order_rejected'),
        'reason': reasonController.text,
        'languageCode': _notificationLanguage.code,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${_loc.get('order_rejected')} - #${order.orderNumber}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_loc.get('failed_reject')}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await _orderRepository.updateOrderStatus(
        order.id,
        newStatus,
      );

      // Get status message
      String statusMessage;
      switch (newStatus) {
        case 'preparing':
          statusMessage = _loc.get('order_preparing');
          break;
        case 'ready':
          statusMessage = _loc.get('order_ready');
          break;
        case 'completed':
          statusMessage = _loc.get('order_completed');
          break;
        default:
          statusMessage = 'Order updated to $newStatus';
      }

      // Send notification to customer
      await _orderRepository.sendOrderNotification(
        orderId: order.id,
        tableId: order.tableId ?? '',
        status: newStatus,
        message: statusMessage,
        languageCode: _notificationLanguage.code,
      );

      // Emit WebSocket event
      _webSocketProvider?.emit('order:updated', {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'tableId': order.tableId,
        'status': newStatus,
        'message': statusMessage,
        'languageCode': _notificationLanguage.code,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$statusMessage - #${order.orderNumber}'),
          backgroundColor: _getStatusColor(newStatus),
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_loc.get('failed_update')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Orders'),
        actions: [
          // Language selector
          InkWell(
            onTap: _showLanguageSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _notificationLanguage.code.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Waiter calls button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_active),
                onPressed: () {
                  setState(() {
                    _showWaiterCalls = !_showWaiterCalls;
                  });
                  if (_showWaiterCalls) {
                    _loadWaiterCalls();
                  }
                },
                tooltip: 'Waiter Calls',
              ),
              if (_waiterCalls.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_waiterCalls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _manualRefresh,
            tooltip: _lastUpdated != null
                ? 'Last updated: ${_formatTime(_lastUpdated!)}'
                : 'Refresh orders',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Pending', 'pending', Colors.orange),
                  const SizedBox(width: 8),
                  _buildFilterChip('Confirmed', 'confirmed', Colors.blue),
                  const SizedBox(width: 8),
                  _buildFilterChip('Preparing', 'preparing', Colors.purple),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ready', 'ready', Colors.green),
                ],
              ),
            ),
          ),

          // Waiter Calls Panel (shown when toggled)
          if (_showWaiterCalls) _buildWaiterCallsPanel(),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
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
                              'No ${_selectedFilter} orders',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredOrders.length,
                          cacheExtent: 200,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _selectedFilter == value;
    final count = _orders.where((o) => o.status == value).length;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? color : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getTableNumber(Order order) {
    // Try order.tableNumber first
    if (order.tableNumber != null && order.tableNumber!.isNotEmpty) {
      return order.tableNumber!;
    }
    // Fall back to tableId (safely handle short IDs)
    if (order.tableId != null && order.tableId!.isNotEmpty) {
      final id = order.tableId!;
      final displayLength = id.length < 6 ? id.length : 6;
      return 'T-${id.substring(0, displayLength)}';
    }
    return 'N/A';
  }

  Widget _buildWaiterCallsPanel() {
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Active Waiter Calls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadWaiterCalls,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_waiterCalls.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('No active waiter calls'),
                ],
              ),
            )
          else
            ..._waiterCalls.map((call) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.table_restaurant,
                          color: Colors.white),
                    ),
                    title: Text(
                      'Table ${call['tableNumber'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(call['message']?.toString() ??
                        'Customer needs assistance'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTimeAgo(_safeParseDateTime(call['createdAt'])),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final callId = call['_id']?.toString() ??
                                call['id']?.toString() ??
                                '';
                            if (callId.isNotEmpty) {
                              _acknowledgeWaiterCall(callId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid call ID'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Attend'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final timeAgo = _getTimeAgo(order.createdAt ?? DateTime.now());
    final statusColor = _getStatusColor(order.status);
    final tableNumber = _getTableNumber(order);

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 400;
                return Row(
                  children: [
                    // Table Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tableNumber,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWide ? 22 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderNumber}',
                            style: TextStyle(
                              fontSize: isWide ? 14 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (order.createdAt != null)
                            OrderTimer(
                              orderTime: order.createdAt!,
                              showFlashing: order.status != 'completed' &&
                                  order.status != 'cancelled',
                            ),
                        ],
                      ),
                    ),
                    // Status Badge - Compact
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status.substring(0, 1).toUpperCase() +
                            order.status.substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Order Items - Compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items list
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'ETB ${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                // Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ETB ${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                // Notes - compact
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.note, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          _buildActionButtons(order),
        ],
      ),
    );
  }

  ButtonStyle _getButtonStyle(Color bgColor, {bool compact = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: Colors.white,
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
          : const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      elevation: 2,
      shadowColor: bgColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      minimumSize: const Size(0, 48),
    );
  }

  Widget _buildActionButtons(Order order) {
    if (order.status == 'pending') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 350;
          final isVeryNarrow = constraints.maxWidth < 280;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border(
                top: BorderSide(color: Colors.orange[200]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Quick action chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickRejectChip(
                        order,
                        isVeryNarrow ? 'Stock' : 'Out of stock',
                        Icons.inventory_2),
                    _buildQuickRejectChip(order,
                        isVeryNarrow ? 'Busy' : 'Kitchen busy', Icons.schedule),
                    _buildQuickRejectChip(
                        order,
                        isVeryNarrow ? 'Closing' : 'Closing soon',
                        Icons.access_time),
                  ],
                ),
                const SizedBox(height: 10),
                // Action buttons row
                Row(
                  children: [
                    // Reject button
                    Expanded(
                      flex: isWide ? 1 : 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectOrder(order),
                        icon: const Icon(Icons.close, size: 20),
                        label: Text(
                          isVeryNarrow ? 'X' : (isWide ? 'REJECT' : 'NO'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: _getButtonStyle(Colors.red, compact: !isWide),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Accept button
                    Expanded(
                      flex: isWide ? 2 : 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptOrder(order),
                        icon: const Icon(Icons.check_circle, size: 22),
                        label: Text(
                          isVeryNarrow ? 'OK' : 'ACCEPT',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: _getButtonStyle(Colors.green, compact: !isWide),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } else if (order.status == 'confirmed') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border(
            top: BorderSide(color: Colors.blue[200]!, width: 1),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(order, 'preparing'),
          icon: const Icon(Icons.restaurant, size: 22),
          label: const Text(
            'START PREPARING',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: _getButtonStyle(Colors.purple),
        ),
      );
    } else if (order.status == 'preparing') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border(
            top: BorderSide(color: Colors.purple[200]!, width: 1),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(order, 'ready'),
          icon: const Icon(Icons.done_all, size: 22),
          label: const Text(
            'MARK AS READY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: _getButtonStyle(Colors.green),
        ),
      );
    } else if (order.status == 'ready') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border(
            top: BorderSide(color: Colors.green[200]!, width: 1),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () => _updateOrderStatus(order, 'completed'),
          icon: const Icon(Icons.celebration, size: 22),
          label: const Text(
            'COMPLETE ORDER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: _getButtonStyle(Colors.teal),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Quick rejection reason chip for faster workflow
  Widget _buildQuickRejectChip(Order order, String reason, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.red[700]),
      label: Text(
        reason,
        style: TextStyle(
          fontSize: 12,
          color: Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.red[50],
      side: BorderSide(color: Colors.red[200]!),
      onPressed: () => _quickRejectOrder(order, reason),
    );
  }

  /// Quick reject with predefined reason
  Future<void> _quickRejectOrder(Order order, String reason) async {
    // Show confirmation dialog with reason pre-filled
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[400], size: 28),
            const SizedBox(width: 12),
            const Text('Reject Order'),
          ],
        ),
        content:
            Text('Reject order #${order.orderNumber} with reason: "$reason"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _orderRepository.updateOrderStatus(
        order.id,
        'cancelled',
      );

      await _orderRepository.sendOrderNotification(
        orderId: order.id,
        tableId: order.tableId ?? '',
        status: 'cancelled',
        message: 'Order rejected: $reason',
        languageCode: _notificationLanguage.code,
      );

      _webSocketProvider?.emit('order:updated', {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'tableId': order.tableId,
        'status': 'cancelled',
        'message': 'Order rejected: $reason',
        'reason': reason,
        'languageCode': _notificationLanguage.code,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} rejected: $reason'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  /// Safely parse datetime from various formats
  DateTime _safeParseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      // Format: "Jan 5, 3:45 PM"
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
      final month = months[dateTime.month - 1];
      final day = dateTime.day;
      final hour = dateTime.hour > 12
          ? dateTime.hour - 12
          : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$month $day, $hour:$minute $period';
    }
  }
}
