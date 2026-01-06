import 'package:flutter_app/models/conversation.dart';

/// Represents a summary of chat history with a matched user
class ChatHistorySummary {
  final String conversationId;
  final String matchId;
  final String matchedUserId;
  final String matchedUsername;
  final String matchedUserAvatar;
  final int totalMessages;
  final DateTime firstMessageAt;
  final DateTime lastMessageAt;
  final String lastMessageText;
  final bool isActive;

  ChatHistorySummary({
    required this.conversationId,
    required this.matchId,
    required this.matchedUserId,
    required this.matchedUsername,
    required this.matchedUserAvatar,
    required this.totalMessages,
    required this.firstMessageAt,
    required this.lastMessageAt,
    required this.lastMessageText,
    this.isActive = true,
  });

  factory ChatHistorySummary.fromConversation(
    Conversation conversation,
    String currentUserId,
    int messageCount,
  ) {
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    
    return ChatHistorySummary(
      conversationId: conversation.id,
      matchId: conversation.metadata.matchId ?? '',
      matchedUserId: otherParticipant?.id ?? '',
      matchedUsername: otherParticipant?.name ?? 'Unknown',
      matchedUserAvatar: otherParticipant?.avatar ?? '',
      totalMessages: messageCount,
      firstMessageAt: conversation.createdAt,
      lastMessageAt: conversation.lastMessage?.timestamp ?? conversation.updatedAt,
      lastMessageText: conversation.lastMessage?.text ?? '',
      isActive: conversation.status == ConversationStatus.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'matchId': matchId,
        'matchedUserId': matchedUserId,
        'matchedUsername': matchedUsername,
        'matchedUserAvatar': matchedUserAvatar,
        'totalMessages': totalMessages,
        'firstMessageAt': firstMessageAt.toIso8601String(),
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'lastMessageText': lastMessageText,
        'isActive': isActive,
      };

  factory ChatHistorySummary.fromJson(Map<String, dynamic> json) {
    return ChatHistorySummary(
      conversationId: json['conversationId'] as String,
      matchId: json['matchId'] as String? ?? '',
      matchedUserId: json['matchedUserId'] as String,
      matchedUsername: json['matchedUsername'] as String,
      matchedUserAvatar: json['matchedUserAvatar'] as String? ?? '',
      totalMessages: json['totalMessages'] as int,
      firstMessageAt: DateTime.parse(json['firstMessageAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      lastMessageText: json['lastMessageText'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
