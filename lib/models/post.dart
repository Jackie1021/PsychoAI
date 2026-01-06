class Post {
  final String? postId;
  final String userId;
  final String author;
  final String authorImageUrl;
  final String content;
  final List<String> media;
  final MediaType? mediaType;
  final int likes;
  final int comments;
  final int favorites;
  final double mainAxisCellCount;
  final double crossAxisCellCount;
  final bool isPublic;
  final bool isFavorited;
  final bool isLiked;
  final DateTime? createdAt;
  final String? status;

  Post({
    this.postId,
    required this.userId,
    required this.author,
    required this.authorImageUrl,
    required this.content,
    this.media = const [],
    this.mediaType,
    this.likes = 0,
    this.comments = 0,
    this.favorites = 0,
    this.mainAxisCellCount = 1.2,
    this.crossAxisCellCount = 1.0,
    this.isPublic = true,
    this.isFavorited = false,
    this.isLiked = false,
    this.createdAt,
    this.status = 'visible',
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] as String?,
      userId: json['userId'] as String? ?? '',
      author: (json['author'] as String? ?? 'Anonymous').trim().isEmpty 
          ? 'Anonymous' 
          : (json['author'] as String).trim(),
      authorImageUrl: (json['authorImageUrl'] as String? ?? '').trim(),
      content: (json['text'] as String? ?? json['content'] as String? ?? '').trim(),
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mediaType: json['mediaType'] != null
          ? MediaType.values.firstWhere(
              (e) => e.toString() == 'MediaType.${json['mediaType']}',
              orElse: () => MediaType.text,
            )
          : null,
      likes: json['likeCount'] as int? ?? json['likes'] as int? ?? 0,
      comments: json['commentCount'] as int? ?? json['comments'] as int? ?? 0,
      favorites:
          json['favoriteCount'] as int? ?? json['favorites'] as int? ?? 0,
      mainAxisCellCount: (json['mainAxisCellCount'] as num?)?.toDouble() ?? 1.2,
      crossAxisCellCount:
          (json['crossAxisCellCount'] as num?)?.toDouble() ?? 1.0,
      isPublic: json['isPublic'] as bool? ?? true,
      isFavorited: json['isFavorited'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      status: json['status'] as String? ?? 'visible',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (postId != null) 'postId': postId,
      'userId': userId,
      'author': author,
      'authorImageUrl': authorImageUrl,
      'text': content,
      'content': content,
      'media': media,
      if (mediaType != null) 'mediaType': mediaType.toString().split('.').last,
      'likeCount': likes,
      'likes': likes,
      'commentCount': comments,
      'comments': comments,
      'favoriteCount': favorites,
      'favorites': favorites,
      'mainAxisCellCount': mainAxisCellCount,
      'crossAxisCellCount': crossAxisCellCount,
      'isPublic': isPublic,
      'isFavorited': isFavorited,
      'isLiked': isLiked,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'status': status,
    };
  }

  Post copyWith({
    String? postId,
    String? userId,
    String? author,
    String? authorImageUrl,
    String? content,
    List<String>? media,
    MediaType? mediaType,
    int? likes,
    int? comments,
    int? favorites,
    double? mainAxisCellCount,
    double? crossAxisCellCount,
    bool? isPublic,
    bool? isFavorited,
    bool? isLiked,
    DateTime? createdAt,
    String? status,
  }) {
    return Post(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      author: author ?? this.author,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      content: content ?? this.content,
      media: media ?? this.media,
      mediaType: mediaType ?? this.mediaType,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      favorites: favorites ?? this.favorites,
      mainAxisCellCount: mainAxisCellCount ?? this.mainAxisCellCount,
      crossAxisCellCount: crossAxisCellCount ?? this.crossAxisCellCount,
      isPublic: isPublic ?? this.isPublic,
      isFavorited: isFavorited ?? this.isFavorited,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

enum MediaType {
  text,
  image,
  video,
}
