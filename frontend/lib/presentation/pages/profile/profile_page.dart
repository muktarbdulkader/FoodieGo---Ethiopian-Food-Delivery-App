import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../state/order/order_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../data/services/api_service.dart';
import '../auth/login_page.dart';
import '../orders/orders_page.dart';
import '../events/my_events_page.dart';
import 'payment_methods_page.dart';
import 'notifications_page.dart';
import 'help_support_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoadingLocation = false;
  bool _isLoadingStats = true;
  int _ordersCount = 0;
  double _walletBalance = 0.0;
  String _userLevel = 'Regular';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStats();
    });
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);

    try {
      final orderProvider = context.read<OrderProvider>();
      await orderProvider.fetchOrders(silent: true);

      if (!mounted) return;
      final orders = orderProvider.orders;

      try {
        final response = await ApiService.get('/auth/me/stats');
        if (mounted) {
          setState(() {
            _ordersCount = response['data']?['ordersCount'] ?? orders.length;
            _walletBalance =
                (response['data']?['walletBalance'] ?? 0.0).toDouble();
            _userLevel = response['data']?['level'] ?? 'Regular';
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _ordersCount = orders.length;
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final location = await LocationService.getFullLocation();

      if (location != null && mounted) {
        final success = await context.read<AuthProvider>().updateLocation(
              latitude: location['latitude'],
              longitude: location['longitude'],
              address: location['address'],
              city: location['city'],
            );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location updated: ${location['city']}'),
                backgroundColor: AppTheme.accentGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get location'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoadingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionTitle('My Account'),
            _buildAccountMenu(),
            const SizedBox(height: 24),
            _buildSectionTitle('Settings'),
            _buildSettingsMenu(),
            const SizedBox(height: 24),
            _buildSectionTitle('More'),
            _buildMoreMenu(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Guest User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.phone ?? user?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigate to edit profile
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Level badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 24,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: 'assets/icons/coupon.png',
            iconWidget: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_offer,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            label: 'Coupons',
            value: _isLoadingStats ? '...' : '$_ordersCount',
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: 'assets/icons/wallet.png',
            iconWidget: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
            label: 'Wallet',
            value: _isLoadingStats
                ? '...'
                : '${_walletBalance.toStringAsFixed(2)} ETB',
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: 'assets/icons/level.png',
            iconWidget: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.workspace_premium,
                color: Colors.orange.shade400,
                size: 20,
              ),
            ),
            label: 'Level',
            value: _userLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required Widget iconWidget,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(width: 4),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAccountMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.favorite_border,
            title: 'Favorites',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            onTap: _isLoadingLocation ? null : _updateLocation,
            trailing: _isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.people_outline,
            title: 'Account Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.translate,
            title: 'Language',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.phone_outlined,
            title: 'Contact Us',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportPage()),
            ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersPage()),
            ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.celebration_outlined,
            title: 'My Events',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyEventsPage()),
            ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
            ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: AppTheme.primaryColor,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? titleColor,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: titleColor ?? Colors.grey.shade600,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: titleColor ?? Colors.black87,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: Colors.grey.shade100,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (r) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
