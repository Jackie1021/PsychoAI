import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/chat_participant.dart';

enum ConversationType {
  match,
  direct,
  group,
}

enum ConversationStatus {
  active,
  archived,
  deleted,
}

class LastMessageSnapshot {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final String type;

  LastMessageSnapshot({
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }

  factory LastMessageSnapshot.fromMap(Map<String, dynamic> map) {
    return LastMessageSnapshot(
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'text',
    );
  }
}

class ConversationMetadata {
  final String? matchId;
  final Map<String, bool> isFavorited;
  final Map<String, bool> isPinned;
  final List<String> tags;

  ConversationMetadata({
    this.matchId,
    this.isFavorited = const {},
    this.isPinned = const {},
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'isFavorited': isFavorited,
      'isPinned': isPinned,
      'tags': tags,
    };
  }

  factory ConversationMetadata.fromMap(Map<String, dynamic> map) {
    return ConversationMetadata(
      matchId: map['matchId'],
      isFavorited: Map<String, bool>.from(map['isFavorited'] ?? {}),
      isPinned: Map<String, bool>.from(map['isPinned'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, ChatParticipant> participantInfo;
  final ConversationType type;
  final ConversationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LastMessageSnapshot? lastMessage;
  final Map<String, int> unreadCount;
  final ConversationMetadata metadata;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.participantInfo,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = const {},
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantInfo': participantInfo.map((key, value) => MapEntry(key, value.toMap())),
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'metadata': metadata.toMap(),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map, String id) {
    return Conversation(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantInfo: (map['participantInfo'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, ChatParticipant.fromMap(value))) ??
          {},
      type: ConversationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ConversationType.direct,
      ),
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ConversationStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: map['lastMessage'] != null
          ? LastMessageSnapshot.fromMap(map['lastMessage'])
          : null,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      metadata: ConversationMetadata.fromMap(map['metadata'] ?? {}),
    );
  }

  ChatParticipant? getOtherParticipant(String currentUserId) {
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return otherId.isNotEmpty ? participantInfo[otherId] : null;
  }

  bool isFavoritedBy(String userId) {
    return metadata.isFavorited[userId] ?? false;
  }

  bool isPinnedBy(String userId) {
    return metadata.isPinned[userId] ?? false;
  }

  int getUnreadCountFor(String userId) {
    return unreadCount[userId] ?? 0;
  }
}
