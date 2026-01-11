import 'dart:convert';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification model for storing notification history
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'order', 'promo', 'delivery'
  final DateTime timestamp;
  final bool isRead;
  final String? payload;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'payload': payload,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: json['type'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
        payload: json['payload'],
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
        payload: payload,
      );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static const String _notificationsKey = 'app_notifications';

  /// Initialize notification service
  static Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - can navigate to specific page
    // based on response.payload
  }

  /// Get all stored notifications
  static Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_notificationsKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((j) => AppNotification.fromJson(j)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Save notification to history
  static Future<void> _saveNotification(AppNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    notifications.insert(0, notification);

    // Keep only last 50 notifications
    final toSave = notifications.take(50).toList();
    await prefs.setString(
        _notificationsKey, jsonEncode(toSave.map((n) => n.toJson()).toList()));
  }

  /// Mark notification as read
  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    final updated = notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await prefs.setString(
        _notificationsKey, jsonEncode(updated.map((n) => n.toJson()).toList()));
  }

  /// Clear all notifications
  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Show order status notification
  static Future<void> showOrderNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Order Updates',
      channelDescription: 'Notifications about your order status',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B35),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _notifications.show(id, title, body, details, payload: payload);

    // Save to history
    await _saveNotification(AppNotification(
      id: id.toString(),
      title: title,
      body: body,
      type: 'order',
      timestamp: DateTime.now(),
      payload: payload,
    ));
  }

  /// Show promotion notification
  static Future<void> showPromoNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'promo_channel',
      'Promotions',
      channelDescription: 'Special offers and discounts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B35),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _notifications.show(id, title, body, details, payload: payload);

    // Save to history
    await _saveNotification(AppNotification(
      id: id.toString(),
      title: title,
      body: body,
      type: 'promo',
      timestamp: DateTime.now(),
      payload: payload,
    ));
  }

  /// Show delivery notification
  static Future<void> showDeliveryNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Updates',
      channelDescription: 'Updates about your delivery',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF10B981),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _notifications.show(id, title, body, details, payload: payload);

    // Save to history
    await _saveNotification(AppNotification(
      id: id.toString(),
      title: title,
      body: body,
      type: 'delivery',
      timestamp: DateTime.now(),
      payload: payload,
    ));
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
