import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/admin/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/storage_utils.dart';
import '../../widgets/loading_widget.dart';

class ManagePaymentsPage extends StatefulWidget {
  const ManagePaymentsPage({super.key});

  @override
  State<ManagePaymentsPage> createState() => _ManagePaymentsPageState();
}

class _ManagePaymentsPageState extends State<ManagePaymentsPage> {
  @override
  void initState() {
    super.initState();
    // Ensure admin session type is set
    StorageUtils.setSessionType(SessionType.admin);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, admin, _) {
                  if (admin.isLoading) {
                    return const LoadingWidget(message: 'Loading payments...');
                  }
                  return RefreshIndicator(
                    onRefresh: () => admin.fetchPayments(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPaymentStats(admin.paymentStats),
                          const SizedBox(height: 24),
                          const Text('Recent Transactions',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ...admin.transactions
                              .where((t) => t['status'] != 'cancelled') // Filter out cancelled orders
                              .map((t) => _buildTransactionCard(t, admin)),
                        ],
                      ),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.cardShadow),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payments',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Manage transactions',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStats(List<Map<String, dynamic>> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: stats
                .map((s) => _buildStatItem(
                      _getPaymentMethodName(s['_id']),
                      '${AppConstants.currency}${(s['total'] ?? 0).toStringAsFixed(2)}',
                      '${s['count'] ?? 0} orders',
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subtitle) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  String _getPaymentMethodName(String? method) {
    switch (method) {
      case 'card':
        return 'Card';
      case 'telebirr':
        return 'Telebirr';
      case 'mpesa':
        return 'M-Pesa';
      case 'cbe_birr':
        return 'CBE Birr';
      case 'cash':
        return 'Cash';
      default:
        return method ?? 'Unknown';
    }
  }

  Widget _buildTransactionCard(
      Map<String, dynamic> transaction, AdminProvider admin) {
    final payment = transaction['payment'] as Map<String, dynamic>? ?? {};
    final user = transaction['user'] as Map<String, dynamic>? ?? {};
    final status = payment['status'] ?? 'pending';
    final isPaid = status == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${transaction['orderNumber'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPaid
                          ? AppTheme.successColor
                          : AppTheme.warningColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(_getPaymentIcon(payment['method']),
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(_getPaymentMethodName(payment['method']),
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text(
                  '${AppConstants.currency}${(transaction['totalPrice'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transaction['type'] == 'dine_in'
                ? 'Table ${transaction['tableNumber'] ?? transaction['tableId'] ?? 'N/A'} • ${user['name'] ?? 'Guest'}'
                : '${user['name'] ?? 'Customer'} • ${user['email'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (!isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _markAsPaid(transaction['_id'], admin),
                child: const Text('Mark as Paid'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String? method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'telebirr':
        return Icons.phone_android;
      case 'mpesa':
        return Icons.phone_iphone;
      case 'cbe_birr':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  void _markAsPaid(String? orderId, AdminProvider admin) async {
    if (orderId == null) return;
    await admin.updatePaymentStatus(orderId, 'paid');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment marked as paid'),
            backgroundColor: AppTheme.successColor),
      );
    }
  }
}
