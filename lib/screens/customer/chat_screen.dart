import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/chat_message_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String recipientName;
  final String? recipientImage;
  final double? recipientRating;
  final String? recipientRole;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.recipientName,
    this.recipientImage,
    this.recipientRating,
    this.recipientRole,
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
                      // 🛡️ Robust Detection: compare IDs as strings to avoid type mismatches
                      final isMe = message.senderId.toString() == userProvider.user?.id.toString();
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
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2), width: 4),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
              backgroundImage: widget.recipientImage != null 
                  ? CachedNetworkImageProvider(widget.recipientImage!) 
                  : null,
              child: widget.recipientImage == null 
                  ? Icon(Icons.person, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300) 
                  : null,
            ),
          ),
          Text(
            widget.recipientName,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.primaryColor, 
              fontSize: 18, 
              fontWeight: FontWeight.w900
            ),
          ),
          if (widget.recipientRole != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.recipientRole!.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500, 
                fontSize: 10, 
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2
              ),
            ),
          ],
          if (widget.recipientRating != null && widget.recipientRating! > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.recipientRating!.toStringAsFixed(1),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87, 
                    fontWeight: FontWeight.w900,
                    fontSize: 14
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Start a conversation about order #${widget.orderNumber}',
              style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                backgroundImage: message.senderImage != null 
                    ? CachedNetworkImageProvider(message.senderImage!) 
                    : null,
                child: message.senderImage == null 
                    ? Icon(Icons.person, size: 16, color: isDark ? Colors.white38 : Colors.grey) 
                    : null,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? AppTheme.accentColor 
                    : (isDark ? const Color(0xFF1E292B) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)
                  )
                ],
                border: isMe ? null : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
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
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(message.createdAt),
                        style: TextStyle(
                          color: isMe ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade400,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2), width: 1),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
                backgroundImage: message.senderImage != null 
                    ? CachedNetworkImageProvider(message.senderImage!) 
                    : null,
                child: message.senderImage == null 
                    ? const Icon(Icons.person, size: 16, color: AppTheme.accentColor) 
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposer(ChatProvider provider, bool isDark) {
    // 🏷️ Quick Texts: Role-based predefined messages
    final List<String> quickTexts = widget.recipientRole == 'Customer' 
      ? ['I\'m on my way!', 'Arrived at your location', 'Having trouble finding the house', 'Picked up your order!']
      : ['Please leave at the door', 'How far are you?', 'Is everything okay?', 'Thank you!'];

    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🚀 Quick Action Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: quickTexts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () async {
                    final text = quickTexts[index];
                    final success = await provider.sendMessage(widget.orderId, text);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send quick message')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      quickTexts[index],
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 8,
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
                      String errorMsg = 'Message failed to send. Please try again.';
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
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
          ),
        ],
      ),
    );
  }
}
