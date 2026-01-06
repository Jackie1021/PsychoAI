import 'package:flutter/material.dart';
import 'package:flutter_app/models/user_data.dart';

/// Card sections that can be displayed
enum CardSection {
  header,        // Avatar + basic info
  bio,           // Personal bio
  traits,        // Trait tags
  stats,         // Statistics
  featuredPosts, // Featured posts
  matches,       // Match records
  social,        // Social links
}

extension CardSectionExtension on CardSection {
  String get displayName {
    switch (this) {
      case CardSection.header:
        return 'Header';
      case CardSection.bio:
        return 'Bio';
      case CardSection.traits:
        return 'Traits';
      case CardSection.stats:
        return 'Stats';
      case CardSection.featuredPosts:
        return 'Featured Posts';
      case CardSection.matches:
        return 'Match Records';
      case CardSection.social:
        return 'Social Links';
    }
  }

  IconData get icon {
    switch (this) {
      case CardSection.header:
        return Icons.person;
      case CardSection.bio:
        return Icons.description;
      case CardSection.traits:
        return Icons.label;
      case CardSection.stats:
        return Icons.analytics;
      case CardSection.featuredPosts:
        return Icons.photo_library;
      case CardSection.matches:
        return Icons.favorite;
      case CardSection.social:
        return Icons.link;
    }
  }
}

/// Access level for profile card sections
enum AccessLevel {
  public,          // Everyone can see
  friendsOnly,     // Only friends
  subscribersOnly, // Only subscribers
  private,         // Only self
}

/// Theme style for profile card
enum ThemeStyle {
  minimalist,   // Simple and clean
  elegant,      // Elegant with gradients
  vibrant,      // Colorful and energetic
  professional, // Professional look (Premium)
  artistic,     // Artistic with custom background (Premium)
  custom,       // Fully customizable (Pro)
}

extension ThemeStyleExtension on ThemeStyle {
  String get displayName {
    switch (this) {
      case ThemeStyle.minimalist:
        return 'Minimalist';
      case ThemeStyle.elegant:
        return 'Elegant';
      case ThemeStyle.vibrant:
        return 'Vibrant';
      case ThemeStyle.professional:
        return 'Professional';
      case ThemeStyle.artistic:
        return 'Artistic';
      case ThemeStyle.custom:
        return 'Custom';
    }
  }

  bool get isPremium {
    return this == ThemeStyle.professional || 
           this == ThemeStyle.artistic || 
           this == ThemeStyle.custom;
  }

  bool get requiresPro {
    return this == ThemeStyle.custom;
  }
}

/// Card layout type
enum CardLayout {
  vertical,   // Vertical scrolling
  horizontal, // Horizontal layout
  grid,       // Grid-based cards
}

/// Background type for profile card
enum BackgroundType {
  solid,    // Solid color
  gradient, // Gradient
  image,    // Custom image
}

/// Profile card theme configuration
class ProfileCardTheme {
  final String id;
  final String name;
  final ThemeStyle style;
  final CardLayout layout;
  final BackgroundType backgroundType;
  final List<Color>? gradientColors;
  final String? backgroundImageUrl;
  final Color? solidColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final bool showDecorations;
  final double borderRadius;
  final double padding;

  const ProfileCardTheme({
    required this.id,
    required this.name,
    required this.style,
    this.layout = CardLayout.vertical,
    this.backgroundType = BackgroundType.gradient,
    this.gradientColors,
    this.backgroundImageUrl,
    this.solidColor,
    this.primaryTextColor = Colors.black87,
    this.secondaryTextColor = Colors.black54,
    this.accentColor = const Color(0xFF992121),
    this.showDecorations = true,
    this.borderRadius = 16.0,
    this.padding = 16.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style.name,
        'layout': layout.name,
        'backgroundType': backgroundType.name,
        'gradientColors': gradientColors?.map((c) => c.value).toList(),
        'backgroundImageUrl': backgroundImageUrl,
        'solidColor': solidColor?.value,
        'primaryTextColor': primaryTextColor.value,
        'secondaryTextColor': secondaryTextColor.value,
        'accentColor': accentColor.value,
        'showDecorations': showDecorations,
        'borderRadius': borderRadius,
        'padding': padding,
      };

  factory ProfileCardTheme.fromJson(Map<String, dynamic> json) {
    return ProfileCardTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      style: ThemeStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => ThemeStyle.elegant,
      ),
      layout: CardLayout.values.firstWhere(
        (e) => e.name == json['layout'],
        orElse: () => CardLayout.vertical,
      ),
      backgroundType: BackgroundType.values.firstWhere(
        (e) => e.name == json['backgroundType'],
        orElse: () => BackgroundType.gradient,
      ),
      gradientColors: (json['gradientColors'] as List?)
          ?.map((c) => Color(c as int))
          .toList(),
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      solidColor: json['solidColor'] != null 
          ? Color(json['solidColor'] as int) 
          : null,
      primaryTextColor: json['primaryTextColor'] != null
          ? Color(json['primaryTextColor'] as int)
          : Colors.black87,
      secondaryTextColor: json['secondaryTextColor'] != null
          ? Color(json['secondaryTextColor'] as int)
          : Colors.black54,
      accentColor: json['accentColor'] != null
          ? Color(json['accentColor'] as int)
          : const Color(0xFF992121),
      showDecorations: json['showDecorations'] as bool? ?? true,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 16.0,
      padding: (json['padding'] as num?)?.toDouble() ?? 16.0,
    );
  }

  /// Predefined themes
  static ProfileCardTheme get minimalist => ProfileCardTheme(
        id: 'minimalist',
        name: 'Minimalist',
        style: ThemeStyle.minimalist,
        backgroundType: BackgroundType.solid,
        solidColor: Colors.white,
        primaryTextColor: Colors.black87,
        secondaryTextColor: Colors.black54,
        accentColor: Colors.black,
        showDecorations: false,
      );

  static ProfileCardTheme get elegant => ProfileCardTheme(
        id: 'elegant',
        name: 'Elegant',
        style: ThemeStyle.elegant,
        backgroundType: BackgroundType.gradient,
        gradientColors: [
          const Color(0xFFF5E6F7),
          const Color(0xFFFFF0F5),
        ],
        primaryTextColor: const Color(0xFF2D1B2E),
        secondaryTextColor: const Color(0xFF6B4C6F),
        accentColor: const Color(0xFF992121),
      );

  static ProfileCardTheme get vibrant => ProfileCardTheme(
        id: 'vibrant',
        name: 'Vibrant',
        style: ThemeStyle.vibrant,
        backgroundType: BackgroundType.gradient,
        gradientColors: [
          const Color(0xFFFF6B9D),
          const Color(0xFFC06C84),
        ],
        primaryTextColor: Colors.white,
        secondaryTextColor: const Color(0xFFFFF0F5),
        accentColor: Colors.yellow,
      );

  static ProfileCardTheme get professional => ProfileCardTheme(
        id: 'professional',
        name: 'Professional',
        style: ThemeStyle.professional,
        backgroundType: BackgroundType.gradient,
        gradientColors: [
          const Color(0xFF1A1A2E),
          const Color(0xFF16213E),
        ],
        primaryTextColor: Colors.white,
        secondaryTextColor: const Color(0xFFB8B8B8),
        accentColor: const Color(0xFFD4AF37),
      );

  static List<ProfileCardTheme> get defaultThemes => [
        minimalist,
        elegant,
        vibrant,
        professional,
      ];
}

/// Section configuration for profile card
class SectionConfig {
  final bool isVisible;
  final AccessLevel accessLevel;
  final int order;

  const SectionConfig({
    this.isVisible = true,
    this.accessLevel = AccessLevel.public,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'isVisible': isVisible,
        'accessLevel': accessLevel.name,
        'order': order,
      };

  factory SectionConfig.fromJson(Map<String, dynamic> json) {
    return SectionConfig(
      isVisible: json['isVisible'] as bool? ?? true,
      accessLevel: AccessLevel.values.firstWhere(
        (e) => e.name == json['accessLevel'],
        orElse: () => AccessLevel.public,
      ),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  SectionConfig copyWith({
    bool? isVisible,
    AccessLevel? accessLevel,
    int? order,
  }) {
    return SectionConfig(
      isVisible: isVisible ?? this.isVisible,
      accessLevel: accessLevel ?? this.accessLevel,
      order: order ?? this.order,
    );
  }
}

/// Profile card customization
class ProfileCardCustomization {
  final ProfileCardTheme theme;
  final Map<CardSection, SectionConfig> sectionConfigs;
  final String? customBackgroundUrl;

  const ProfileCardCustomization({
    required this.theme,
    this.sectionConfigs = const {},
    this.customBackgroundUrl,
  });

  Map<String, dynamic> toJson() => {
        'theme': theme.toJson(),
        'sectionConfigs': sectionConfigs.map(
          (key, value) => MapEntry(key.name, value.toJson()),
        ),
        'customBackgroundUrl': customBackgroundUrl,
      };

  factory ProfileCardCustomization.fromJson(Map<String, dynamic> json) {
    final sectionConfigsJson = json['sectionConfigs'] as Map<String, dynamic>?;
    final sectionConfigs = <CardSection, SectionConfig>{};
    
    if (sectionConfigsJson != null) {
      sectionConfigsJson.forEach((key, value) {
        final section = CardSection.values.firstWhere(
          (e) => e.name == key,
          orElse: () => CardSection.header,
        );
        sectionConfigs[section] = SectionConfig.fromJson(value as Map<String, dynamic>);
      });
    }

    return ProfileCardCustomization(
      theme: ProfileCardTheme.fromJson(json['theme'] as Map<String, dynamic>),
      sectionConfigs: sectionConfigs,
      customBackgroundUrl: json['customBackgroundUrl'] as String?,
    );
  }

  ProfileCardCustomization copyWith({
    ProfileCardTheme? theme,
    Map<CardSection, SectionConfig>? sectionConfigs,
    String? customBackgroundUrl,
  }) {
    return ProfileCardCustomization(
      theme: theme ?? this.theme,
      sectionConfigs: sectionConfigs ?? this.sectionConfigs,
      customBackgroundUrl: customBackgroundUrl ?? this.customBackgroundUrl,
    );
  }

  /// Get ordered list of visible sections
  List<CardSection> get orderedSections {
    final sections = sectionConfigs.entries
        .where((e) => e.value.isVisible)
        .map((e) => MapEntry(e.key, e.value.order))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sections.map((e) => e.key).toList();
  }

  /// Check if section is accessible for given user
  bool isSectionAccessible(CardSection section, {
    required bool isOwner,
    required bool isFriend,
    required bool hasSubscription,
  }) {
    final config = sectionConfigs[section];
    if (config == null || !config.isVisible) return false;
    
    if (isOwner) return true;
    
    switch (config.accessLevel) {
      case AccessLevel.public:
        return true;
      case AccessLevel.friendsOnly:
        return isFriend;
      case AccessLevel.subscribersOnly:
        return hasSubscription;
      case AccessLevel.private:
        return false;
    }
  }
}

/// Privacy settings for profile card
class ProfileCardPrivacySettings {
  final bool showTraits;
  final bool showPosts;
  final bool showMatches;
  final bool showStats;
  final bool allowStrangerAccess;
  final bool requireSubscription;

  const ProfileCardPrivacySettings({
    this.showTraits = true,
    this.showPosts = true,
    this.showMatches = true,
    this.showStats = true,
    this.allowStrangerAccess = true,
    this.requireSubscription = false,
  });

  Map<String, dynamic> toJson() => {
        'showTraits': showTraits,
        'showPosts': showPosts,
        'showMatches': showMatches,
        'showStats': showStats,
        'allowStrangerAccess': allowStrangerAccess,
        'requireSubscription': requireSubscription,
      };

  factory ProfileCardPrivacySettings.fromJson(Map<String, dynamic> json) {
    return ProfileCardPrivacySettings(
      showTraits: json['showTraits'] as bool? ?? true,
      showPosts: json['showPosts'] as bool? ?? true,
      showMatches: json['showMatches'] as bool? ?? true,
      showStats: json['showStats'] as bool? ?? true,
      allowStrangerAccess: json['allowStrangerAccess'] as bool? ?? true,
      requireSubscription: json['requireSubscription'] as bool? ?? false,
    );
  }

  ProfileCardPrivacySettings copyWith({
    bool? showTraits,
    bool? showPosts,
    bool? showMatches,
    bool? showStats,
    bool? allowStrangerAccess,
    bool? requireSubscription,
  }) {
    return ProfileCardPrivacySettings(
      showTraits: showTraits ?? this.showTraits,
      showPosts: showPosts ?? this.showPosts,
      showMatches: showMatches ?? this.showMatches,
      showStats: showStats ?? this.showStats,
      allowStrangerAccess: allowStrangerAccess ?? this.allowStrangerAccess,
      requireSubscription: requireSubscription ?? this.requireSubscription,
    );
  }
}

/// Profile card model - enhanced version
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
  final ProfileCardCustomization customization;
  final DateTime lastUpdated;
  final MembershipTier membershipTier;
  final int viewCount;
  final int likeCount;
  final int followersCount;
  final int followingCount;

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
    ProfileCardCustomization? customization,
    required this.lastUpdated,
    this.membershipTier = MembershipTier.free,
    this.viewCount = 0,
    this.likeCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  }) : customization = customization ?? ProfileCardCustomization(
          theme: ProfileCardTheme.elegant,
        );

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
    ProfileCardCustomization? customization,
    DateTime? lastUpdated,
    MembershipTier? membershipTier,
    int? viewCount,
    int? likeCount,
    int? followersCount,
    int? followingCount,
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
      customization: customization ?? this.customization,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      membershipTier: membershipTier ?? this.membershipTier,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
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
        'customization': customization.toJson(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'membershipTier': membershipTier.name,
        'viewCount': viewCount,
        'likeCount': likeCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
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
      customization: json['customization'] != null
          ? ProfileCardCustomization.fromJson(
              json['customization'] as Map<String, dynamic>)
          : ProfileCardCustomization(
              theme: ProfileCardTheme.elegant,
            ),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      membershipTier: tier,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
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
      followersCount: userData.followersCount,
      followingCount: userData.followingCount,
    );
  }
}
