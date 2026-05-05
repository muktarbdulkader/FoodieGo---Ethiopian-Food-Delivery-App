import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../state/websocket/websocket_provider.dart';
import '../../widgets/delivery_map_widget.dart';

class DeliveryChatPage extends StatefulWidget {
  final Order order;
  final bool isDriver; // true = driver view, false = customer view

  const DeliveryChatPage({
    super.key,
    required this.order,
    this.isDriver = false,
  });

  @override
  State<DeliveryChatPage> createState() => _DeliveryChatPageState();
}

class _DeliveryChatPageState extends State<DeliveryChatPage> {
  final OrderRepository _orderRepo = OrderRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  WebSocketProvider? _webSocketProvider;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isSharingLocation = false;
  Timer? _refreshTimer;
  Timer? _locationShareTimer;

  // Live location data
  Position? _currentPosition;
  StreamSubscription<Position>? _locationStream;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocket();
    _startAutoRefresh();

    // If driver, start sharing location automatically
    if (widget.isDriver) {
      _startLocationSharing();
    } else {
      // Customer - listen for driver's location
      _listenForDriverLocation();
    }
  }

  void _setupWebSocket() {
    _webSocketProvider = Provider.of<WebSocketProvider>(context, listen: false);
    _webSocketProvider?.joinRoom('order:${widget.order.id}');
    _webSocketProvider?.on('chat:message', _handleNewMessage);
    _webSocketProvider?.on('driver:location', _handleLocationUpdate);
  }

  void _handleNewMessage(dynamic data) {
    if (mounted && data['orderId'] == widget.order.id) {
      setState(() {
        _messages.add({
          'id': data['id'],
          'text': data['message'],
          'sender': data['sender'],
          'senderRole': data['senderRole'],
          'type': data['type'] ?? 'text',
          'timestamp': DateTime.parse(data['timestamp']),
          'location': data['location'],
        });
      });
      _scrollToBottom();
    }
  }

  void _handleLocationUpdate(dynamic data) {
    if (mounted && data['orderId'] == widget.order.id) {
      final location = data['location'];
      if (location != null) {
        setState(() {
          _messages.add({
            'id': 'loc_${DateTime.now().millisecondsSinceEpoch}',
            'text': '📍 Shared live location',
            'sender': data['driverName'] ?? 'Driver',
            'senderRole': 'driver',
            'type': 'location',
            'timestamp': DateTime.now(),
            'location': {
              'lat': location['lat'],
              'lng': location['lng'],
              'address': location['address'],
            },
          });
        });
        _scrollToBottom();
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadMessages(silent: true);
    });
  }

  Future<void> _startLocationSharing() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() => _isSharingLocation = true);

    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _sendLocationUpdate(position);
    });

    _locationShareTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_currentPosition != null) {
        await _sendLocationUpdate(_currentPosition!);
      }
    });
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      await _orderRepo.updateDriverLocation(
        position.latitude,
        position.longitude,
        orderId: widget.order.id,
      );

      _webSocketProvider?.emit('driver:location', {
        'orderId': widget.order.id,
        'driverId': widget.order.delivery?.driverId,
        'driverName': widget.order.delivery?.driverName,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': 'Current location',
        },
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending location: $e');
    }
  }

  void _listenForDriverLocation() {
    // Customer receives location via WebSocket in _handleLocationUpdate
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _locationShareTimer?.cancel();
    _locationStream?.cancel();
    _webSocketProvider?.off('chat:message');
    _webSocketProvider?.off('driver:location');
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final messages = await _orderRepo.getChatMessages(widget.order.id);
      if (mounted) {
        setState(() {
          _messages = messages.map((m) => {
            'id': m.id,
            'text': m.message,
            'sender': m.senderName,
            'senderRole': m.senderRole,
            'type': m.type ?? 'text',
            'timestamp': m.timestamp,
            'location': m.metadata?['location'],
          }).toList();
          _isLoading = false;
        });
        if (!silent) _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage({String? type, Map<String, dynamic>? metadata}) async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && type != 'location') || _isSending) return;

    setState(() => _isSending = true);
    try {
      final message = await _orderRepo.sendChatMessage(
        widget.order.id,
        text.isNotEmpty ? text : (type == 'location' ? '📍 Shared live location' : ''),
        type: type ?? 'text',
        metadata: metadata,
      );

      _messageController.clear();

      _webSocketProvider?.emit('chat:message', {
        'orderId': widget.order.id,
        'id': message.id,
        'message': message.message,
        'sender': message.senderName,
        'senderRole': message.senderRole,
        'type': type ?? 'text',
        'timestamp': message.timestamp.toIso8601String(),
        'metadata': metadata,
      });

      setState(() {
        _messages.add({
          'id': message.id,
          'text': message.message,
          'sender': message.senderName,
          'senderRole': message.senderRole,
          'type': type ?? 'text',
          'timestamp': message.timestamp,
          'location': metadata?['location'],
        });
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await _sendMessage(
        type: 'location',
        metadata: {
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
            'address': 'Current location',
          },
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isDriver
                  ? (widget.order.userName ?? 'Customer')
                  : (widget.order.delivery?.driverName ?? 'Driver'),
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Order #${widget.order.orderNumber}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_isSharingLocation)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: Colors.green[700], size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Location Map (if driver is sharing)
          if (widget.order.delivery != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: DeliveryMapWidget(
                driverLocation: _currentPosition != null
                    ? {'latitude': _currentPosition!.latitude, 'longitude': _currentPosition!.longitude}
                    : widget.order.delivery?.driverLocation,
                restaurantLocation: widget.order.delivery?.pickupLocation,
                customerLocation: widget.order.deliveryAddress,
                driverName: widget.order.delivery?.driverName,
                status: widget.order.delivery?.trackingStatus,
                distance: widget.order.delivery?.distance,
                estimatedMinutes: widget.order.delivery?.estimatedTime,
              ),
            ),

          // Order info banner
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.order.deliveryAddress?.fullAddress ?? 'No address',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) =>
                            _buildMessageBubble(_messages[index]),
                      ),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No messages yet',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(
            widget.isDriver
                ? 'Send a message to the customer'
                : 'Send a message to your driver',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = widget.isDriver
        ? message['senderRole'] == 'driver'
        : message['senderRole'] != 'driver';
    final isLocation = message['type'] == 'location';
    final location = message['location'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name (if not me)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message['sender'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Message bubble
            Container(
              padding: isLocation
                  ? const EdgeInsets.all(8)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF8B5CF6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: isLocation && location != null
                  ? _buildLocationPreview(location, isMe)
                  : Text(
                      message['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                _formatTime(message['timestamp'] ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPreview(Map<String, dynamic> location, bool isMe) {
    return Container(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 48,
                    color: isMe ? Colors.white : const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${location['lat']?.toStringAsFixed(4) ?? '0.0000'}, '
                    '${location['lng']?.toStringAsFixed(4) ?? '0.0000'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.map,
                size: 16,
                color: isMe ? Colors.white70 : const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location['address'] ?? 'Shared location',
                  style: TextStyle(
                    color: isMe ? Colors.white : AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Location share button
            GestureDetector(
              onTap: _shareCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
