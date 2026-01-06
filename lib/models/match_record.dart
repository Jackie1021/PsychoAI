import 'package:flutter_app/models/match_analysis.dart';

/// Represents a single match record saved to the user's history.
class MatchRecord {
  final String id; // Unique ID
  final String userId; // Current user ID
  final String matchedUserId; // Matched user ID
  final String matchedUsername; // Matched username
  final String matchedUserAvatar; // Matched user avatar
  final double compatibilityScore; // Compatibility score (0.0-1.0)
  final String matchSummary; // AI-generated match summary
  final Map<String, ScoredFeature> featureScores; // Detailed feature analysis
  final DateTime createdAt; // Match timestamp
  final MatchAction action; // User action (chatted/skipped/none)
  final int chatMessageCount; // Chat message count (if chatted)
  final DateTime? lastInteractionAt; // Last interaction timestamp
  final Map<String, dynamic> metadata; // Extended metadata

  MatchRecord({
    required this.id,
    required this.userId,
    required this.matchedUserId,
    required this.matchedUsername,
    required this.matchedUserAvatar,
    required this.compatibilityScore,
    required this.matchSummary,
    required this.featureScores,
    required this.createdAt,
    this.action = MatchAction.none,
    this.chatMessageCount = 0,
    this.lastInteractionAt,
    this.metadata = const {},
  });

  factory MatchRecord.fromMatchAnalysis(
      MatchAnalysis analysis, String currentUserId) {
    // Generate unique ID for each match record to allow multiple matches with same user
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = '${analysis.id}_$timestamp';
    
    return MatchRecord(
      id: uniqueId,
      userId: currentUserId,
      matchedUserId: analysis.userB.uid,
      matchedUsername: analysis.userB.username,
      matchedUserAvatar: analysis.userB.avatarUrl ?? '',
      compatibilityScore: analysis.totalScore,
      matchSummary: analysis.matchSummary,
      featureScores: analysis.similarFeatures,
      createdAt: DateTime.now(),
      action: MatchAction.none,
      metadata: {
        'originalMatchId': analysis.id, // Keep original for reference
        'matchSessionTimestamp': timestamp,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'matchedUserId': matchedUserId,
        'matchedUsername': matchedUsername,
        'matchedUserAvatar': matchedUserAvatar,
        'compatibilityScore': compatibilityScore,
        'matchSummary': matchSummary,
        'featureScores': featureScores.map((k, v) => MapEntry(k, {
              'score': v.score,
              'explanation': v.explanation,
            })),
        'createdAt': createdAt.toIso8601String(),
        'action': action.name,
        'chatMessageCount': chatMessageCount,
        'lastInteractionAt': lastInteractionAt?.toIso8601String(),
        'metadata': metadata,
      };

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['featureScores'] as Map<String, dynamic>? ?? {};
    final featureScores = <String, ScoredFeature>{};
    featuresRaw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        featureScores[key] = ScoredFeature.fromJson(value);
      }
    });

    return MatchRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      matchedUserId: json['matchedUserId'] as String,
      matchedUsername: json['matchedUsername'] as String? ?? 'Unknown',
      matchedUserAvatar: json['matchedUserAvatar'] as String? ?? '',
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      matchSummary: json['matchSummary'] as String? ?? '',
      featureScores: featureScores,
      createdAt: DateTime.parse(json['createdAt'] as String),
      action: MatchAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => MatchAction.none,
      ),
      chatMessageCount: json['chatMessageCount'] as int? ?? 0,
      lastInteractionAt: json['lastInteractionAt'] != null
          ? DateTime.parse(json['lastInteractionAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  MatchRecord copyWith({
    MatchAction? action,
    int? chatMessageCount,
    DateTime? lastInteractionAt,
  }) {
    return MatchRecord(
      id: id,
      userId: userId,
      matchedUserId: matchedUserId,
      matchedUsername: matchedUsername,
      matchedUserAvatar: matchedUserAvatar,
      compatibilityScore: compatibilityScore,
      matchSummary: matchSummary,
      featureScores: featureScores,
      createdAt: createdAt,
      action: action ?? this.action,
      chatMessageCount: chatMessageCount ?? this.chatMessageCount,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      metadata: metadata,
    );
  }
}

enum MatchAction {
  none, // Not acted upon
  chatted, // Started chatting
  skipped, // Skipped
}
