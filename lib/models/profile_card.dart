import 'package:flutter_app/models/user_data.dart';

/// Privacy settings for profile card
class ProfileCardPrivacySettings {
  final bool showTraits;
  final bool showPosts;
  final bool showMatches;
  final bool showStats;
  final bool allowStrangerAccess;

  const ProfileCardPrivacySettings({
    this.showTraits = true,
    this.showPosts = true,
    this.showMatches = false,
    this.showStats = true,
    this.allowStrangerAccess = true,
  });

  Map<String, dynamic> toJson() => {
        'showTraits': showTraits,
        'showPosts': showPosts,
        'showMatches': showMatches,
        'showStats': showStats,
        'allowStrangerAccess': allowStrangerAccess,
      };

  factory ProfileCardPrivacySettings.fromJson(Map<String, dynamic> json) {
    return ProfileCardPrivacySettings(
      showTraits: json['showTraits'] as bool? ?? true,
      showPosts: json['showPosts'] as bool? ?? true,
      showMatches: json['showMatches'] as bool? ?? false,
      showStats: json['showStats'] as bool? ?? true,
      allowStrangerAccess: json['allowStrangerAccess'] as bool? ?? true,
    );
  }
}

/// Profile card model - like a business card for social interaction
class ProfileCard {
  final String uid;
  final String username;
  final String? avatarUrl;
  final String bio;
  final List<String> highlightedTraits;
  final int postsCount;
  final int matchesCount;
  final List<String> featuredPostIds;
  final List<String> publicMatchIds;
  final ProfileCardPrivacySettings privacy;
  final DateTime lastUpdated;
  final MembershipTier membershipTier;
  final int viewCount;
  final int likeCount;

  const ProfileCard({
    required this.uid,
    required this.username,
    this.avatarUrl,
    this.bio = '',
    this.highlightedTraits = const [],
    this.postsCount = 0,
    this.matchesCount = 0,
    this.featuredPostIds = const [],
    this.publicMatchIds = const [],
    this.privacy = const ProfileCardPrivacySettings(),
    required this.lastUpdated,
    this.membershipTier = MembershipTier.free,
    this.viewCount = 0,
    this.likeCount = 0,
  });

  ProfileCard copyWith({
    String? username,
    String? avatarUrl,
    String? bio,
    List<String>? highlightedTraits,
    int? postsCount,
    int? matchesCount,
    List<String>? featuredPostIds,
    List<String>? publicMatchIds,
    ProfileCardPrivacySettings? privacy,
    DateTime? lastUpdated,
    MembershipTier? membershipTier,
    int? viewCount,
    int? likeCount,
  }) {
    return ProfileCard(
      uid: uid,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      highlightedTraits: highlightedTraits ?? this.highlightedTraits,
      postsCount: postsCount ?? this.postsCount,
      matchesCount: matchesCount ?? this.matchesCount,
      featuredPostIds: featuredPostIds ?? this.featuredPostIds,
      publicMatchIds: publicMatchIds ?? this.publicMatchIds,
      privacy: privacy ?? this.privacy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      membershipTier: membershipTier ?? this.membershipTier,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'highlightedTraits': highlightedTraits,
        'postsCount': postsCount,
        'matchesCount': matchesCount,
        'featuredPostIds': featuredPostIds,
        'publicMatchIds': publicMatchIds,
        'privacy': privacy.toJson(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'membershipTier': membershipTier.name,
        'viewCount': viewCount,
        'likeCount': likeCount,
      };

  factory ProfileCard.fromJson(Map<String, dynamic> json) {
    MembershipTier tier = MembershipTier.free;
    final tierString = json['membershipTier'] as String?;
    if (tierString != null) {
      tier = MembershipTier.values.firstWhere(
        (e) => e.name == tierString,
        orElse: () => MembershipTier.free,
      );
    }

    return ProfileCard(
      uid: json['uid'] as String,
      username: json['username'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      highlightedTraits: List<String>.from(
          json['highlightedTraits'] as List? ?? const []),
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      matchesCount: (json['matchesCount'] as num?)?.toInt() ?? 0,
      featuredPostIds:
          List<String>.from(json['featuredPostIds'] as List? ?? const []),
      publicMatchIds:
          List<String>.from(json['publicMatchIds'] as List? ?? const []),
      privacy: json['privacy'] != null
          ? ProfileCardPrivacySettings.fromJson(
              json['privacy'] as Map<String, dynamic>)
          : const ProfileCardPrivacySettings(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      membershipTier: tier,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Create profile card from user data
  factory ProfileCard.fromUserData(UserData userData) {
    return ProfileCard(
      uid: userData.uid,
      username: userData.username,
      avatarUrl: userData.avatarUrl,
      bio: userData.freeText,
      highlightedTraits:
          userData.traits.take(5).toList(), // Max 5 highlighted traits
      postsCount: userData.postsCount,
      matchesCount: 0, // Will be populated separately
      lastUpdated: DateTime.now(),
      membershipTier: userData.membershipTier,
    );
  }
}
