import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/notification_service.dart';

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
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long;
      case 'promo':
        return Icons.local_offer;
      case 'delivery':
        return Icons.delivery_dining;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'order':
        return AppTheme.primaryColor;
      case 'promo':
        return AppTheme.accentPink;
      case 'delivery':
        return AppTheme.accentGreen;
      default:
        return AppTheme.accentBlue;
    }
  }

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
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.textSecondary),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All'),
                    content: const Text('Delete all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await NotificationService.clearNotifications();
                  _loadNotifications();
                }
              },
            ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Recent Notifications'),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_notifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Your notifications will appear here',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ..._notifications.map((n) => _buildNotificationItem(n)),
      ],
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final color = _getColor(notification.type);
    final icon = _getIcon(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        // Reload to sync with storage
        await _loadNotifications();
      },
      child: GestureDetector(
        onTap: () async {
          if (!notification.isRead) {
            await NotificationService.markAsRead(notification.id);
            _loadNotifications();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
            border: notification.isRead
                ? null
                : Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(notification.title,
                              style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  fontSize: 14)),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.body,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(_formatTime(notification.timestamp),
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
