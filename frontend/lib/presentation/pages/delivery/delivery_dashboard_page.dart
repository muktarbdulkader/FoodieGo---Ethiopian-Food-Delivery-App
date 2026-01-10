import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/loading_widget.dart';

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});

  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderRepository _orderRepo = OrderRepository();

  List<Order> _myDeliveries = [];
  List<Order> _availableOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure delivery session type is set
    StorageUtils.setSessionType(SessionType.delivery);
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final myOrders = await _orderRepo.getAllOrders();
      final available = await _orderRepo.getAvailableDeliveryOrders();
      setState(() {
        _myDeliveries = myOrders;
        _availableOrders = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(Order order) async {
    try {
      await _orderRepo.acceptDeliveryOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Order accepted!'),
            backgroundColor: Color(0xFF10B981)),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateDeliveryStatus(Order order, String status) async {
    try {
      await _orderRepo.updateDeliveryStatus(order.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: const Color(0xFF10B981)),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user?.name ?? 'Delivery'),
            _buildTabs(),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyDeliveriesList(),
                        _buildAvailableOrdersList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
        boxShadow: [
          BoxShadow(color: Colors.purple.withValues(alpha: 0.3), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delivery_dining,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery Portal',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Welcome, $name',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadOrders,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/delivery', (r) => false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF8B5CF6),
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: const Color(0xFF8B5CF6),
        tabs: [
          Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_shipping, size: 16),
            const SizedBox(width: 6),
            Text('My Deliveries (${_myDeliveries.length})'),
          ])),
          Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.list_alt, size: 16),
            const SizedBox(width: 6),
            Text('Available (${_availableOrders.length})'),
          ])),
        ],
      ),
    );
  }

  Widget _buildMyDeliveriesList() {
    if (_myDeliveries.isEmpty) {
      return _buildEmptyState('No deliveries assigned', Icons.local_shipping);
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myDeliveries.length,
        itemBuilder: (context, index) =>
            _buildDeliveryCard(_myDeliveries[index], isMyDelivery: true),
      ),
    );
  }

  Widget _buildAvailableOrdersList() {
    if (_availableOrders.isEmpty) {
      return _buildEmptyState('No available orders', Icons.inbox);
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _availableOrders.length,
        itemBuilder: (context, index) =>
            _buildDeliveryCard(_availableOrders[index], isMyDelivery: false),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Order order, {required bool isMyDelivery}) {
    final hotelName =
        order.items.isNotEmpty ? order.items.first.hotelName : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store, color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(hotelName,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                        order.delivery?.trackingStatus ?? 'pending'),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (order.delivery?.trackingStatus ?? 'pending').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Order info
                Row(
                  children: [
                    Text('#${order.orderNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                        '${AppConstants.currency}${order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6))),
                  ],
                ),
                const SizedBox(height: 8),
                // Customer
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(order.userName ?? 'Customer',
                        style: const TextStyle(fontSize: 13)),
                    if (order.userPhone != null) ...[
                      const Text(' • ',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      Text(order.userPhone!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ],
                ),
                // Address
                if (order.deliveryAddress != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.deliveryAddress!.fullAddress,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Actions
                if (isMyDelivery)
                  _buildDeliveryActions(order)
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryActions(Order order) {
    final status = order.delivery?.trackingStatus ?? 'pending';

    return Row(
      children: [
        if (status == 'assigned')
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateDeliveryStatus(order, 'picked_up'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6)),
              child: const Text('Picked Up', style: TextStyle(fontSize: 12)),
            ),
          ),
        if (status == 'picked_up') ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateDeliveryStatus(order, 'on_the_way'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B)),
              child: const Text('On The Way', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
        if (status == 'on_the_way') ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateDeliveryStatus(order, 'arrived'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6)),
              child: const Text('Arrived', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
        if (status == 'arrived') ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateDeliveryStatus(order, 'delivered'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981)),
              child: const Text('Delivered ✓', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
        if (status == 'delivered')
          const Expanded(
            child: Center(
              child: Text('✅ Completed',
                  style: TextStyle(
                      color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'on_the_way':
        return const Color(0xFFF59E0B);
      case 'picked_up':
        return const Color(0xFF3B82F6);
      case 'arrived':
        return const Color(0xFF8B5CF6);
      case 'assigned':
        return const Color(0xFF06B6D4);
      default:
        return AppTheme.textSecondary;
    }
  }
}
