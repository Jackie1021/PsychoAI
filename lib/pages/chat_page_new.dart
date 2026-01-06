import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/message.dart';
import 'package:flutter_app/models/conversation.dart';
import 'package:flutter_app/providers/chat_provider.dart';
import 'package:flutter_app/widgets/bottom_nav_bar_visibility_notification.dart';
import 'package:flutter_app/pages/profile_card_page.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String? otherUserId;
  final String? matchId;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.otherUserId,
    this.matchId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ScrollController _scrollController;
  late final TextEditingController _inputController;
  late final FocusNode _inputFocusNode;
  bool _canSend = false;
  bool _isNavBarVisible = true;
  Conversation? _conversation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _inputController = TextEditingController();
    _inputController.addListener(_handleInputChanged);
    _inputFocusNode = FocusNode();

    // Subscribe to messages for this conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.subscribeToMessages(widget.conversationId);
      chatProvider.markAsRead(widget.conversationId);
    });
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isNavBarVisible) {
        setState(() {
          _isNavBarVisible = false;
          BottomNavBarVisibilityNotification(false).dispatch(context);
        });
      }
    }
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isNavBarVisible) {
        setState(() {
          _isNavBarVisible = true;
          BottomNavBarVisibilityNotification(true).dispatch(context);
        });
      }
    }
  }

  void _handleInputChanged() {
    final hasContent = _inputController.text.trim().isNotEmpty;
    if (hasContent != _canSend) {
      setState(() => _canSend = hasContent);
    }
  }

  Future<void> _sendMessage() async {
    final raw = _inputController.text.trim();
    if (raw.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _inputController.clear();
    _inputFocusNode.requestFocus();

    try {
      await chatProvider.sendMessage(
        conversationId: widget.conversationId,
        text: raw,
      );
      _scrollToBottom();
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openProfileCard(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileCardPage(userId: userId),
      ),
    );
  }

  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.unsubscribeFromMessages(widget.conversationId);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _inputController.removeListener(_handleInputChanged);
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        _conversation = chatProvider.getConversationById(widget.conversationId);
        if (_conversation == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final otherParticipant = _conversation!.getOtherParticipant(currentUserId);
        final isFavorited = _conversation!.isFavoritedBy(currentUserId);
        final messages = chatProvider.getMessages(widget.conversationId);

        // Auto scroll to bottom when new message arrives
        if (messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && 
                _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
              _scrollToBottom();
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: otherParticipant != null
                  ? () => _openProfileCard(otherParticipant.id)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: otherParticipant?.avatar != null
                        ? NetworkImage(otherParticipant!.avatar!)
                        : null,
                    child: otherParticipant?.avatar == null
                        ? Icon(
                            Icons.person,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        otherParticipant?.name ?? 'Chat',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (otherParticipant != null)
                        Text(
                          '@${otherParticipant.id.substring(0, math.min(8, otherParticipant.id.length))}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorited ? Icons.star : Icons.star_border,
                  color: isFavorited ? Colors.amber : null,
                ),
                onPressed: () {
                  chatProvider.toggleFavorite(widget.conversationId);
                },
                tooltip: 'Favorite Chat',
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == currentUserId;
                              final showTimestamp = _shouldShowTimestamp(messages, index);
                              
                              return Column(
                                children: [
                                  if (showTimestamp)
                                    _buildTimestamp(message.createdAt),
                                  _MessageBubble(
                                    message: message,
                                    isMe: isMe,
                                    otherName: otherParticipant?.name ?? 'User',
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  _ChatInputBar(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    canSend: _canSend,
                    onSend: _sendMessage,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _shouldShowTimestamp(List<Message> messages, int index) {
    if (index == 0) return true;
    final current = messages[index];
    final previous = messages[index - 1];
    return current.createdAt.difference(previous.createdAt).inMinutes > 5;
  }

  Widget _buildTimestamp(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    String text;
    if (messageDate == today) {
      text = DateFormat('HH:mm').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      text = 'Yesterday ${DateFormat('HH:mm').format(time)}';
    } else {
      text = DateFormat('MMM dd, HH:mm').format(time);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String otherName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.otherName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: CustomPaint(
          painter: ChatBubblePainter(
            isMe: isMe,
            color: isMe ? accentColor.withOpacity(0.9) : Colors.white,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.text != null)
                  Text(
                    message.text!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                if (message.status == MessageStatus.sending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Sending...',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatBubblePainter extends CustomPainter {
  final bool isMe;
  final Color color;

  ChatBubblePainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );
    path.addRRect(r);

    final tailSize = 8.0;
    if (isMe) {
      path.moveTo(size.width - 18, size.height - tailSize);
      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - tailSize,
        size.height - tailSize,
      );
    } else {
      path.moveTo(18, size.height - tailSize);
      path.quadraticBezierTo(0, size.height, tailSize, size.height - tailSize);
    }

    canvas.drawPath(path, paint);
    
    // Add shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 4, false);
  }

  @override
  bool shouldRepaint(covariant ChatBubblePainter oldDelegate) {
    return oldDelegate.isMe != isMe || oldDelegate.color != color;
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => onSend(),
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: InputBorder.none,
                hintText: 'Share a thought...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF3E2A2A).withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: canSend ? accent : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  Icons.arrow_upward,
                  key: ValueKey<bool>(canSend),
                  size: 20,
                  color: canSend ? Colors.white : Colors.grey[500],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
