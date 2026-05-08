import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';
import '../../../state/auth/auth_provider.dart';
import 'restaurants_management_page.dart';
import 'users_management_page.dart';
import 'platform_orders_page.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.get('${ApiConstants.baseUrl}/super-admin/dashboard');
      if (mounted) {
        setState(() {
          _stats = response['data'];
          _isLoading = false;
        });
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

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/super-admin/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFE94560)),
            SizedBox(width: 10),
            Text('Super Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildDashboard(auth),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadStats, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDashboard(AuthProvider auth) {
    final overview = _stats?['overview'] ?? {};
    final recentRevenue = (_stats?['recentRevenue'] as List?) ?? [];
    final topRestaurants = (_stats?['topRestaurants'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          _buildWelcomeHeader(auth),
          const SizedBox(height: 20),

          // Stats grid
          _buildStatsGrid(overview),
          const SizedBox(height: 20),

          // Quick actions
          _buildQuickActions(),
          const SizedBox(height: 20),

          // Top restaurants by orders (bar chart)
          if (topRestaurants.isNotEmpty) ...[
            _buildSectionTitle('Orders by Restaurant'),
            const SizedBox(height: 12),
            _buildOrdersByRestaurantChart(topRestaurants),
            const SizedBox(height: 20),
          ],

          // Revenue trend
          if (recentRevenue.isNotEmpty) ...[
            _buildSectionTitle('Revenue (Last 7 Days)'),
            const SizedBox(height: 12),
            _buildRevenueTrend(recentRevenue),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Color(0xFFE94560), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${auth.user?.name ?? 'Super Admin'}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Platform Administrator',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SUPER ADMIN',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> overview) {
    final stats = [
      _StatItem('Total Users', '${overview['totalUsers'] ?? 0}', Icons.people, Colors.blue),
      _StatItem('Restaurants', '${overview['totalRestaurants'] ?? 0}', Icons.restaurant, Colors.orange),
      _StatItem('Drivers', '${overview['totalDeliveryDrivers'] ?? 0}', Icons.delivery_dining, Colors.purple),
      _StatItem('Total Orders', '${overview['totalOrders'] ?? 0}', Icons.receipt_long, Colors.teal),
      _StatItem(
        'Platform Revenue',
        'ETB ${((overview['totalRevenue'] ?? 0.0) as num).toStringAsFixed(0)}',
        Icons.attach_money,
        Colors.green,
      ),
      _StatItem('Active Restaurants', '${overview['activeRestaurants'] ?? 0}', Icons.store, Colors.indigo),
      _StatItem('Menu Items', '${overview['totalFoods'] ?? 0}', Icons.fastfood, Colors.pink),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(stats[i]),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  stat.label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
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
        _buildSectionTitle('Management'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Restaurants',
                Icons.restaurant,
                const Color(0xFFFF6B35),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RestaurantsManagementPage())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Users',
                Icons.people,
                const Color(0xFF4ECDC4),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersManagementPage())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Orders',
                Icons.receipt_long,
                const Color(0xFF45B7D1),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlatformOrdersPage())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersByRestaurantChart(List<dynamic> restaurants) {
    // Find max orders to scale bars
    final maxOrders = restaurants
        .map((r) => ((r['orders'] ?? 0) as num).toInt())
        .fold(0, (a, b) => a > b ? a : b);

    // Bar colors cycling
    final barColors = [
      const Color(0xFFFF6B35),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFE94560),
      const Color(0xFF96CEB4),
    ];

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart bars
          ...restaurants.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value as Map<String, dynamic>;
            final orders = ((r['orders'] ?? 0) as num).toInt();
            final name = (r['hotelName'] ?? 'Unknown') as String;
            final barFraction = maxOrders > 0 ? orders / maxOrders : 0.0;
            final color = barColors[i % barColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$orders orders',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Background track
                          Container(
                            height: 12,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          // Filled bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            height: 12,
                            width: constraints.maxWidth * barFraction,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRevenueTrend(List<dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: data.map((day) {
          final revenue = ((day['revenue'] ?? 0.0) as num).toDouble();
          final orders = day['orders'] ?? 0;
          final date = day['_id'] ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 90, child: Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: revenue > 0 ? (revenue / 10000).clamp(0.0, 1.0) : 0,
                      backgroundColor: Colors.grey[200],
                      color: AppTheme.primaryColor,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text(
                    'ETB ${revenue.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Text('($orders)', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}
