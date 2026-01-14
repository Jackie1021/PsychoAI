
import 'package:flutter/material.dart';

class ProfileAnalysis {
  final List<String> keyInsights;
  
  const ProfileAnalysis({
    required this.keyInsights,
  });
  
  factory ProfileAnalysis.fromMap(Map<String, dynamic> data) {
    return ProfileAnalysis(
      keyInsights: List<String>.from(data['keyInsights'] ?? []),
    );
  }
}

class MatchProfile {
  final String id;
  final String name;
  final String tagline;
  final Color accent;
  final ProfileAnalysis? analysis;

  const MatchProfile({
    required this.id,
    required this.name,
    required this.tagline,
    required this.accent,
    this.analysis,
  });
  
  factory MatchProfile.fromFirestore(Map<String, dynamic> data) {
    return MatchProfile(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      tagline: data['tagline'] ?? '',
      accent: Color(data['accent'] ?? 0xFF6200EA),
      analysis: data['analysis'] != null 
          ? ProfileAnalysis.fromMap(data['analysis'])
          : null,
    );
  }
}
