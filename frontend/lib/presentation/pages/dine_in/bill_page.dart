import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';

/// Bill Management Page for Dine-In
/// Shows itemized bill, totals, and allows requesting payment
class BillPage extends StatefulWidget {
  final String tableId;
  final String restaurantId;
  final String? guestSessionId;

  const BillPage({
    super.key,
    required this.tableId,
    required this.restaurantId,
    this.guestSessionId,
  });

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  bool _isRequestingBill = false;
  bool _billRequested = false;
  String? _error;
  Timer? _refreshTimer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadBill();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadBill();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBill() async {
    try {
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
        _animController.forward();
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

  Future<void> _requestBill() async {
    setState(() => _isRequestingBill = true);
    try {
      await ApiService.postPublic(
        '${ApiConstants.orders}/dine-in/call-waiter',
        {
          'tableId': widget.tableId,
          'message': '🧾 Customer is requesting the bill',
        },
      );
      if (mounted) {
        setState(() {
          _billRequested = true;
          _isRequestingBill = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Waiter notified — bill is on the way!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingBill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Your Bill',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadBill();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _orderData == null
                  ? _buildNoOrder()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildBill(),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text('Could not load bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBill,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No active order', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Place an order first to see your bill', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBill() {
    final items = (_orderData!['items'] as List<dynamic>?) ?? [];
    final totalPrice = (_orderData!['totalPrice'] ?? 0.0).toDouble();
    final subtotal = (_orderData!['subtotal'] ?? totalPrice).toDouble();
    final tax = (_orderData!['tax'] ?? 0.0).toDouble();
    final orderNumber = _orderData!['orderNumber'] ?? 'N/A';
    final tableNumber = _orderData!['tableNumber'] ?? 'N/A';
    final status = _orderData!['status'] ?? 'pending';
    final isPaid = status == 'completed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Receipt Header
          _buildReceiptHeader(orderNumber, tableNumber, isPaid),
          const SizedBox(height: 16),

          // Order Status Banner
          _buildStatusBanner(status),
          const SizedBox(height: 16),

          // Items List
          _buildItemsCard(items),
          const SizedBox(height: 16),

          // Totals Card
          _buildTotalsCard(subtotal, tax, totalPrice),
          const SizedBox(height: 24),

          // Payment Methods Info
          if (!isPaid) _buildPaymentInfo(),
          if (!isPaid) const SizedBox(height: 16),

          // Request Bill Button
          if (!isPaid) _buildRequestBillButton(),
          if (isPaid) _buildPaidBadge(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader(String orderNumber, String tableNumber, bool isPaid) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaid
              ? [Colors.green.shade600, Colors.green.shade400]
              : [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPaid ? Colors.green : AppTheme.primaryColor).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.receipt_long,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isPaid ? 'Bill Paid ✓' : 'Your Bill',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderBadge(Icons.receipt, 'Order #$orderNumber'),
              const SizedBox(width: 12),
              _buildHeaderBadge(Icons.table_restaurant, 'Table $tableNumber'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color;
    IconData icon;
    String message;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        message = 'Order is being reviewed by kitchen';
        break;
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        message = 'Order confirmed — kitchen is preparing';
        break;
      case 'preparing':
        color = Colors.purple;
        icon = Icons.restaurant;
        message = 'Your food is being prepared';
        break;
      case 'ready':
        color = Colors.green;
        icon = Icons.done_all;
        message = 'Food is ready — waiter will bring it shortly';
        break;
      case 'completed':
        color = Colors.teal;
        icon = Icons.celebration;
        message = 'Order completed — thank you!';
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        message = 'Order was cancelled';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        message = 'Status: $status';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<dynamic> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 8),
                Text('Order Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value as Map<String, dynamic>;
            final isLast = index == items.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Quantity badge
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item['quantity']}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                      // Price
                      Text(
                        'ETB ${((item['price'] ?? 0.0) as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(double subtotal, double tax, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', subtotal, isTotal: false),
          if (tax > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('VAT (15%)', tax, isTotal: false),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildTotalRow('Total', total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {required bool isTotal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimary : Colors.grey[600],
          ),
        ),
        Text(
          'ETB ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 22 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Payment Options', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(Icons.phone_android, 'Telebirr', 'Pay via mobile money'),
          const SizedBox(height: 8),
          _buildPaymentOption(Icons.payments, 'Cash', 'Pay cash to the waiter'),
          const SizedBox(height: 8),
          _buildPaymentOption(Icons.account_balance, 'CBE Birr', 'Commercial Bank of Ethiopia'),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(IconData icon, String name, String desc) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestBillButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _billRequested || _isRequestingBill ? null : _requestBill,
        icon: _isRequestingBill
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(_billRequested ? Icons.check_circle : Icons.notifications_active),
        label: Text(
          _billRequested ? 'Waiter Notified ✓' : 'Request Bill',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _billRequested ? Colors.green : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: _billRequested ? 0 : 4,
        ),
      ),
    );
  }

  Widget _buildPaidBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(height: 12),
          Text(
            'Bill Paid',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          SizedBox(height: 4),
          Text(
            'Thank you for dining with us!',
            style: TextStyle(fontSize: 14, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
