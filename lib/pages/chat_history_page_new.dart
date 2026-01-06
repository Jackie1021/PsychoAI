import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/conversation.dart';
import 'package:flutter_app/providers/chat_provider.dart';
import 'package:flutter_app/pages/chat_page_new.dart';
import 'package:intl/intl.dart';

class ChatHistoryPageNew extends StatefulWidget {
  const ChatHistoryPageNew({super.key});

  @override
  State<ChatHistoryPageNew> createState() => _ChatHistoryPageNewState();
}

class _ChatHistoryPageNewState extends State<ChatHistoryPageNew> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return conversations.where((conv) {
      final otherParticipant = conv.getOtherParticipant(currentUserId);
      return otherParticipant?.name.toLowerCase().contains(_searchQuery) ?? false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conversations',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Favorites'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildChatList(
                _filterConversations(chatProvider.activeConversations),
                chatProvider,
              ),
              _buildChatList(
                _filterConversations(chatProvider.favoritedConversations),
                chatProvider,
                isFavoritesTab: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatList(
    List<Conversation> conversations,
    ChatProvider chatProvider, {
    bool isFavoritesTab = false,
  }) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFavoritesTab ? Icons.star_border : Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isFavoritesTab
                  ? 'No favorited conversations yet.'
                  : _searchQuery.isEmpty
                      ? 'No conversations yet.'
                      : 'No conversations found.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (!isFavoritesTab && _searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Match with someone to start chatting!',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Sort: pinned first, then by updatedAt
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final sortedConversations = List<Conversation>.from(conversations)
      ..sort((a, b) {
        final aPinned = a.isPinnedBy(currentUserId);
        final bPinned = b.isPinnedBy(currentUserId);
        if (aPinned != bPinned) return aPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    return ListView.builder(
      itemCount: sortedConversations.length,
      itemBuilder: (context, index) {
        final conversation = sortedConversations[index];
        return _ConversationTile(
          conversation: conversation,
          chatProvider: chatProvider,
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final ChatProvider chatProvider;

  const _ConversationTile({
    required this.conversation,
    required this.chatProvider,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    final lastMessage = conversation.lastMessage;
    final unreadCount = conversation.getUnreadCountFor(currentUserId);
    final isFavorited = conversation.isFavoritedBy(currentUserId);
    final isPinned = conversation.isPinnedBy(currentUserId);

    if (otherParticipant == null) return const SizedBox.shrink();

    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text('Are you sure you want to delete this conversation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        chatProvider.deleteConversation(conversation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Text(
                otherParticipant.name[0].toUpperCase(),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            if (isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.push_pin, size: 16, color: Colors.blue),
              ),
            Expanded(
              child: Text(
                otherParticipant.name,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: lastMessage != null
            ? Text(
                lastMessage.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                ),
              )
            : Text(
                'No messages yet',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessage != null)
              Text(
                _formatTime(lastMessage.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: unreadCount > 0 ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (conversation.type == ConversationType.match)
                  const Icon(Icons.favorite, size: 14, color: Colors.pink),
                IconButton(
                  icon: Icon(
                    isFavorited ? Icons.star : Icons.star_border,
                    color: isFavorited ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    chatProvider.toggleFavorite(conversation.id);
                  },
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatPage(
                conversationId: conversation.id,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEE').format(time);
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }
}
