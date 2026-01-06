import 'package:flutter_app/models/conversation.dart';
import 'package:flutter_app/models/message.dart';

abstract class ChatService {
  // Conversation Management
  Stream<List<Conversation>> getConversationsStream(String userId);
  Future<Conversation?> getConversation(String conversationId);
  Future<String> createConversation({
    required String currentUserId,
    required String otherUserId,
    String? matchId,
  });
  Future<void> updateConversationMetadata(
    String conversationId,
    String userId, {
    bool? isFavorited,
    bool? isPinned,
  });
  Future<void> deleteConversation(String conversationId, String userId);

  // Message Management
  Stream<List<Message>> getMessagesStream(String conversationId, {int limit = 50});
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    MessageReplyInfo? replyTo,
  });
  Future<void> markMessagesAsRead(String conversationId, String userId);
  Future<void> deleteMessage(String conversationId, String messageId);
  Future<void> addReaction(
    String conversationId,
    String messageId,
    String userId,
    String emoji,
  );
  Future<void> removeReaction(
    String conversationId,
    String messageId,
    String userId,
  );

  // User Status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline);
  Stream<bool> getUserOnlineStatus(String userId);
}
