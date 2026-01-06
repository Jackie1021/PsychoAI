import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/models/conversation.dart';
import 'package:flutter_app/models/message.dart';
import 'package:flutter_app/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  final String currentUserId;

  final Map<String, List<Message>> _messageCache = {};
  List<Conversation> _conversations = [];
  StreamSubscription? _conversationsSubscription;
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  ChatProvider({
    required ChatService chatService,
    required this.currentUserId,
  }) : _chatService = chatService {
    _initConversations();
  }

  List<Conversation> get conversations => _conversations;

  List<Conversation> get activeConversations {
    return _conversations
        .where((c) => c.status == ConversationStatus.active)
        .toList();
  }

  List<Conversation> get favoritedConversations {
    return activeConversations.where((c) => c.isFavoritedBy(currentUserId)).toList();
  }

  List<Message> getMessages(String conversationId) {
    return _messageCache[conversationId] ?? [];
  }

  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conv) => sum + conv.getUnreadCountFor(currentUserId));
  }

  void _initConversations() {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _chatService
        .getConversationsStream(currentUserId)
        .listen((conversations) {
      _conversations = conversations;
      notifyListeners();
    });
  }

  void subscribeToMessages(String conversationId) {
    if (_messageSubscriptions.containsKey(conversationId)) return;

    _messageSubscriptions[conversationId] = _chatService
        .getMessagesStream(conversationId)
        .listen((messages) {
      _messageCache[conversationId] = messages;
      notifyListeners();
    });
  }

  void unsubscribeFromMessages(String conversationId) {
    _messageSubscriptions[conversationId]?.cancel();
    _messageSubscriptions.remove(conversationId);
  }

  Future<String> createOrGetConversation({
    required String otherUserId,
    String? matchId,
  }) async {
    final existing = _conversations.firstWhere(
      (c) => c.participantIds.contains(otherUserId),
      orElse: () => Conversation(
        id: '',
        participantIds: [],
        participantInfo: {},
        type: ConversationType.direct,
        status: ConversationStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: ConversationMetadata(),
      ),
    );

    if (existing.id.isNotEmpty) {
      return existing.id;
    }

    return await _chatService.createConversation(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      matchId: matchId,
    );
  }

  Future<String> getOrCreateConversation({
    required String otherUserId,
    String? matchId,
  }) async {
    return createOrGetConversation(otherUserId: otherUserId, matchId: matchId);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    MessageReplyInfo? replyTo,
  }) async {
    await _chatService.sendMessage(
      conversationId: conversationId,
      senderId: currentUserId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      mediaMetadata: mediaMetadata,
      replyTo: replyTo,
    );
  }

  Future<void> markAsRead(String conversationId) async {
    await _chatService.markMessagesAsRead(conversationId, currentUserId);
  }

  Future<void> toggleFavorite(String conversationId) async {
    final conversation = _conversations.firstWhere((c) => c.id == conversationId);
    final newValue = !conversation.isFavoritedBy(currentUserId);
    await _chatService.updateConversationMetadata(
      conversationId,
      currentUserId,
      isFavorited: newValue,
    );
  }

  Future<void> deleteConversation(String conversationId) async {
    await _chatService.deleteConversation(conversationId, currentUserId);
  }

  Conversation? getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
