import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../state/language/language_provider.dart';

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
      backgroundColor: AppTheme.premiumCream, // Luxury Cream background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
        title: Text(
          context.watch<LanguageProvider>().loc.yourBill,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.premiumGold),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadBill();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.premiumGold, strokeWidth: 2))
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
          Text(context.read<LanguageProvider>().loc.noActiveOrderBill, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(context.read<LanguageProvider>().loc.addItemsFirst, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Order Status Banner (Premium)
          _buildStatusBanner(status),
          const SizedBox(height: 20),

          // Items List (Elegant Receipt Style)
          _buildReceiptCard(items, subtotal, tax, totalPrice, orderNumber, tableNumber, isPaid),
          const SizedBox(height: 24),

          // Payment Methods (Interactive)
          if (!isPaid) ...[
            _buildSectionTitle('Select Payment Method'),
            const SizedBox(height: 12),
            _buildInteractivePaymentOptions(),
            const SizedBox(height: 24),
            _buildRequestBillButton(),
          ],
          
          if (isPaid) _buildPaidBadge(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildReceiptCard(List<dynamic> items, double subtotal, double tax, double total, String orderNo, String tableNo, bool isPaid) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Receipt Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ORDER ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                        Text('#$orderNo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('TABLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                        Text(tableNo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.premiumGold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Items
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Text('${item['quantity']}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.premiumGold)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('ETB ${((item['price'] ?? 0.0) as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: DottedDivider(),
                ),
                
                _buildTotalLine('Subtotal', subtotal),
                if (tax > 0) _buildTotalLine('VAT (15%)', tax),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                    Text('ETB ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.premiumGold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Text('ETB ${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _selectedMethod = 'Telebirr';

  Widget _buildInteractivePaymentOptions() {
    final methods = [
      {'id': 'Telebirr', 'name': 'Telebirr', 'icon': Icons.phone_android, 'desc': 'Scan QR to pay instantly'},
      {'id': 'CBE Birr', 'name': 'CBE Birr', 'icon': Icons.account_balance, 'desc': 'Commercial Bank of Ethiopia'},
      {'id': 'Cash', 'name': 'Cash', 'icon': Icons.payments, 'desc': 'Hand cash to the waiter'},
    ];

    return Column(
      children: methods.map((m) => _buildPaymentCard(m)).toList(),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method['id']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.premiumGold : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppTheme.premiumGold.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.premiumGold : AppTheme.premiumCream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(method['icon'] as IconData, color: isSelected ? Colors.white : AppTheme.premiumGold, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(method['desc'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: AppTheme.premiumGold),
              ],
            ),
            if (isSelected && method['id'] != 'Cash') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.premiumCream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 120, color: AppTheme.textPrimary),
                    const SizedBox(height: 8),
                    Text('Scan to Pay via ${method['name']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.premiumGold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmSelfPayment(method['name']!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.premiumGold,
                    side: const BorderSide(color: AppTheme.premiumGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('I Have Paid - Confirm'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSelfPayment(String method) async {
    // Show a confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Payment'),
        content: Text('Did you successfully pay via $method? This will notify the kitchen to verify.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.premiumGold, foregroundColor: Colors.white),
            child: const Text('Yes, I Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Notify kitchen
      try {
        await ApiService.postPublic(
          '${ApiConstants.orders}/dine-in/call-waiter',
          {
            'tableId': widget.tableId,
            'message': '💰 Customer reported payment via $method. Please verify and mark as paid.',
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment report sent! Waiter will verify shortly.')),
          );
        }
      } catch (e) {
        debugPrint('Error reporting payment: $e');
      }
    }
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
            isPaid ? '${context.read<LanguageProvider>().loc.billPaid} ✓' : context.read<LanguageProvider>().loc.yourBill,
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
        message = 'Reviewing Order';
        break;
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        message = 'Confirmed & Preparing';
        break;
      case 'preparing':
        color = Colors.purple;
        icon = Icons.restaurant;
        message = 'Cooking Your Meal';
        break;
      case 'ready':
        color = Colors.green;
        icon = Icons.done_all;
        message = 'Ready to Serve';
        break;
      case 'completed':
        color = AppTheme.premiumGold;
        icon = Icons.star;
        message = 'Paid & Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        message = 'Order Cancelled';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        message = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
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
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(context.read<LanguageProvider>().loc.orderItems, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          Row(
            children: [
              const Icon(Icons.payment, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(context.read<LanguageProvider>().loc.paymentOptions, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(Icons.phone_android, 'Telebirr', 'Pay via mobile money'),
          const SizedBox(height: 8),
          _buildPaymentOption(Icons.payments, context.read<LanguageProvider>().loc.cash, context.read<LanguageProvider>().loc.payCashWaiter),
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
          _billRequested ? context.read<LanguageProvider>().loc.waiterNotifiedBill : context.read<LanguageProvider>().loc.requestBill,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _billRequested ? Colors.green : AppTheme.premiumGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: _billRequested ? 0 : 8,
          shadowColor: AppTheme.premiumGold.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildPaidBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 20),
          Text(
            context.read<LanguageProvider>().loc.billPaid,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            context.read<LanguageProvider>().loc.thankYouDining,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class DottedDivider extends StatelessWidget {
  const DottedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}
