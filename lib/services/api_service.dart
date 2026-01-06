import 'dart:typed_data';

import 'package:flutter_app/models/match_analysis.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/comment.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/models/match_report.dart';
import 'package:flutter_app/models/chat_history_summary.dart';
import 'package:flutter_app/models/yearly_ai_analysis.dart';

/// Defines the contract for all data operations in the app.
/// This abstract class can be implemented by a fake local service for debugging
/// or a real backend service (e.g., Firebase) for production.
abstract class ApiService {
  /// Retrieves a user's complete profile data.
  Future<UserData> getUser(String uid);

  /// Updates a user's profile data.
  Future<void> updateUser(UserData user);

  /// Fetches the public feed of posts from the community.
  Future<List<Post>> getPublicPosts();

  /// Fetches all posts created by a specific user.
  Future<List<Post>> getMyPosts(String uid);

  /// Generates or retrieves a list of potential matches for the user,
  /// complete with detailed AI analysis for each.
  Future<List<MatchAnalysis>> getMatches(String uid);

  /// Gets cached match results if available, otherwise returns empty list.
  /// Used for quickly viewing previous match results without recomputing.
  Future<List<MatchAnalysis>> getCachedMatches(String uid);

  /// Updates the current user's traits and free text for matching purposes.
  /// Returns a Future to ensure the update completes before matching starts.
  Future<void> updateCurrentUserTraits(List<String> traits, String freeText);

  /// Updates an existing post.
  Future<void> updatePost(String postId, {String? text, bool? isPublic});

  /// Gets posts liked by a user.
  Future<List<Post>> getLikedPosts(String userId);

  /// Gets posts favorited by a user.
  Future<List<Post>> getFavoritedPosts(String userId);

  /// Creates a new post.
  Future<void> createPost(Post post);

  /// Likes or unlikes a post.
  Future<bool> likePost(String postId);

  /// Favorites or unfavorites a post.
  Future<bool> toggleFavoritePost(String postId);

  /// Deletes a post.
  Future<void> deletePost(String postId);

  /// Streams live comments for a given post ordered by newest first.
  Stream<List<PostComment>> streamComments(String postId);

  /// Adds a new comment to the post and returns the created comment.
  Future<PostComment> addComment({
    required String postId,
    required String text,
    String? parentCommentId, // For replies
  });

  /// Deletes the current user's comment from a post.
  Future<void> deleteComment(
      {required String postId, required String commentId});

  /// Likes or unlikes a comment.
  Future<bool> likeComment({
    required String postId,
    required String commentId,
  });

  /// Gets replies for a comment.
  Stream<List<PostComment>> streamReplies({
    required String postId,
    required String commentId,
  });

  /// Blocks a user.
  Future<void> blockUser(String blockedUid);

  /// Unblocks a user.
  Future<void> unblockUser(String blockedUid);

  /// Follows another user.
  Future<void> followUser(String targetUid);

  /// Unfollows a previously followed user.
  Future<void> unfollowUser(String targetUid);

  /// Reports a post or user.
  Future<void> report({
    required String targetType, // "post" or "user"
    required String targetId,
    required String reasonCode, // "spam", "abuse", "nudity", "other"
    String? detailsText,
    List<String>? evidence,
  });

  /// Saves a match record to the user's history.
  Future<void> saveMatchRecord(MatchRecord record);

  /// Gets match history with optional filtering.
  Future<List<MatchRecord>> getMatchHistory({
    required String userId,
    DateRange? dateRange,
    MatchAction? filterAction,
    int? limit,
    String? startAfter,
  });
  
  /// Gets match frequency statistics with a specific user.
  Future<Map<String, dynamic>> getMatchFrequencyWithUser({
    required String userId,
    required String matchedUserId,
    DateRange? dateRange,
  });

  /// Updates a match record's action status.
  Future<void> updateMatchAction({
    required String userId,
    required String matchRecordId,
    required MatchAction action,
    int? chatMessageCount,
  });

  /// Generates a match report for a date range.
  Future<MatchReport> generateMatchReport({
    required String userId,
    required DateRange dateRange,
  });

  /// Gets a cached report if available.
  Future<MatchReport?> getCachedReport({
    required String userId,
    required DateRange dateRange,
  });

  /// Requests AI analysis of match patterns.
  Future<String> requestAIAnalysis({
    required String userId,
    required DateRange dateRange,
  });

  /// Requests detailed AI analysis of yearly match patterns.
  Future<YearlyAIAnalysis> requestYearlyAIAnalysis({
    required String userId,
    required DateRange dateRange,
  });

  /// Retrieves the last cached YearlyAIAnalysis for the user/dateRange if available.
  Future<YearlyAIAnalysis?> getCachedYearlyAIAnalysis({
    required String userId,
    required DateRange dateRange,
  });

  /// Gets chat history summaries for matched users.
  Future<List<ChatHistorySummary>> getChatHistorySummaries({
    required String userId,
    DateRange? dateRange,
  });

  /// Gets chat message count for a specific conversation.
  Future<int> getChatMessageCount(String conversationId);

  /// Exports a report to PDF.
  Future<Uint8List> exportReportToPDF({
    required MatchReport report,
  });

  /// Upgrades user membership.
  Future<void> upgradeMembership({
    required MembershipTier tier,
    required int durationDays,
    String? subscriptionId,
  });

  /// Cancels user membership.
  Future<void> cancelMembership();

  // Future<void> saveConversation(Conversation conversation);
  // Future<List<Conversation>> getConversations(String uid);
}
