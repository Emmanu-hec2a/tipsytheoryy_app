import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_message_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String recipientName;
  final String? recipientImage;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.recipientName,
    this.recipientImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).setActiveOrder(widget.orderId);
    });
  }

  @override
  void dispose() {
    // We don't stop polling here because we want it to stop when the provider is cleaned up 
    // or when the user moves to another screen, but actually it's better to stop when leaving chat
    // to save battery.
    Provider.of<ChatProvider>(context, listen: false).stopPolling();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipientName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Order #${widget.orderNumber}',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final isMe = message.senderId == userProvider.user?.id;
                      return _buildMessageBubble(message, isMe, isDark);
                    },
                  ),
          ),
          _buildComposer(chatProvider, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.recipientImage != null)
             Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2), width: 4),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: CachedNetworkImageProvider(widget.recipientImage!),
              ),
            )
          else
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            'Chat with ${widget.recipientName}',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation about order #${widget.orderNumber}',
            style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              backgroundImage: message.senderImage != null 
                  ? CachedNetworkImageProvider(message.senderImage!) 
                  : null,
              child: message.senderImage == null 
                  ? Icon(Icons.person, size: 14, color: isDark ? Colors.white38 : Colors.grey) 
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe 
                    ? AppTheme.primaryColor 
                    : (isDark ? Theme.of(context).cardColor : Colors.grey.shade100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isMe ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
              backgroundImage: message.senderImage != null 
                  ? CachedNetworkImageProvider(message.senderImage!) 
                  : null,
              child: message.senderImage == null 
                  ? const Icon(Icons.person, size: 14, color: AppTheme.accentColor) 
                  : null,
            ),
            const SizedBox(height: 12), // Align with margin-bottom of bubble
          ],
        ],
      ),
    );
  }

  Widget _buildComposer(ChatProvider provider, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final text = _controller.text;
              if (text.trim().isEmpty) return;
              
              _controller.clear();
              final success = await provider.sendMessage(widget.orderId, text);
              
              if (!success && mounted) {
                _controller.text = text; // Restore text on failure
                
                // Show specific error if possible
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message could not be sent. Check if a rider is assigned.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
