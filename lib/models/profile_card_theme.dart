/// Profile card theme and customization
class ProfileCardTheme {
  final String id;
  final String name;
  final ProfileCardStyle style;
  final List<String> gradientColors;
  final String? backgroundImageUrl;
  final ProfileCardLayout layout;

  const ProfileCardTheme({
    required this.id,
    required this.name,
    required this.style,
    this.gradientColors = const [],
    this.backgroundImageUrl,
    this.layout = ProfileCardLayout.standard,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style.name,
        'gradientColors': gradientColors,
        'backgroundImageUrl': backgroundImageUrl,
        'layout': layout.name,
      };

  factory ProfileCardTheme.fromJson(Map<String, dynamic> json) {
    return ProfileCardTheme(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Default',
      style: ProfileCardStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => ProfileCardStyle.gradient,
      ),
      gradientColors:
          List<String>.from(json['gradientColors'] as List? ?? const []),
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      layout: ProfileCardLayout.values.firstWhere(
        (e) => e.name == json['layout'],
        orElse: () => ProfileCardLayout.standard,
      ),
    );
  }

  // Predefined themes
  static const ProfileCardTheme sunset = ProfileCardTheme(
    id: 'sunset',
    name: 'Sunset',
    style: ProfileCardStyle.gradient,
    gradientColors: ['#FF6B6B', '#FFA07A', '#FFD93D'],
  );

  static const ProfileCardTheme ocean = ProfileCardTheme(
    id: 'ocean',
    name: 'Ocean',
    style: ProfileCardStyle.gradient,
    gradientColors: ['#667eea', '#764ba2', '#f093fb'],
  );

  static const ProfileCardTheme forest = ProfileCardTheme(
    id: 'forest',
    name: 'Forest',
    style: ProfileCardStyle.gradient,
    gradientColors: ['#134E5E', '#71B280'],
  );

  static const ProfileCardTheme lavender = ProfileCardTheme(
    id: 'lavender',
    name: 'Lavender',
    style: ProfileCardStyle.gradient,
    gradientColors: ['#B06AB3', '#4568DC'],
  );

  static const ProfileCardTheme rose = ProfileCardTheme(
    id: 'rose',
    name: 'Rose Gold',
    style: ProfileCardStyle.gradient,
    gradientColors: ['#ED4264', '#FFEDBC'],
  );

  static const ProfileCardTheme minimal = ProfileCardTheme(
    id: 'minimal',
    name: 'Minimal',
    style: ProfileCardStyle.solid,
    gradientColors: ['#FFFFFF'],
  );

  static const ProfileCardTheme dark = ProfileCardTheme(
    id: 'dark',
    name: 'Dark Mode',
    style: ProfileCardStyle.solid,
    gradientColors: ['#2C3E50'],
  );

  static List<ProfileCardTheme> get allThemes => [
        sunset,
        ocean,
        forest,
        lavender,
        rose,
        minimal,
        dark,
      ];
}

enum ProfileCardStyle {
  gradient,
  solid,
  glassmorphism,
  image,
}

enum ProfileCardLayout {
  standard,
  compact,
  expanded,
  magazine,
}

/// Profile card customization settings
class ProfileCardCustomization {
  final ProfileCardTheme theme;
  final bool showAvatar;
  final bool showBio;
  final bool showTraits;
  final bool showPosts;
  final bool showMatches;
  final bool showStats;
  final List<String> customImages;
  final String? customBackgroundUrl;

  const ProfileCardCustomization({
    this.theme = ProfileCardTheme.sunset,
    this.showAvatar = true,
    this.showBio = true,
    this.showTraits = true,
    this.showPosts = true,
    this.showMatches = false,
    this.showStats = true,
    this.customImages = const [],
    this.customBackgroundUrl,
  });

  ProfileCardCustomization copyWith({
    ProfileCardTheme? theme,
    bool? showAvatar,
    bool? showBio,
    bool? showTraits,
    bool? showPosts,
    bool? showMatches,
    bool? showStats,
    List<String>? customImages,
    String? customBackgroundUrl,
  }) {
    return ProfileCardCustomization(
      theme: theme ?? this.theme,
      showAvatar: showAvatar ?? this.showAvatar,
      showBio: showBio ?? this.showBio,
      showTraits: showTraits ?? this.showTraits,
      showPosts: showPosts ?? this.showPosts,
      showMatches: showMatches ?? this.showMatches,
      showStats: showStats ?? this.showStats,
      customImages: customImages ?? this.customImages,
      customBackgroundUrl: customBackgroundUrl ?? this.customBackgroundUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.toJson(),
        'showAvatar': showAvatar,
        'showBio': showBio,
        'showTraits': showTraits,
        'showPosts': showPosts,
        'showMatches': showMatches,
        'showStats': showStats,
        'customImages': customImages,
        'customBackgroundUrl': customBackgroundUrl,
      };

  factory ProfileCardCustomization.fromJson(Map<String, dynamic> json) {
    return ProfileCardCustomization(
      theme: json['theme'] != null
          ? ProfileCardTheme.fromJson(json['theme'] as Map<String, dynamic>)
          : ProfileCardTheme.sunset,
      showAvatar: json['showAvatar'] as bool? ?? true,
      showBio: json['showBio'] as bool? ?? true,
      showTraits: json['showTraits'] as bool? ?? true,
      showPosts: json['showPosts'] as bool? ?? true,
      showMatches: json['showMatches'] as bool? ?? false,
      showStats: json['showStats'] as bool? ?? true,
      customImages:
          List<String>.from(json['customImages'] as List? ?? const []),
      customBackgroundUrl: json['customBackgroundUrl'] as String?,
    );
  }
}
