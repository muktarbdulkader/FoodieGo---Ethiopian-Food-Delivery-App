import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';

/// Chat page for customers to communicate with their delivery driver
class OrderChatPage extends StatefulWidget {
  final Order order;

  const OrderChatPage({super.key, required this.order});

  @override
  State<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  final OrderRepository _orderRepo = OrderRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _messages = widget.order.chatMessages;
    _loadMessages();
    // Refresh messages every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final messages = await _orderRepo.getChatMessages(widget.order.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final message = await _orderRepo.sendChatMessage(widget.order.id, text);
      _messageController.clear();
      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
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
    final driverName = widget.order.delivery?.driverName ?? 'Driver';
    final hasDriver = widget.order.delivery?.driverName != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driverName, style: const TextStyle(fontSize: 16)),
            Text(
              hasDriver ? 'Your delivery driver' : 'Driver not assigned yet',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (widget.order.delivery?.driverPhone != null)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Call: ${widget.order.delivery!.driverPhone}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: !hasDriver
          ? _buildNoDriverState()
          : Column(
              children: [
                // Driver info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: const Icon(Icons.person,
                            color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driverName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                              widget.order.deliveryStatusDisplay,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                              widget.order.delivery?.trackingStatus ??
                                  'pending'),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (widget.order.delivery?.trackingStatus ?? 'pending')
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
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

  Widget _buildNoDriverState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delivery_dining,
                  size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text(
              'Driver Not Assigned Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You can chat with your driver once they are assigned to your order.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            'Send a message to your driver',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderRole == 'user';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style:
                  TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
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
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'on_the_way':
        return const Color(0xFFF59E0B);
      case 'picked_up':
        return const Color(0xFF3B82F6);
      case 'arrived':
        return const Color(0xFF8B5CF6);
      case 'assigned':
        return const Color(0xFF06B6D4);
      default:
        return AppTheme.textSecondary;
    }
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
