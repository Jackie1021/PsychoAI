import 'dart:typed_data';

/// Base user data model with only pure Dart compatible fields
/// This can be shared between Flutter app and standalone scripts
class BaseUserData {
  final String uid;
  final String username;
  final String? email;
  final List<String> traits;
  final String freeText;
  final List<String> followedBloggerIds;
  final List<String> favoritedPostIds;
  final List<String> favoritedConversationIds;
  final List<String> likedPostIds;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  BaseUserData({
    required this.uid,
    required this.username,
    this.email,
    this.traits = const [],
    this.freeText = '',
    this.followedBloggerIds = const [],
    this.favoritedPostIds = const [],
    this.favoritedConversationIds = const [],
    this.likedPostIds = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  factory BaseUserData.fromJson(Map<String, dynamic> json) => BaseUserData(
        uid: json["uid"],
        username: json["username"],
        email: json["email"],
        traits: List<String>.from(
            (json["traits"] ?? const <String>[]).map((x) => x)),
        freeText: json["freeText"] ?? '',
        followedBloggerIds: List<String>.from(
            (json["followedBloggerIds"] ?? const <String>[]).map((x) => x)),
        favoritedPostIds: List<String>.from(
            (json["favoritedPostIds"] ?? const <String>[]).map((x) => x)),
        favoritedConversationIds: List<String>.from(
            (json["favoritedConversationIds"] ?? const <String>[])
                .map((x) => x)),
        likedPostIds: List<String>.from(
            (json["likedPostIds"] ?? const <String>[]).map((x) => x)),
        followersCount: json["followersCount"] ?? 0,
        followingCount: json["followingCount"] ?? 0,
        postsCount: json["postsCount"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "username": username,
        "email": email,
        "traits": List<dynamic>.from(traits.map((x) => x)),
        "freeText": freeText,
        "followedBloggerIds":
            List<dynamic>.from(followedBloggerIds.map((x) => x)),
        "favoritedPostIds": List<dynamic>.from(favoritedPostIds.map((x) => x)),
        "favoritedConversationIds":
            List<dynamic>.from(favoritedConversationIds.map((x) => x)),
        "likedPostIds": List<dynamic>.from(likedPostIds.map((x) => x)),
        "followersCount": followersCount,
        "followingCount": followingCount,
        "postsCount": postsCount,
      };
}
