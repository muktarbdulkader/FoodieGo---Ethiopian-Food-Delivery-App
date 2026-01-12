import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';

class DeliveryChatPage extends StatefulWidget {
  final Order order;

  const DeliveryChatPage({super.key, required this.order});

  @override
  State<DeliveryChatPage> createState() => _DeliveryChatPageState();
}

class _DeliveryChatPageState extends State<DeliveryChatPage> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.order.userName ?? 'Customer',
                style: const TextStyle(fontSize: 16)),
            Text('Order #${widget.order.orderNumber}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
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
          Text('Send a message to the customer',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderRole == 'driver';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
