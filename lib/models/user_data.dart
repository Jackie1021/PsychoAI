import 'dart:typed_data';
import 'package:flutter_app/models/post.dart';
import 'base_user_data.dart';

/// Membership tier enum
enum MembershipTier {
  free,
  premium,
  pro;

  String get displayName {
    switch (this) {
      case MembershipTier.free:
        return 'Free';
      case MembershipTier.premium:
        return 'Premium';
      case MembershipTier.pro:
        return 'Pro';
    }
  }
}

/// A comprehensive data model for a user's profile and activities within the app.
/// Extends BaseUserData to inherit common fields that are shared with scripts.
class UserData extends BaseUserData {
  final Uint8List? portrait; // The user's hand-drawn portrait
  final String? avatarUrl; // Avatar URL from backend
  final List<Post> userPosts; // Posts created by the user
  final DateTime? lastActive; // Last active timestamp
  final bool isSuspended; // Whether user is suspended
  final int reportCount; // Number of reports against this user
  
  // Membership fields
  final MembershipTier membershipTier;
  final DateTime? membershipExpiry;
  final String? subscriptionId;

  UserData({
    required super.uid,
    required super.username,
    this.portrait,
    this.avatarUrl,
    super.traits,
    super.freeText,
    super.followedBloggerIds,
    super.favoritedPostIds,
    super.likedPostIds,
    this.userPosts = const [],
    super.favoritedConversationIds,
    super.followersCount,
    super.followingCount,
    super.postsCount,
    this.lastActive,
    this.isSuspended = false,
    this.reportCount = 0,
    this.membershipTier = MembershipTier.free,
    this.membershipExpiry,
    this.subscriptionId,
  });
  
  // Check if user has active membership
  bool get hasActiveMembership {
    if (membershipTier == MembershipTier.free) return false;
    if (membershipExpiry == null) return true; // Lifetime membership
    return membershipExpiry!.isAfter(DateTime.now());
  }
  
  // Get effective membership tier (considering expiry)
  MembershipTier get effectiveTier {
    return hasActiveMembership ? membershipTier : MembershipTier.free;
  }

  // Method to create a copy with updated values, useful for state management.
  UserData copyWith({
    String? username,
    Uint8List? portrait,
    String? avatarUrl,
    List<String>? traits,
    String? freeText,
    List<String>? followedBloggerIds,
    List<String>? favoritedPostIds,
    List<String>? likedPostIds,
    List<Post>? userPosts,
    List<String>? favoritedConversationIds,
    DateTime? lastActive,
    bool? isSuspended,
    int? reportCount,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    MembershipTier? membershipTier,
    DateTime? membershipExpiry,
    String? subscriptionId,
  }) {
    return UserData(
      uid: uid,
      username: username ?? this.username,
      portrait: portrait ?? this.portrait,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      traits: traits ?? this.traits,
      freeText: freeText ?? this.freeText,
      followedBloggerIds: followedBloggerIds ?? this.followedBloggerIds,
      favoritedPostIds: favoritedPostIds ?? this.favoritedPostIds,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      userPosts: userPosts ?? this.userPosts,
      favoritedConversationIds:
          favoritedConversationIds ?? this.favoritedConversationIds,
      lastActive: lastActive ?? this.lastActive,
      isSuspended: isSuspended ?? this.isSuspended,
      reportCount: reportCount ?? this.reportCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      membershipTier: membershipTier ?? this.membershipTier,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    // Parse membership tier
    MembershipTier membershipTier = MembershipTier.free;
    final tierString = json["membershipTier"] as String?;
    if (tierString != null) {
      membershipTier = MembershipTier.values.firstWhere(
        (e) => e.name == tierString,
        orElse: () => MembershipTier.free,
      );
    }
    
    // Parse membership expiry
    DateTime? membershipExpiry;
    if (json["membershipExpiry"] != null) {
      if (json["membershipExpiry"] is String) {
        membershipExpiry = DateTime.tryParse(json["membershipExpiry"]);
      } else if (json["membershipExpiry"] is int) {
        membershipExpiry = DateTime.fromMillisecondsSinceEpoch(json["membershipExpiry"]);
      }
    }
    
    return UserData(
      uid: (json["uid"] ?? json["id"] ?? '') as String,
      username: json["username"] as String? ?? 'Unknown',
      portrait: json["portrait"] as Uint8List?,
      avatarUrl: json["avatarUrl"] as String?,
      traits: List<String>.from(
          (json["traits"] ?? const <String>[]).map((x) => x.toString())),
      freeText: json["freeText"] as String? ?? json["bio"] as String? ?? "",
      followedBloggerIds: List<String>.from(
          (json["followedBloggerIds"] ?? const <String>[])
              .map((x) => x.toString())),
      favoritedPostIds: List<String>.from(
          (json["favoritedPostIds"] ?? const <String>[])
              .map((x) => x.toString())),
      likedPostIds: List<String>.from(
          (json["likedPostIds"] ?? const <String>[])
              .map((x) => x.toString())),
      userPosts: json["userPosts"] != null
          ? List<Post>.from(
              (json["userPosts"] as List).map((x) => Post.fromJson(x)))
          : const [],
      favoritedConversationIds: List<String>.from(
          (json["favoritedConversationIds"] ?? const <String>[])
              .map((x) => x.toString())),
      lastActive: json["lastActive"] != null
          ? DateTime.tryParse(json["lastActive"].toString())
          : null,
      isSuspended: json["isSuspended"] as bool? ?? false,
      reportCount: (json["reportCount"] as num?)?.toInt() ?? 0,
      followersCount: (json["followersCount"] as num?)?.toInt() ?? 0,
      followingCount: (json["followingCount"] as num?)?.toInt() ?? 0,
      postsCount: (json["postsCount"] as num?)?.toInt() ?? 0,
      membershipTier: membershipTier,
      membershipExpiry: membershipExpiry,
      subscriptionId: json["subscriptionId"] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "portrait": portrait,
        "avatarUrl": avatarUrl,
        "userPosts": List<dynamic>.from(userPosts.map((x) => x.toJson())),
        "lastActive": lastActive?.toIso8601String(),
        "isSuspended": isSuspended,
        "reportCount": reportCount,
        "membershipTier": membershipTier.name,
        "membershipExpiry": membershipExpiry?.toIso8601String(),
        "subscriptionId": subscriptionId,
      };
}
