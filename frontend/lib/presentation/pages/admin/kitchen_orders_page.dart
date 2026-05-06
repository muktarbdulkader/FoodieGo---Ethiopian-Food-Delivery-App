import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/kitchen_localizations.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Order> _orders = [];
  List<Map<String, dynamic>> _waiterCalls = []; // Pending waiter calls
  bool _isLoading = true;
  bool _isRefreshing = false; // Track manual refresh state
  bool _showWaiterCalls = false; // Toggle to show waiter calls panel
  String _selectedFilter = 'pending'; // pending, confirmed, preparing, ready
  String _currentLanguage = 'en'; // Language for notifications (en, am, om)
  WebSocketProvider? _webSocketProvider;
  String? _restaurantId;
  Timer? _refreshTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadWaiterCalls();
    
    // Setup WebSocket listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWebSocket();
    });
    
    // Auto-refresh every 10 seconds as backup
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadOrders();
        _loadWaiterCalls();
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
      // Join kitchen room
      final roomName = 'kitchen:$_restaurantId';
      _webSocketProvider!.joinRoom(roomName);
      
      // Listen for order events
      _webSocketProvider!.on('order:created', _handleNewOrder);
      _webSocketProvider!.on('order:updated', _handleOrderUpdate);
      _webSocketProvider!.on('waiter:called', _handleWaiterCall);
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
          content: Text('New order #${data['orderNumber']} - Table ${data['tableNumber']}'),
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
    
    // Play bell sound
    _playWaiterCallSound();
    
    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Text('Table ${data['tableNumber']}'),
            ],
          ),
          content: Text(data['message'] ?? 'Customer needs assistance'),
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
  
  Future<void> _playNewOrderSound() async {
    try {
      // Play a notification sound (you can add custom sound files to assets)
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('[KITCHEN] Error playing sound: $e');
    }
  }
  
  Future<void> _playWaiterCallSound() async {
    try {
      // Play a bell sound
      await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (e) {
      debugPrint('[KITCHEN] Error playing sound: $e');
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    _refreshTimer?.cancel();
    
    // Leave room and remove listeners
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
      final dineInOrders = orders.where((order) => 
        order.type == 'dine_in'
      ).toList();
      
      // Sort by creation time (newest first)
      dineInOrders.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.now();
        final bTime = b.createdAt ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _orders = dineInOrders;
          _isLoading = false;
          _isRefreshing = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error loading kitchen orders: $e');
      
      // Retry logic for timeout errors (backend sleeping on Render free tier)
      if (e.toString().contains('timed out') && retryCount < maxRetries) {
        debugPrint('Retrying... Attempt ${retryCount + 1}/$maxRetries');
        
        if (mounted) {
          // Show retry message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server is waking up... Retry ${retryCount + 1}/$maxRetries'),
              backgroundColor: Colors.orange,
              duration: retryDelay,
            ),
          );
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay);
        
        // Retry
        return _loadOrders(retryCount: retryCount + 1);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().contains('timed out') ? 'Server is sleeping. Please wait and try again.' : e.toString()}'),
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

  KitchenLocalizations get _loc => KitchenLocalizations(_currentLanguage);
  
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
            ...KitchenLocalizations.supportedLanguages.map((code) => ListTile(
              leading: Radio<String>(
                value: code,
                groupValue: _currentLanguage,
                onChanged: (value) {
                  setState(() {
                    _currentLanguage = value!;
                  });
                  Navigator.pop(ctx);
                },
              ),
              title: Text(KitchenLocalizations.getLanguageName(code)),
              onTap: () {
                setState(() {
                  _currentLanguage = code;
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
          content: Text('${_loc.get('order_accepted')} - #${order.orderNumber}'),
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
      _orderRepository.sendOrderNotification(
        orderId: order.id,
        tableId: order.tableId ?? '',
        status: 'confirmed',
        message: _loc.get('order_accepted'),
        languageCode: _currentLanguage,
      ).catchError((e) => debugPrint('Notification error: $e'));

      // Emit WebSocket event for real-time update
      _webSocketProvider?.emit('order:updated', {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'tableId': order.tableId,
        'status': 'confirmed',
        'message': _loc.get('order_accepted'),
        'languageCode': _currentLanguage,
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
        languageCode: _currentLanguage,
      );

      // Emit WebSocket event
      _webSocketProvider?.emit('order:updated', {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'tableId': order.tableId,
        'status': 'cancelled',
        'message': _loc.get('order_rejected'),
        'reason': reasonController.text,
        'languageCode': _currentLanguage,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_loc.get('order_rejected')} - #${order.orderNumber}'),
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
        languageCode: _currentLanguage,
      );

      // Emit WebSocket event
      _webSocketProvider?.emit('order:updated', {
        'orderId': order.id,
        'orderNumber': order.orderNumber,
        'tableId': order.tableId,
        'status': newStatus,
        'message': statusMessage,
        'languageCode': _currentLanguage,
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
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _currentLanguage.toUpperCase(),
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
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
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
    // Fall back to tableId
    if (order.tableId != null) {
      return 'T-${order.tableId!.substring(0, 6)}';
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
                  child: const Icon(Icons.table_restaurant, color: Colors.white),
                ),
                title: Text(
                  'Table ${call['tableNumber'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(call['message'] ?? 'Customer needs assistance'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTimeAgo(DateTime.parse(call['createdAt'] ?? DateTime.now().toIso8601String())),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _acknowledgeWaiterCall(call['_id'] ?? call['id'] ?? ''),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                // Table Number - Large and prominent
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tableNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Order Timer
                      if (order.createdAt != null)
                        OrderTimer(
                          orderTime: order.createdAt!,
                          showFlashing: order.status != 'completed' && order.status != 'cancelled',
                        ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantity}x',
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
                              item.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Text(
                            'ETB ${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
                      'ETB ${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.note, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: const TextStyle(fontSize: 14),
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

  Widget _buildActionButtons(Order order) {
    if (order.status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rejectOrder(order),
                icon: const Icon(Icons.close),
                label: Text(_loc.get('reject_order')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(order),
                icon: const Icon(Icons.check),
                label: Text(_loc.get('accept_order')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (order.status == 'confirmed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, 'preparing'),
            icon: const Icon(Icons.restaurant),
            label: Text(_loc.get('start_preparing')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    } else if (order.status == 'preparing') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, 'ready'),
            icon: const Icon(Icons.done_all),
            label: Text(_loc.get('mark_ready')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    } else if (order.status == 'ready') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _loc.get('order_ready'),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order, 'completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_loc.get('complete')),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dateTime.month - 1];
      final day = dateTime.day;
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$month $day, $hour:$minute $period';
    }
  }
}
