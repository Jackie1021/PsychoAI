import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  audio,
  video,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime timestamp;

  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'emoji': emoji,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      userId: map['userId'] ?? '',
      emoji: map['emoji'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class MessageReplyInfo {
  final String messageId;
  final String text;
  final String senderId;

  MessageReplyInfo({
    required this.messageId,
    required this.text,
    required this.senderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'text': text,
      'senderId': senderId,
    };
  }

  factory MessageReplyInfo.fromMap(Map<String, dynamic> map) {
    return MessageReplyInfo(
      messageId: map['messageId'] ?? '',
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
    );
  }
}

class MediaMetadata {
  final int? width;
  final int? height;
  final int? duration;
  final String? thumbnailUrl;

  MediaMetadata({
    this.width,
    this.height,
    this.duration,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
      'duration': duration,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory MediaMetadata.fromMap(Map<String, dynamic> map) {
    return MediaMetadata(
      width: map['width'],
      height: map['height'],
      duration: map['duration'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String? text;
  final MessageType type;
  final String? mediaUrl;
  final MediaMetadata? mediaMetadata;
  final MessageReplyInfo? replyTo;
  final MessageStatus status;
  final List<MessageReaction> reactions;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.senderId,
    this.text,
    required this.type,
    this.mediaUrl,
    this.mediaMetadata,
    this.replyTo,
    required this.status,
    this.reactions = const [],
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'mediaMetadata': mediaMetadata?.toMap(),
      'replyTo': replyTo?.toMap(),
      'status': status.name,
      'reactions': reactions.map((r) => r.toMap()).toList(),
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'],
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: map['mediaUrl'],
      mediaMetadata: map['mediaMetadata'] != null
          ? MediaMetadata.fromMap(map['mediaMetadata'])
          : null,
      replyTo: map['replyTo'] != null
          ? MessageReplyInfo.fromMap(map['replyTo'])
          : null,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      reactions: map['reactions'] != null
          ? (map['reactions'] as List)
              .map((r) => MessageReaction.fromMap(r))
              .toList()
          : [],
      isDeleted: map['isDeleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    MessageType? type,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    MessageReplyInfo? replyTo,
    MessageStatus? status,
    List<MessageReaction>? reactions,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
