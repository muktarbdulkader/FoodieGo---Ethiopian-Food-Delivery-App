import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/admin/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../widgets/loading_widget.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'all';
  bool _groupByHotel = true;
  final Set<String> _expandedOrders = {};

  final List<Map<String, dynamic>> _statusFilters = [
    {'id': 'all', 'label': 'All', 'icon': Icons.list_alt},
    {'id': 'pending', 'label': 'Pending', 'icon': Icons.pending_actions},
    {
      'id': 'confirmed',
      'label': 'Confirmed',
      'icon': Icons.check_circle_outline
    },
    {'id': 'preparing', 'label': 'Preparing', 'icon': Icons.restaurant},
    {
      'id': 'out_for_delivery',
      'label': 'Delivery',
      'icon': Icons.delivery_dining
    },
    {'id': 'delivered', 'label': 'Done', 'icon': Icons.done_all},
  ];

  @override
  void initState() {
    super.initState();
    // Ensure admin session type is set
    StorageUtils.setSessionType(SessionType.admin);

    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(() {
      setState(
          () => _filterStatus = _statusFilters[_tabController.index]['id']);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_filterStatus == 'all') return orders;
    return orders.where((o) => o.status == _filterStatus).toList();
  }

  // Group orders by hotel name
  Map<String, List<Order>> _groupOrdersByHotel(List<Order> orders) {
    final Map<String, List<Order>> grouped = {};
    for (final order in orders) {
      // Get hotel name from first item, or 'Other' if not available
      final hotelName =
          order.items.isNotEmpty && order.items.first.hotelName.isNotEmpty
              ? order.items.first.hotelName
              : 'Other Orders';
      grouped.putIfAbsent(hotelName, () => []).add(order);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusTabs(),
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, admin, _) {
                  if (admin.isLoading) return const LoadingWidget();
                  final filteredOrders = _getFilteredOrders(admin.allOrders);
                  if (filteredOrders.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () => admin.fetchAllOrders(),
                    child: _groupByHotel
                        ? _buildGroupedOrdersList(filteredOrders)
                        : _buildFlatOrdersList(filteredOrders),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Orders',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Manage all orders',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Group toggle
          GestureDetector(
            onTap: () => setState(() => _groupByHotel = !_groupByHotel),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _groupByHotel
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _groupByHotel ? Icons.store : Icons.list,
                    size: 16,
                    color: _groupByHotel
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _groupByHotel ? 'By Hotel' : 'All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _groupByHotel
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<AdminProvider>(
            builder: (context, admin, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${admin.allOrders.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: _statusFilters
            .map((f) => Tab(
                  child: Row(
                    children: [
                      Icon(f['icon'], size: 14),
                      const SizedBox(width: 4),
                      Text(f['label']),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long,
                size: 40, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          const Text('No orders found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Orders with "$_filterStatus" status will appear here',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  // Grouped orders list by hotel
  Widget _buildGroupedOrdersList(List<Order> orders) {
    final grouped = _groupOrdersByHotel(orders);
    final hotelNames = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: hotelNames.length,
      itemBuilder: (context, index) {
        final hotelName = hotelNames[index];
        final hotelOrders = grouped[hotelName]!;
        return _buildHotelSection(hotelName, hotelOrders);
      },
    );
  }

  // Flat orders list
  Widget _buildFlatOrdersList(List<Order> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildCompactOrderCard(orders[index]),
    );
  }

  // Hotel section with orders
  Widget _buildHotelSection(String hotelName, List<Order> orders) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Hotel header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryColor.withValues(alpha: 0.05)
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store,
                      color: AppTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hotelName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length} orders',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Orders list
          ...orders
              .map((order) => _buildCompactOrderCard(order, showHotel: false)),
        ],
      ),
    );
  }

  // Compact order card with expandable user info
  Widget _buildCompactOrderCard(Order order, {bool showHotel = true}) {
    final isExpanded = _expandedOrders.contains(order.id);
    final hotelName =
        order.items.isNotEmpty && order.items.first.hotelName.isNotEmpty
            ? order.items.first.hotelName
            : null;

    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: const Color(0xFFF1F5F9), width: showHotel ? 0 : 1)),
      ),
      child: Column(
        children: [
          // Main order info row
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedOrders.remove(order.id);
              } else {
                _expandedOrders.add(order.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getStatusIcon(order.status),
                        color: _getStatusColor(order.status), size: 18),
                  ),
                  const SizedBox(width: 10),
                  // Order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(order.id.length - 6).toUpperCase()}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.status.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              order.userName ?? 'Customer',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            if (showHotel && hotelName != null) ...[
                              const Text(' • ',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                              Icon(Icons.store_outlined,
                                  size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  hotelName,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Price and items count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppConstants.currency}${order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.primaryColor),
                      ),
                      Text(
                        '${order.items.length} items',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (isExpanded) _buildExpandedDetails(order),
        ],
      ),
    );
  }

  // Expanded order details section
  Widget _buildExpandedDetails(Order order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          // User info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Customer row
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          (order.userName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.userName ?? 'Customer',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          if (order.userPhone != null)
                            Text(order.userPhone!,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                    // Contact buttons
                    _buildMiniContactButton(
                        Icons.phone,
                        const Color(0xFF10B981),
                        () => _showContactDialog(order, 'phone')),
                    const SizedBox(width: 6),
                    _buildMiniContactButton(
                        Icons.message,
                        const Color(0xFF3B82F6),
                        () => _showContactDialog(order, 'message')),
                  ],
                ),
                // Address if available
                if (order.deliveryAddress != null) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Order items summary
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${item.quantity}x',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(item.name,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis)),
                          Text(
                              '${AppConstants.currency}${item.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
                if (order.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+${order.items.length - 3} more items',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Payment & Status row
          Row(
            children: [
              // Payment info
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getPaymentColor(order.payment?.method ?? 'cash')
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(_getPaymentEmoji(order.payment?.method ?? 'cash'),
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _getPaymentName(
                                    order.payment?.method ?? 'cash'),
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            Text(
                              (order.payment?.status ?? 'pending')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                color: order.payment?.status == 'paid'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status dropdown
              _buildCompactStatusDropdown(order),
            ],
          ),
          const SizedBox(height: 10),
          // Delivery tracking section (if driver assigned)
          if (order.delivery?.driverName != null &&
              order.delivery!.driverName!.isNotEmpty) ...[
            _buildDeliveryTrackingSection(order),
            const SizedBox(height: 10),
          ],
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showOrderDetails(order),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text('Details', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _printOrder(order),
                  icon: const Icon(Icons.print, size: 14),
                  label: const Text('Print', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              GestureDetector(
                onTap: () => _confirmDeleteOrder(order),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFFEF4444)),
                ),
              ),
              if (order.delivery?.type == 'delivery' &&
                  (order.delivery?.driverName == null ||
                      order.delivery!.driverName!.isEmpty)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAssignDriverDialog(order),
                    icon: const Icon(Icons.delivery_dining, size: 14),
                    label: const Text('Driver', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTrackingSection(Order order) {
    final trackingStatus = order.delivery?.trackingStatus ?? 'assigned';
    final driverName = order.delivery?.driverName ?? 'Unknown';
    final driverPhone = order.delivery?.driverPhone ?? '';

    // Define tracking steps
    final steps = [
      {'id': 'assigned', 'label': 'Assigned', 'icon': Icons.person_pin},
      {'id': 'picked_up', 'label': 'Picked Up', 'icon': Icons.inventory_2},
      {
        'id': 'on_the_way',
        'label': 'On The Way',
        'icon': Icons.delivery_dining
      },
      {'id': 'arrived', 'label': 'Arrived', 'icon': Icons.location_on},
      {'id': 'delivered', 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    int currentStepIndex = steps.indexWhere((s) => s['id'] == trackingStatus);
    if (currentStepIndex == -1) {
      currentStepIndex = 0;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delivery_dining,
                    color: Color(0xFF8B5CF6), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Driver',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                    Text(driverName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              if (driverPhone.isNotEmpty)
                GestureDetector(
                  onTap: () => _showContactDialog(order, 'phone'),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone,
                        color: Color(0xFF10B981), size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Tracking progress
          Row(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isCompleted = index <= currentStepIndex;
              final isCurrent = index == currentStepIndex;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                              border: isCurrent
                                  ? Border.all(
                                      color: const Color(0xFF8B5CF6), width: 2)
                                  : null,
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              size: 14,
                              color: isCompleted ? Colors.white : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['label'] as String,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCompleted
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          color: index < currentStepIndex
                              ? const Color(0xFF8B5CF6)
                              : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          // Current status message
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getTrackingStatusColor(trackingStatus)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTrackingStatusIcon(trackingStatus),
                  size: 14,
                  color: _getTrackingStatusColor(trackingStatus),
                ),
                const SizedBox(width: 6),
                Text(
                  _getTrackingStatusMessage(trackingStatus),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getTrackingStatusColor(trackingStatus),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrackingStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'arrived':
        return const Color(0xFF8B5CF6);
      case 'on_the_way':
        return const Color(0xFFF59E0B);
      case 'picked_up':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _getTrackingStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'arrived':
        return Icons.location_on;
      case 'on_the_way':
        return Icons.delivery_dining;
      case 'picked_up':
        return Icons.inventory_2;
      default:
        return Icons.person_pin;
    }
  }

  String _getTrackingStatusMessage(String status) {
    switch (status) {
      case 'delivered':
        return 'Order has been delivered! ✅';
      case 'arrived':
        return 'Driver has arrived at destination';
      case 'on_the_way':
        return 'Driver is on the way to customer';
      case 'picked_up':
        return 'Driver picked up the order';
      default:
        return 'Driver assigned, waiting for pickup';
    }
  }

  Widget _buildMiniContactButton(
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }

  Widget _buildCompactStatusDropdown(Order order) {
    final statuses = [
      'pending',
      'confirmed',
      'preparing',
      'ready',
      'out_for_delivery',
      'delivered',
      'cancelled'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(order.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: _getStatusColor(order.status).withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: order.status,
        underline: const SizedBox(),
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down,
            color: _getStatusColor(order.status), size: 16),
        style: TextStyle(
            color: _getStatusColor(order.status),
            fontWeight: FontWeight.bold,
            fontSize: 10),
        items: statuses
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(s),
                          size: 12, color: _getStatusColor(s)),
                      const SizedBox(width: 4),
                      Text(s.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                              fontSize: 10, color: _getStatusColor(s))),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (newStatus) async {
          if (newStatus != null && newStatus != order.status) {
            await context
                .read<AdminProvider>()
                .updateOrderStatus(order.id, newStatus);
          }
        },
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'preparing':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'ready':
        return const Color(0xFF8B5CF6);
      case 'out_for_delivery':
        return const Color(0xFF06B6D4);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'cancelled':
        return Icons.cancel;
      case 'confirmed':
        return Icons.thumb_up;
      case 'ready':
        return Icons.done;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      default:
        return Icons.pending;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method) {
      case 'telebirr':
        return const Color(0xFF00A651);
      case 'mpesa':
        return const Color(0xFFE60000);
      case 'cbe_birr':
        return const Color(0xFF1E3A8A);
      case 'card':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF059669);
    }
  }

  String _getPaymentEmoji(String method) {
    switch (method) {
      case 'telebirr':
        return '🟢';
      case 'mpesa':
        return '🔴';
      case 'cbe_birr':
        return '🔵';
      case 'card':
        return '💳';
      default:
        return '💵';
    }
  }

  String _getPaymentName(String method) {
    switch (method) {
      case 'telebirr':
        return 'Telebirr';
      case 'mpesa':
        return 'M-Pesa';
      case 'cbe_birr':
        return 'CBE Birr';
      case 'card':
        return 'Card';
      default:
        return 'Cash';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Dialog methods
  void _showContactDialog(Order order, String type) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(type == 'phone' ? Icons.phone : Icons.message,
                color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(type == 'phone' ? 'Call' : 'Message',
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.userName ?? 'Customer',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (order.userPhone != null) ...[
              const SizedBox(height: 4),
              Text('📞 ${order.userPhone}',
                  style: const TextStyle(fontSize: 14)),
            ],
            if (order.userEmail != null) ...[
              const SizedBox(height: 4),
              Text('📧 ${order.userEmail}',
                  style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAssignDriverDialog(Order order) {
    final adminProvider = context.read<AdminProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final adminRepo = AdminRepository();

    showDialog(
      context: context,
      builder: (dialogContext) => FutureBuilder<List<Map<String, dynamic>>>(
        future: adminRepo.getDeliveryUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              content: const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final deliveryUsers = snapshot.data ?? [];
          Map<String, dynamic>? selectedDriver;

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.delivery_dining,
                      color: Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text('Assign Driver', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deliveryUsers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Color(0xFFF59E0B), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No delivery users registered. Please register delivery personnel first.',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const Text('Select Driver',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedDriver,
                        hint: const Text('Choose a driver'),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: deliveryUsers.map((driver) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: driver,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (driver['name'] ?? 'D')[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        driver['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                      ),
                                      if (driver['phone'] != null)
                                        Text(
                                          driver['phone'],
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedDriver = value);
                        },
                      ),
                    ),
                    if (selectedDriver != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF22C55E), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedDriver!['name'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    selectedDriver!['phone'] ?? '',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                if (deliveryUsers.isNotEmpty)
                  ElevatedButton(
                    onPressed: selectedDriver == null
                        ? null
                        : () async {
                            Navigator.pop(dialogContext);
                            await adminProvider.assignDriver(
                              order.id,
                              selectedDriver!['name'] ?? '',
                              selectedDriver!['phone'] ?? '',
                            );
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Driver ${selectedDriver!['name']} assigned!'),
                                backgroundColor: const Color(0xFF8B5CF6),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                    child: const Text('Assign'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _printOrder(Order order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Printing order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(order.id.length - 6)}...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Order Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close, size: 20)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Order Info', [
                      _buildDetailRow(
                          'Order #',
                          order.orderNumber.isNotEmpty
                              ? order.orderNumber
                              : order.id.substring(order.id.length - 8)),
                      _buildDetailRow('Status',
                          order.status.toUpperCase().replaceAll('_', ' ')),
                      _buildDetailRow('Date', _formatDate(order.createdAt)),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailSection('Customer', [
                      _buildDetailRow('Name', order.userName ?? 'Unknown'),
                      if (order.userEmail != null)
                        _buildDetailRow('Email', order.userEmail!),
                      if (order.userPhone != null)
                        _buildDetailRow('Phone', order.userPhone!),
                    ]),
                    if (order.deliveryAddress != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection('Delivery', [
                        _buildDetailRow(
                            'Address', order.deliveryAddress!.fullAddress),
                        if (order.deliveryAddress!.city != null)
                          _buildDetailRow('City', order.deliveryAddress!.city!),
                        if (order.deliveryAddress!.instructions != null)
                          _buildDetailRow(
                              'Note', order.deliveryAddress!.instructions!),
                      ]),
                    ],
                    const SizedBox(height: 16),
                    _buildDetailSection(
                        'Items',
                        order.items
                            .map((item) => _buildDetailRow(
                                '${item.quantity}x ${item.name}',
                                '${AppConstants.currency}${item.total.toStringAsFixed(2)}'))
                            .toList()),
                    const SizedBox(height: 16),
                    _buildDetailSection('Payment', [
                      _buildDetailRow('Method',
                          _getPaymentName(order.payment?.method ?? 'cash')),
                      _buildDetailRow('Status',
                          (order.payment?.status ?? 'pending').toUpperCase()),
                      _buildDetailRow('Subtotal',
                          '${AppConstants.currency}${order.subtotal.toStringAsFixed(2)}'),
                      _buildDetailRow('Delivery',
                          '${AppConstants.currency}${order.deliveryFee.toStringAsFixed(2)}'),
                      _buildDetailRow('Tax',
                          '${AppConstants.currency}${order.tax.toStringAsFixed(2)}'),
                      _buildDetailRow('Total',
                          '${AppConstants.currency}${order.totalPrice.toStringAsFixed(2)}'),
                    ]),
                    if (order.delivery != null &&
                        order.delivery!.driverName != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection('Driver', [
                        _buildDetailRow('Name', order.delivery!.driverName!),
                        if (order.delivery!.driverPhone != null)
                          _buildDetailRow(
                              'Phone', order.delivery!.driverPhone!),
                        _buildDetailRow(
                            'Status',
                            order.delivery!.trackingStatus
                                .toUpperCase()
                                .replaceAll('_', ' ')),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 12))),
        ],
      ),
    );
  }

  void _confirmDeleteOrder(Order order) async {
    final adminProvider = context.read<AdminProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 8),
            Text('Delete Order', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(order.id.length - 6)}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await adminProvider.deleteOrder(order.id);
      _expandedOrders.remove(order.id);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Order deleted' : 'Failed to delete order'),
          backgroundColor:
              success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
    }
  }
}
