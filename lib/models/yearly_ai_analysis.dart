import 'package:flutter_app/models/match_report.dart' show DateRange;

/// AI-generated analysis of yearly match patterns
class YearlyAIAnalysis {
  final String userId;
  final DateRange dateRange;
  final String overallSummary;
  final Map<String, String> insights;
  final List<String> recommendations;
  final Map<String, double> personalityTraits;
  final List<String> topPreferences;
  final DateTime generatedAt;

  YearlyAIAnalysis({
    required this.userId,
    required this.dateRange,
    required this.overallSummary,
    required this.insights,
    required this.recommendations,
    required this.personalityTraits,
    required this.topPreferences,
    required this.generatedAt,
  });

  factory YearlyAIAnalysis.fromJson(Map<String, dynamic> json) {
    return YearlyAIAnalysis(
      userId: json['userId'] as String,
      dateRange: DateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
      overallSummary: json['overallSummary'] as String,
      insights: Map<String, String>.from(json['insights'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      personalityTraits: Map<String, double>.from(
        (json['personalityTraits'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      topPreferences: List<String>.from(json['topPreferences'] ?? []),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'dateRange': dateRange.toJson(),
        'overallSummary': overallSummary,
        'insights': insights,
        'recommendations': recommendations,
        'personalityTraits': personalityTraits,
        'topPreferences': topPreferences,
        'generatedAt': generatedAt.toIso8601String(),
      };
}
