import 'package:flutter/material.dart';

// Helper function to convert hex color string to Color object
Color _colorFromHex(String hexColor) {
  final hexCode = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

/// Represents the entire theme structure fetched from a remote source.
class AppTheme {
  final String name;
  final ThemeColors colors;
  final ThemeAssets assets;
  final ThemeFeatures features;

  AppTheme({
    required this.name,
    required this.colors,
    required this.assets,
    required this.features,
  });

  /// A factory to create a default, hardcoded theme for fallback.
  factory AppTheme.defaultTheme() {
    return AppTheme(
      name: 'Default',
      colors: ThemeColors.defaultColors(),
      assets: ThemeAssets.defaultAssets(),
      features: ThemeFeatures(enableSnowEffect: false),
    );
  }

  /// A factory to create an AppTheme from a Firestore document.
  factory AppTheme.fromFirestore(Map<String, dynamic> data) {
    return AppTheme(
      name: data['name'] ?? 'Unnamed Theme',
      colors: ThemeColors.fromMap(data['colors'] ?? {}),
      assets: ThemeAssets.fromMap(data['assets'] ?? {}),
      features: ThemeFeatures.fromMap(data['features'] ?? {}),
    );
  }
}

/// Holds all the color definitions for the theme.
class ThemeColors {
  final Color primary;
  final Color accent;
  final Color background;
  final Color cardBackground;
  final Color textColor;
  final List<Color> bubbleGradient;

  ThemeColors({
    required this.primary,
    required this.accent,
    required this.background,
    required this.cardBackground,
    required this.textColor,
    required this.bubbleGradient,
  });

  factory ThemeColors.defaultColors() {
    return ThemeColors(
      primary: const Color(0xFF992121),
      accent: const Color(0xFFE6A5A5),
      background: const Color(0xFFFBF9F7),
      cardBackground: const Color(0xFFFDFBFA),
      textColor: const Color(0xFF4F4A45),
      bubbleGradient: [const Color(0xFF992121), const Color(0xFFE6A5A5)],
    );
  }

  factory ThemeColors.fromMap(Map<String, dynamic> map) {
    return ThemeColors(
      primary: _colorFromHex(map['primary'] ?? '#992121'),
      accent: _colorFromHex(map['accent'] ?? '#E6A5A5'),
      background: _colorFromHex(map['background'] ?? '#FBF9F7'),
      cardBackground: _colorFromHex(map['cardBackground'] ?? '#FDFBFA'),
      textColor: _colorFromHex(map['textColor'] ?? '#4F4A45'),
      bubbleGradient: (map['bubbleGradient'] as List<dynamic>?)
              ?.map((hex) => _colorFromHex(hex as String))
              .toList() ??
          [_colorFromHex('#992121'), _colorFromHex('#E6A5A5')],
    );
  }
}

/// Holds all the asset URLs for the theme.
class ThemeAssets {
  final String matchBubble;
  final String homeBackground;
  final String appLogo;
  final String fallingParticle;
  // Navigation icons
  final String postIcon;
  final String matchIcon;
  final String profileIcon;


  ThemeAssets({
    required this.matchBubble,
    required this.homeBackground,
    required this.appLogo,
    required this.fallingParticle,
    required this.postIcon,
    required this.matchIcon,
    required this.profileIcon,
  });

  factory ThemeAssets.defaultAssets() {
    // In default theme, we use local assets.
    return ThemeAssets(
      matchBubble: 'assets/svgs/match.svg',
      homeBackground: '', // No background by default
      appLogo: 'assets/svgs/littleworld.svg',
      fallingParticle: '', // No particle effect by default
      postIcon: 'assets/svgs/post.svg',
      matchIcon: 'assets/svgs/match.svg',
      profileIcon: 'assets/svgs/profile.svg',
    );
  }

  factory ThemeAssets.fromMap(Map<String, dynamic> map) {
    // For remote themes, these will be URLs.
    return ThemeAssets(
      matchBubble: map['matchBubble'] ?? '',
      homeBackground: map['homeBackground'] ?? '',
      appLogo: map['appLogo'] ?? '',
      fallingParticle: map['fallingParticle'] ?? '',
      postIcon: map['postIcon'] ?? '',
      matchIcon: map['matchIcon'] ?? '',
      profileIcon: map['profileIcon'] ?? '',
    );
  }
}


/// Holds feature flags for the theme.
class ThemeFeatures {
  final bool enableSnowEffect;

  ThemeFeatures({required this.enableSnowEffect});

  factory ThemeFeatures.fromMap(Map<String, dynamic> map) {
    return ThemeFeatures(
      enableSnowEffect: map['enableSnowEffect'] ?? false,
    );
  }
}
