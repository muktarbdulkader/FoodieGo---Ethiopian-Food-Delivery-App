import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newRestaurants = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppTheme.textPrimary),
          ),
        ),
        title: const Text('Notifications',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Notification Types'),
            const SizedBox(height: 12),
            _buildNotificationCard([
              _buildSwitchTile(
                'Order Updates',
                'Get notified about your order status',
                Icons.delivery_dining,
                AppTheme.primaryColor,
                _orderUpdates,
                (v) => setState(() => _orderUpdates = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                'Promotions & Offers',
                'Receive special deals and discounts',
                Icons.local_offer,
                AppTheme.accentPink,
                _promotions,
                (v) => setState(() => _promotions = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                'New Restaurants',
                'Know when new restaurants join',
                Icons.restaurant,
                AppTheme.accentGreen,
                _newRestaurants,
                (v) => setState(() => _newRestaurants = v),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Notification Channels'),
            const SizedBox(height: 12),
            _buildNotificationCard([
              _buildSwitchTile(
                'Push Notifications',
                'Receive notifications on your device',
                Icons.notifications_active,
                AppTheme.accentBlue,
                _pushNotifications,
                (v) => setState(() => _pushNotifications = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                'Email Notifications',
                'Receive updates via email',
                Icons.email,
                AppTheme.secondaryColor,
                _emailNotifications,
                (v) => setState(() => _emailNotifications = v),
              ),
              _buildDivider(),
              _buildSwitchTile(
                'SMS Notifications',
                'Receive updates via SMS',
                Icons.sms,
                AppTheme.accentYellow,
                _smsNotifications,
                (v) => setState(() => _smsNotifications = v),
              ),
            ]),
            const SizedBox(height: 24),
            _buildRecentNotifications(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary)),
    );
  }

  Widget _buildNotificationCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon,
      Color color, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 70);
  }

  Widget _buildRecentNotifications() {
    final notifications = [
      {
        'title': 'Order Delivered!',
        'message': 'Your order #1234 has been delivered',
        'time': '2 hours ago',
        'icon': Icons.check_circle,
        'color': AppTheme.accentGreen,
      },
      {
        'title': '50% Off Today!',
        'message': 'Get 50% off on all pizzas at Pizza Palace',
        'time': '5 hours ago',
        'icon': Icons.local_offer,
        'color': AppTheme.accentPink,
      },
      {
        'title': 'New Restaurant',
        'message': 'Habesha Kitchen is now on FoodieGo!',
        'time': '1 day ago',
        'icon': Icons.restaurant,
        'color': AppTheme.accentBlue,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Recent Notifications'),
        const SizedBox(height: 12),
        ...notifications.map((n) => _buildNotificationItem(n)),
      ],
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (notification['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(notification['icon'],
                color: notification['color'], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(notification['message'],
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 6),
                Text(notification['time'],
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
