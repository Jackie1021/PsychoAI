import 'package:flutter_app/models/match_record.dart';

/// Represents a match report for a specific date range.
class MatchReport {
  final String userId;
  final DateRange dateRange;
  final MatchStatistics statistics;
  final List<TraitAnalysis> traitAnalysis;
  final List<TopMatch> topMatches;
  final List<MatchTrend> trends;
  final String? aiInsight; // AI-generated insight

  MatchReport({
    required this.userId,
    required this.dateRange,
    required this.statistics,
    required this.traitAnalysis,
    required this.topMatches,
    required this.trends,
    this.aiInsight,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'dateRange': dateRange.toJson(),
        'statistics': statistics.toJson(),
        'traitAnalysis': traitAnalysis.map((t) => t.toJson()).toList(),
        'topMatches': topMatches.map((t) => t.toJson()).toList(),
        'trends': trends.map((t) => t.toJson()).toList(),
        'aiInsight': aiInsight,
      };

  factory MatchReport.fromJson(Map<String, dynamic> json) {
    return MatchReport(
      userId: json['userId'] as String,
      dateRange: DateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
      statistics:
          MatchStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
      traitAnalysis: (json['traitAnalysis'] as List)
          .map((t) => TraitAnalysis.fromJson(t as Map<String, dynamic>))
          .toList(),
      topMatches: (json['topMatches'] as List)
          .map((t) => TopMatch.fromJson(t as Map<String, dynamic>))
          .toList(),
      trends: (json['trends'] as List)
          .map((t) => MatchTrend.fromJson(t as Map<String, dynamic>))
          .toList(),
      aiInsight: json['aiInsight'] as String?,
    );
  }
}

/// Statistics for match data.
class MatchStatistics {
  final int totalMatches; // Total matches
  final int chattedCount; // Chatted count
  final int skippedCount; // Skipped count
  final double avgCompatibility; // Average compatibility
  final double maxCompatibility; // Max compatibility
  final int totalChatMessages; // Total chat messages
  final Map<String, int> actionDistribution; // Action distribution

  MatchStatistics({
    required this.totalMatches,
    required this.chattedCount,
    required this.skippedCount,
    required this.avgCompatibility,
    required this.maxCompatibility,
    required this.totalChatMessages,
    required this.actionDistribution,
  });

  Map<String, dynamic> toJson() => {
        'totalMatches': totalMatches,
        'chattedCount': chattedCount,
        'skippedCount': skippedCount,
        'avgCompatibility': avgCompatibility,
        'maxCompatibility': maxCompatibility,
        'totalChatMessages': totalChatMessages,
        'actionDistribution': actionDistribution,
      };

  factory MatchStatistics.fromJson(Map<String, dynamic> json) {
    return MatchStatistics(
      totalMatches: json['totalMatches'] as int,
      chattedCount: json['chattedCount'] as int,
      skippedCount: json['skippedCount'] as int,
      avgCompatibility: (json['avgCompatibility'] as num).toDouble(),
      maxCompatibility: (json['maxCompatibility'] as num).toDouble(),
      totalChatMessages: json['totalChatMessages'] as int,
      actionDistribution: Map<String, int>.from(json['actionDistribution']),
    );
  }
}

/// Analysis of a specific trait.
class TraitAnalysis {
  final String trait;
  final int matchCount; // Match count for this trait
  final double avgScore; // Average score
  final double successRate; // Success rate (chatted/total)

  TraitAnalysis({
    required this.trait,
    required this.matchCount,
    required this.avgScore,
    required this.successRate,
  });

  Map<String, dynamic> toJson() => {
        'trait': trait,
        'matchCount': matchCount,
        'avgScore': avgScore,
        'successRate': successRate,
      };

  factory TraitAnalysis.fromJson(Map<String, dynamic> json) {
    return TraitAnalysis(
      trait: json['trait'] as String,
      matchCount: json['matchCount'] as int,
      avgScore: (json['avgScore'] as num).toDouble(),
      successRate: (json['successRate'] as num).toDouble(),
    );
  }
}

/// Represents a top match with reason.
class TopMatch {
  final MatchRecord record;
  final String reason; // Why this is a top match

  TopMatch({required this.record, required this.reason});

  Map<String, dynamic> toJson() => {
        'record': record.toJson(),
        'reason': reason,
      };

  factory TopMatch.fromJson(Map<String, dynamic> json) {
    return TopMatch(
      record: MatchRecord.fromJson(json['record'] as Map<String, dynamic>),
      reason: json['reason'] as String,
    );
  }
}

/// Represents a match trend over time.
class MatchTrend {
  final DateTime date;
  final int matchCount;
  final double avgScore;

  MatchTrend({
    required this.date,
    required this.matchCount,
    required this.avgScore,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'matchCount': matchCount,
        'avgScore': avgScore,
      };

  factory MatchTrend.fromJson(Map<String, dynamic> json) {
    return MatchTrend(
      date: DateTime.parse(json['date'] as String),
      matchCount: json['matchCount'] as int,
      avgScore: (json['avgScore'] as num).toDouble(),
    );
  }
}

/// Represents a date range for filtering.
class DateRange {
  final DateTime start;
  final DateTime end;
  final String label; // "1个月", "3个月", "半年", "全部"

  DateRange({
    required this.start,
    required this.end,
    required this.label,
  });

  static DateRange lastMonth() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month - 1, now.day),
      end: now,
      label: '1个月',
    );
  }

  static DateRange last3Months() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month - 3, now.day),
      end: now,
      label: '3个月',
    );
  }

  static DateRange last6Months() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month - 6, now.day),
      end: now,
      label: '半年',
    );
  }

  static DateRange allTime() {
    return DateRange(
      start: DateTime(2020, 1, 1),
      end: DateTime.now(),
      label: '全部',
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'label': label,
      };

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      label: json['label'] as String,
    );
  }
}
