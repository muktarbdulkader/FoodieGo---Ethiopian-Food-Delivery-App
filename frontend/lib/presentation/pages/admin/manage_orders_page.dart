import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/admin/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/order.dart';
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
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) =>
                          _buildOrderCard(filteredOrders[index]),
                    ),
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
      padding: const EdgeInsets.all(20),
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
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Management',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Track and manage all orders',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Consumer<AdminProvider>(
            builder: (context, admin, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text('${admin.allOrders.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                ],
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: _statusFilters
            .map((f) => Tab(
                  child: Row(
                    children: [
                      Icon(f['icon'], size: 16),
                      const SizedBox(width: 6),
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
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long,
                size: 48, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text('No orders found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Orders with "$_filterStatus" status will appear here',
              style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header with order number and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(order.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getStatusIcon(order.status),
                      color: _getStatusColor(order.status), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '#${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(order.id.length - 6).toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_formatDate(order.createdAt),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                _buildStatusDropdown(order),
              ],
            ),
          ),

          // Customer Info Section
          _buildCustomerSection(order),

          // Delivery Address Section
          if (order.deliveryAddress != null) _buildAddressSection(order),

          // Order Items
          _buildItemsSection(order),

          // Payment Info
          _buildPaymentSection(order),

          // Delivery/Driver Section
          if (order.delivery?.type == 'delivery') _buildDeliverySection(order),

          // Action Buttons
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (order.userName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(order.userName ?? 'Customer',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
                if (order.userEmail != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(order.userEmail!,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                if (order.userPhone != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(order.userPhone!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Contact buttons
          Row(
            children: [
              _buildContactButton(Icons.phone, const Color(0xFF10B981),
                  () => _showContactDialog(order, 'phone')),
              const SizedBox(width: 8),
              _buildContactButton(Icons.message, const Color(0xFF3B82F6),
                  () => _showContactDialog(order, 'message')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildAddressSection(Order order) {
    final address = order.deliveryAddress!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on,
                    color: Color(0xFFEF4444), size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(_getAddressIcon(address.label),
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(address.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.fullAddress,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (address.street != null && address.street!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.signpost,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                          '${address.street}${address.city != null ? ", ${address.city}" : ""}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
                if (address.instructions != null &&
                    address.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(address.instructions!,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFD97706)))),
                      ],
                    ),
                  ),
                ],
                // Map button
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openMap(address),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, size: 16, color: Color(0xFF3B82F6)),
                        SizedBox(width: 6),
                        Text('View on Map',
                            style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
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

  Widget _buildItemsSection(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.restaurant_menu,
                    color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Order Items (${order.items.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                          child: Text('${item.quantity}x',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  fontSize: 12))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500))),
                    Text(
                        '${AppConstants.currency}${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 20),
          _buildPriceRow('Subtotal', order.subtotal),
          _buildPriceRow('Delivery Fee', order.deliveryFee),
          _buildPriceRow('Tax (15%)', order.tax),
          if (order.tip > 0) _buildPriceRow('Tip', order.tip),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, Color(0xFFFF8A5C)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                    '${AppConstants.currency}${order.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text('${AppConstants.currency}${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Order order) {
    final payment = order.payment;
    final paymentMethod = payment?.method ?? 'cash';
    final paymentStatus = payment?.status ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color:
                        _getPaymentColor(paymentMethod).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(_getPaymentIcon(paymentMethod),
                    color: _getPaymentColor(paymentMethod), size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Payment',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              _buildPaymentStatusBadge(paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Text(_getPaymentEmoji(paymentMethod),
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getPaymentName(paymentMethod),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (payment?.transactionId != null)
                        Text('TXN: ${payment!.transactionId}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (paymentStatus == 'pending')
                  ElevatedButton.icon(
                    onPressed: () => _confirmPayment(order),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    final color = status == 'paid'
        ? const Color(0xFF10B981)
        : status == 'failed'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(
              status == 'paid'
                  ? Icons.check_circle
                  : status == 'failed'
                      ? Icons.cancel
                      : Icons.schedule,
              size: 14,
              color: color),
          const SizedBox(width: 4),
          Text(status.toUpperCase(),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(Order order) {
    final delivery = order.delivery!;
    final hasDriver =
        delivery.driverName != null && delivery.driverName!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delivery_dining,
                    color: Color(0xFF8B5CF6), size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Delivery',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDeliveryStatusColor(delivery.trackingStatus)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    delivery.trackingStatus.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                        color: _getDeliveryStatusColor(delivery.trackingStatus),
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Delivery info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text('Est. ${delivery.estimatedTime} min',
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.attach_money,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                        'Fee: ${AppConstants.currency}${delivery.fee.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
                if (hasDriver) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF34D399)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Driver Assigned',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                            Text(delivery.driverName!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15)),
                            if (delivery.driverPhone != null)
                              Text(delivery.driverPhone!,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                          ],
                        ),
                      ),
                      _buildContactButton(
                          Icons.phone, const Color(0xFF10B981), () {}),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignDriverDialog(order),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Assign Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _printOrder(order),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showOrderDetails(order),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(Order order) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(order.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _getStatusColor(order.status).withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: order.status,
        underline: const SizedBox(),
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down,
            color: _getStatusColor(order.status), size: 18),
        style: TextStyle(
            color: _getStatusColor(order.status),
            fontWeight: FontWeight.bold,
            fontSize: 11),
        items: statuses
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(s),
                          size: 14, color: _getStatusColor(s)),
                      const SizedBox(width: 6),
                      Text(s.toUpperCase().replaceAll('_', ' ')),
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

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'on_the_way':
        return const Color(0xFF3B82F6);
      case 'picked_up':
        return const Color(0xFF8B5CF6);
      case 'assigned':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      default:
        return Icons.place;
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

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'telebirr':
        return Icons.phone_android;
      case 'mpesa':
        return Icons.phone_iphone;
      case 'cbe_birr':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payments;
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
        return 'Credit/Debit Card';
      default:
        return 'Cash on Delivery';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(type == 'phone' ? Icons.phone : Icons.message,
                color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text(type == 'phone' ? 'Call Customer' : 'Message Customer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customer: ${order.userName ?? "Unknown"}'),
            if (order.userPhone != null) ...[
              const SizedBox(height: 8),
              Text('Phone: ${order.userPhone}'),
            ],
            if (order.userEmail != null) ...[
              const SizedBox(height: 4),
              Text('Email: ${order.userEmail}'),
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

  void _openMap(DeliveryAddress address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening map for: ${address.fullAddress}'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  void _confirmPayment(Order order) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('Confirm Payment'),
          ],
        ),
        content: Text(
            'Mark payment as received for order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(order.id.length - 6)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update payment status via admin provider
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('Payment confirmed!'),
            backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  void _showAssignDriverDialog(Order order) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final adminProvider = context.read<AdminProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delivery_dining, color: Color(0xFF8B5CF6)),
            SizedBox(width: 10),
            Text('Assign Driver'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Driver Name',
                prefixIcon: const Icon(Icons.person),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Driver Phone',
                prefixIcon: const Icon(Icons.phone),
                hintText: '+251 9XX XXX XXX',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                await adminProvider.assignDriver(
                  order.id,
                  nameController.text,
                  phoneController.text,
                );
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                      content: Text('Driver assigned successfully!'),
                      backgroundColor: Color(0xFF8B5CF6)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Assign'),
          ),
        ],
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
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('Order Details',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Order Info', [
                      _buildDetailRow(
                          'Order Number',
                          order.orderNumber.isNotEmpty
                              ? order.orderNumber
                              : order.id),
                      _buildDetailRow('Status', order.status.toUpperCase()),
                      _buildDetailRow('Created', _formatDate(order.createdAt)),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Customer', [
                      _buildDetailRow('Name', order.userName ?? 'Unknown'),
                      if (order.userEmail != null)
                        _buildDetailRow('Email', order.userEmail!),
                      if (order.userPhone != null)
                        _buildDetailRow('Phone', order.userPhone!),
                    ]),
                    if (order.deliveryAddress != null) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Delivery Address', [
                        _buildDetailRow('Label', order.deliveryAddress!.label),
                        _buildDetailRow(
                            'Address', order.deliveryAddress!.fullAddress),
                        if (order.deliveryAddress!.city != null)
                          _buildDetailRow('City', order.deliveryAddress!.city!),
                        if (order.deliveryAddress!.instructions != null)
                          _buildDetailRow('Instructions',
                              order.deliveryAddress!.instructions!),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    _buildDetailSection('Payment', [
                      _buildDetailRow('Method',
                          _getPaymentName(order.payment?.method ?? 'cash')),
                      _buildDetailRow('Status',
                          (order.payment?.status ?? 'pending').toUpperCase()),
                      if (order.payment?.transactionId != null)
                        _buildDetailRow(
                            'Transaction ID', order.payment!.transactionId!),
                    ]),
                    if (order.delivery != null) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Delivery', [
                        _buildDetailRow(
                            'Type', order.delivery!.type.toUpperCase()),
                        _buildDetailRow('Fee',
                            '${AppConstants.currency}${order.delivery!.fee.toStringAsFixed(2)}'),
                        _buildDetailRow('Est. Time',
                            '${order.delivery!.estimatedTime} min'),
                        _buildDetailRow('Status',
                            order.delivery!.trackingStatus.toUpperCase()),
                        if (order.delivery!.driverName != null)
                          _buildDetailRow(
                              'Driver', order.delivery!.driverName!),
                        if (order.delivery!.driverPhone != null)
                          _buildDetailRow(
                              'Driver Phone', order.delivery!.driverPhone!),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
