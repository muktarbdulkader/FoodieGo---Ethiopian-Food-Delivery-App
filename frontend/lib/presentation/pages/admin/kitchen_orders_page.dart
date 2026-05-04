import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/websocket/websocket_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../widgets/connection_status_indicator.dart';

class KitchenOrdersPage extends StatefulWidget {
  const KitchenOrdersPage({super.key});

  @override
  State<KitchenOrdersPage> createState() => _KitchenOrdersPageState();
}

class _KitchenOrdersPageState extends State<KitchenOrdersPage> {
  final OrderRepository _orderRepository = OrderRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Order> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending'; // pending, confirmed, preparing, ready
  WebSocketProvider? _webSocketProvider;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    
    // Setup WebSocket listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWebSocket();
    });
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

  Future<void> _loadOrders() async {
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
        });
      }
    } catch (e) {
      debugPrint('Error loading kitchen orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Order> get _filteredOrders {
    return _orders.where((order) => order.status == _selectedFilter).toList();
  }

  Future<void> _acceptOrder(Order order) async {
    try {
      await _orderRepository.updateOrderStatus(
        order.id,
        'confirmed',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.orderNumber} accepted'),
          backgroundColor: Colors.green,
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrder(Order order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order?'),
        content: Text('Are you sure you want to reject order #${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.orderNumber} rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await _orderRepository.updateOrderStatus(
        order.id,
        newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.orderNumber} updated to $newStatus'),
          backgroundColor: Colors.blue,
        ),
      );

      _loadOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
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
          const ConnectionStatusIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
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
      selectedColor: color.withOpacity(0.2),
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
              color: statusColor.withOpacity(0.1),
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
                              color: AppTheme.primaryColor.withOpacity(0.1),
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
                label: const Text('Reject'),
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
                label: const Text('Accept Order'),
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
            label: const Text('Start Preparing'),
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
            label: const Text('Mark as Ready'),
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
            const Expanded(
              child: Text(
                'Ready for serving',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order, 'completed'),
              child: const Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
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
