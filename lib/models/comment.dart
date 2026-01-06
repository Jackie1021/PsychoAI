import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String authorAvatarUrl;
  final String text;
  final DateTime? createdAt;
  final String status;
  
  // New fields for enhanced functionality
  final int likeCount;
  final String? parentCommentId; // For replies
  final int replyCount;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
    this.status = 'visible',
    this.likeCount = 0,
    this.parentCommentId,
    this.replyCount = 0,
  });

  bool get isVisible => status == 'visible';
  bool get isReply => parentCommentId != null;

  factory PostComment.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required String postId,
  }) {
    final createdAtValue = json['createdAt'];
    DateTime? createdAt;
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue);
    }

    return PostComment(
      id: id,
      postId: postId,
      userId: json['userId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Unknown',
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: createdAt,
      status: json['status'] as String? ?? 'visible',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      parentCommentId: json['parentCommentId'] as String?,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': id,
      'postId': postId,
      'userId': userId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'text': text,
      'createdAt': createdAt,
      'status': status,
      'likeCount': likeCount,
      'parentCommentId': parentCommentId,
      'replyCount': replyCount,
    };
  }

  PostComment copyWith({
    int? likeCount,
    int? replyCount,
    String? status,
  }) {
    return PostComment(
      id: id,
      postId: postId,
      userId: userId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      text: text,
      createdAt: createdAt,
      status: status ?? this.status,
      likeCount: likeCount ?? this.likeCount,
      parentCommentId: parentCommentId,
      replyCount: replyCount ?? this.replyCount,
    );
  }
}
