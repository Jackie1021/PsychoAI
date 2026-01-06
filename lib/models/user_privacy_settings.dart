/// Visibility level for user profile
enum ProfileVisibility {
  public,
  friendsOnly,
  private;

  String get displayName {
    switch (this) {
      case ProfileVisibility.public:
        return 'Public';
      case ProfileVisibility.friendsOnly:
        return 'Friends Only';
      case ProfileVisibility.private:
        return 'Private';
    }
  }
}

/// Default visibility for posts
enum PostVisibility {
  public,
  followers,
  private;

  String get displayName {
    switch (this) {
      case PostVisibility.public:
        return 'Public';
      case PostVisibility.followers:
        return 'Followers Only';
      case PostVisibility.private:
        return 'Private';
    }
  }
}

/// Comprehensive privacy settings for users
class UserPrivacySettings {
  // Profile visibility
  final ProfileVisibility profileVisibility;
  final bool showAvatarToStrangers;
  final bool showBioToStrangers;
  final bool showTraitsToStrangers;

  // Content visibility
  final PostVisibility defaultPostVisibility;
  final bool allowComments;
  final bool allowShare;

  // Interaction settings
  final bool allowMessageFromStrangers;
  final bool allowMatchFromStrangers;

  // Profile card settings
  final bool enableProfileCard;
  final bool profileCardRequiresSubscription;

  // Blocked users
  final List<String> blockedUserIds;

  const UserPrivacySettings({
    this.profileVisibility = ProfileVisibility.public,
    this.showAvatarToStrangers = true,
    this.showBioToStrangers = true,
    this.showTraitsToStrangers = true,
    this.defaultPostVisibility = PostVisibility.public,
    this.allowComments = true,
    this.allowShare = true,
    this.allowMessageFromStrangers = true,
    this.allowMatchFromStrangers = true,
    this.enableProfileCard = true,
    this.profileCardRequiresSubscription = false,
    this.blockedUserIds = const [],
  });

  UserPrivacySettings copyWith({
    ProfileVisibility? profileVisibility,
    bool? showAvatarToStrangers,
    bool? showBioToStrangers,
    bool? showTraitsToStrangers,
    PostVisibility? defaultPostVisibility,
    bool? allowComments,
    bool? allowShare,
    bool? allowMessageFromStrangers,
    bool? allowMatchFromStrangers,
    bool? enableProfileCard,
    bool? profileCardRequiresSubscription,
    List<String>? blockedUserIds,
  }) {
    return UserPrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showAvatarToStrangers:
          showAvatarToStrangers ?? this.showAvatarToStrangers,
      showBioToStrangers: showBioToStrangers ?? this.showBioToStrangers,
      showTraitsToStrangers:
          showTraitsToStrangers ?? this.showTraitsToStrangers,
      defaultPostVisibility:
          defaultPostVisibility ?? this.defaultPostVisibility,
      allowComments: allowComments ?? this.allowComments,
      allowShare: allowShare ?? this.allowShare,
      allowMessageFromStrangers:
          allowMessageFromStrangers ?? this.allowMessageFromStrangers,
      allowMatchFromStrangers:
          allowMatchFromStrangers ?? this.allowMatchFromStrangers,
      enableProfileCard: enableProfileCard ?? this.enableProfileCard,
      profileCardRequiresSubscription: profileCardRequiresSubscription ??
          this.profileCardRequiresSubscription,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'profileVisibility': profileVisibility.name,
        'showAvatarToStrangers': showAvatarToStrangers,
        'showBioToStrangers': showBioToStrangers,
        'showTraitsToStrangers': showTraitsToStrangers,
        'defaultPostVisibility': defaultPostVisibility.name,
        'allowComments': allowComments,
        'allowShare': allowShare,
        'allowMessageFromStrangers': allowMessageFromStrangers,
        'allowMatchFromStrangers': allowMatchFromStrangers,
        'enableProfileCard': enableProfileCard,
        'profileCardRequiresSubscription': profileCardRequiresSubscription,
        'blockedUserIds': blockedUserIds,
      };

  factory UserPrivacySettings.fromJson(Map<String, dynamic> json) {
    ProfileVisibility profileVis = ProfileVisibility.public;
    final profileVisString = json['profileVisibility'] as String?;
    if (profileVisString != null) {
      profileVis = ProfileVisibility.values.firstWhere(
        (e) => e.name == profileVisString,
        orElse: () => ProfileVisibility.public,
      );
    }

    PostVisibility postVis = PostVisibility.public;
    final postVisString = json['defaultPostVisibility'] as String?;
    if (postVisString != null) {
      postVis = PostVisibility.values.firstWhere(
        (e) => e.name == postVisString,
        orElse: () => PostVisibility.public,
      );
    }

    return UserPrivacySettings(
      profileVisibility: profileVis,
      showAvatarToStrangers: json['showAvatarToStrangers'] as bool? ?? true,
      showBioToStrangers: json['showBioToStrangers'] as bool? ?? true,
      showTraitsToStrangers: json['showTraitsToStrangers'] as bool? ?? true,
      defaultPostVisibility: postVis,
      allowComments: json['allowComments'] as bool? ?? true,
      allowShare: json['allowShare'] as bool? ?? true,
      allowMessageFromStrangers:
          json['allowMessageFromStrangers'] as bool? ?? true,
      allowMatchFromStrangers:
          json['allowMatchFromStrangers'] as bool? ?? true,
      enableProfileCard: json['enableProfileCard'] as bool? ?? true,
      profileCardRequiresSubscription:
          json['profileCardRequiresSubscription'] as bool? ?? false,
      blockedUserIds:
          List<String>.from(json['blockedUserIds'] as List? ?? const []),
    );
  }

  /// Check if a user is blocked
  bool isUserBlocked(String userId) {
    return blockedUserIds.contains(userId);
  }

  /// Add user to block list
  UserPrivacySettings blockUser(String userId) {
    if (blockedUserIds.contains(userId)) return this;
    return copyWith(
      blockedUserIds: [...blockedUserIds, userId],
    );
  }

  /// Remove user from block list
  UserPrivacySettings unblockUser(String userId) {
    return copyWith(
      blockedUserIds: blockedUserIds.where((id) => id != userId).toList(),
    );
  }
}
