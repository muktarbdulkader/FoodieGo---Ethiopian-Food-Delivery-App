import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/admin/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/loading_widget.dart';
import 'manage_foods_page.dart';
import 'manage_orders_page.dart';
import 'manage_users_page.dart';
import 'manage_payments_page.dart';
import '../../../state/auth/auth_provider.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, admin, _) {
            if (admin.isLoading && admin.stats == null) {
              return const LoadingWidget(message: 'Loading dashboard...');
            }
            return RefreshIndicator(
              onRefresh: () => admin.fetchDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTodayStats(admin.stats),
                    const SizedBox(height: 20),
                    _buildStatsGrid(admin.stats),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentOrders(admin.stats?['recentOrders']),
                    const SizedBox(height: 24),
                    _buildTopSellingItems(admin.stats?['topFoods']),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthProvider>().user;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user?.name ?? 'Admin'}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (user?.hotelName != null)
              Text(user!.hotelName!,
                  style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/admin', (r) => false);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow),
            child: const Icon(Icons.logout, color: AppTheme.errorColor),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStats(Map<String, dynamic>? stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6B35FF), Color(0xFF8A5CFF)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Revenue",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                    '${AppConstants.currency}${(stats?['todayRevenue'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('${stats?['todayOrders'] ?? 0} orders today',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Icon(Icons.pending_actions,
                    color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text('${stats?['pendingOrders'] ?? 0}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
                const Text('Pending',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate aspect ratio based on available width
        final cardWidth = (constraints.maxWidth - 10) / 2;
        const cardHeight = 80.0; // Fixed height for consistent layout
        final aspectRatio = cardWidth / cardHeight;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
                'Revenue',
                '${AppConstants.currency}${(stats?['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                Icons.attach_money,
                AppTheme.successColor),
            _buildStatCard('Orders', '${stats?['totalOrders'] ?? 0}',
                Icons.shopping_bag, AppTheme.primaryColor),
            _buildStatCard('Users', '${stats?['activeUsers'] ?? 0}',
                Icons.people, AppTheme.secondaryColor),
            _buildStatCard('Menu', '${stats?['totalFoods'] ?? 0}',
                Icons.restaurant_menu, AppTheme.warningColor),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Management',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            const cardHeight = 50.0;
            final aspectRatio = cardWidth / cardHeight;

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: aspectRatio,
              children: [
                _buildActionCard(
                    'Orders', Icons.receipt_long, AppTheme.primaryColor, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageOrdersPage()));
                }),
                _buildActionCard(
                    'Menu', Icons.restaurant_menu, AppTheme.secondaryColor, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageFoodsPage()));
                }),
                _buildActionCard('Users', Icons.people, AppTheme.warningColor,
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManageUsersPage()));
                }),
                _buildActionCard(
                    'Payments', Icons.payment, AppTheme.successColor, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ManagePaymentsPage()));
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(List<dynamic>? orders) {
    if (orders == null || orders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageOrdersPage())),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...orders.take(5).map((order) => _buildOrderItem(order)),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final user = order['user'] as Map<String, dynamic>?;
    final status = order['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_getStatusIcon(status),
                color: _getStatusColor(status), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order['orderNumber'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(user?['name'] ?? 'Unknown',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  '${AppConstants.currency}${(order['totalPrice'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successColor;
      case 'preparing':
      case 'ready':
        return AppTheme.warningColor;
      case 'out_for_delivery':
        return AppTheme.secondaryColor;
      case 'cancelled':
        return AppTheme.errorColor;
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
      case 'ready':
        return Icons.takeout_dining;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildTopSellingItems(List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Selling Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? Colors.amber
                        : (index == 1
                            ? Colors.grey.shade400
                            : (index == 2
                                ? Colors.brown.shade300
                                : AppTheme.primaryColor
                                    .withValues(alpha: 0.1))),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                      child: Text('${index + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index < 3
                                  ? Colors.white
                                  : AppTheme.primaryColor))),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(item['_id'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item['totalSold'] ?? 0} sold',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                    Text(
                        '${AppConstants.currency}${(item['revenue'] ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
