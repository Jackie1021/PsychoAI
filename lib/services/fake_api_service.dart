import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/models/match_analysis.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/comment.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/models/match_report.dart';
import 'package:flutter_app/models/chat_history_summary.dart';
import 'package:flutter_app/models/yearly_ai_analysis.dart';
import 'api_service.dart';

/// ⚠️ DEPRECATED - This service has been deprecated.
/// All functionality now uses FirebaseApiService with Firebase Emulators.
///
/// A fake implementation of [ApiService] that loads a pre-generated set of mock data
/// for local development and testing.
///
/// This service simulates network latency and provides a rich user base from a JSON file,
/// allowing for rapid UI testing without a real backend.
/// When useLLM is enabled, it calls real LLM APIs for authentic match analysis.
///
/// @deprecated Use FirebaseApiService instead
class FakeApiService implements ApiService {
  final _latency = const Duration(milliseconds: 50);
  final Random _random = Random();
  final bool useLLM;
  final String? geminiApiKey;

  // --- Fake Data Store ---
  late UserData _currentUser;
  List<UserData> _mockUsers = [];
  final List<Post> _publicPosts = [];
  final Map<String, List<PostComment>> _commentsByPost = {};
  final Map<String, StreamController<List<PostComment>>> _commentControllers =
      {};

  // --- Match History Cache ---
  List<MatchAnalysis>? _lastMatchResults;

  /// Private constructor to be called by the async factory.
  FakeApiService._({
    required this.useLLM,
    this.geminiApiKey,
  });

  /// Async factory to create and initialize the service.
  static Future<FakeApiService> create({
    bool useLLM = false,
    String? geminiApiKey,
  }) async {
    final service = FakeApiService._(
      useLLM: useLLM,
      geminiApiKey: geminiApiKey,
    );
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    // The current user is static for now
    _currentUser = UserData(
      uid: 'current_user_id',
      username: 'You',
      portrait: null,
      traits: ['storyteller', 'night owl'],
      freeText: 'Loves rainy nights and old books.',
      userPosts: [],
    );

    print('🏗️ FakeApiService: Initialized current user');
    print('   Initial user data:');
    print('     - uid: ${_currentUser.uid}');
    print('     - username: ${_currentUser.username}');
    print('     - traits: ${_currentUser.traits}');
    print('     - freeText: "${_currentUser.freeText}"');
    print(
        '     - portrait: ${_currentUser.portrait != null ? "present" : "null"}');
    print('     - userPosts count: ${_currentUser.userPosts.length}');

    // Load the pre-generated mock users from the JSON file
    try {
      final String usersJsonString =
          await rootBundle.loadString('assets/data/fake_users.json');
      final List<dynamic> usersJson = json.decode(usersJsonString);
      _mockUsers = usersJson.map((json) => UserData.fromJson(json)).toList();
      // Debug: Uncomment to confirm users loaded
      // print('Loaded ${_mockUsers.length} mock users successfully');
    } catch (e) {
      print('Error loading fake_users.json: $e');
      print(
          'Did you forget to run `dart run scripts/generate_fake_data.dart`?');
      // If loading fails, continue with an empty list of users.
      _mockUsers = [];
    }

    // Create some initial public posts from the loaded users
    if (_mockUsers.isNotEmpty) {
      for (var i = 0; i < 5; i++) {
        final author = _mockUsers[_random.nextInt(_mockUsers.length)];
        _publicPosts.add(
          Post(
            userId: author.uid,
            author: author.username,
            authorImageUrl: 'https://i.pravatar.cc/150?u=${author.uid}',
            content: author.freeText,
            likes: _random.nextInt(100),
            comments: _random.nextInt(20),
            mainAxisCellCount: 1.2 + _random.nextDouble() * 0.4,
            crossAxisCellCount: 1.0,
          ),
        );
      }
    }
  }

  @override
  Future<UserData> getUser(String uid) async {
    await Future.delayed(_latency);
    if (uid == _currentUser.uid) {
      return _currentUser;
    }
    return _mockUsers.firstWhere((user) => user.uid == uid,
        orElse: () => _mockUsers.first);
  }

  @override
  Future<List<MatchAnalysis>> getCachedMatches(String uid) async {
    await Future.delayed(_latency);

    print('🗄️ FakeApiService.getCachedMatches called for uid: $uid');
    print('   Cached results available: ${_lastMatchResults != null}');

    if (_lastMatchResults != null) {
      print('   Returning ${_lastMatchResults!.length} cached match results');
      return _lastMatchResults!;
    } else {
      print('   No cached results available, returning empty list');
      return [];
    }
  }

  @override
  Future<void> updateUser(UserData user) async {
    await Future.delayed(_latency);
    print('FakeApiService: Updating user ${user.uid}');
  }

  @override
  Future<void> updateCurrentUserTraits(List<String> traits, String freeText) async {
    print('🔄 FakeApiService: Updating current user traits...');
    print('   Previous traits: ${_currentUser.traits}');
    print('   Previous freeText: "${_currentUser.freeText}"');
    print('   New traits: $traits');
    print('   New freeText: "$freeText"');

    _currentUser = _currentUser.copyWith(
      traits: traits,
      freeText: freeText,
    );

    print('✅ FakeApiService: Current user updated successfully');
    print('   Final traits: ${_currentUser.traits}');
    print('   Final freeText: "${_currentUser.freeText}"');
    print(
        '   Full user data: uid=${_currentUser.uid}, username=${_currentUser.username}');
  }

  @override
  Future<List<Post>> getPublicPosts() async {
    await Future.delayed(_latency);
    return _publicPosts;
  }

  @override
  Future<List<Post>> getMyPosts(String uid) async {
    await Future.delayed(_latency);
    return _currentUser.userPosts;
  }

  @override
  Future<void> createPost(Post post) async {
    await Future.delayed(_latency);
    _currentUser.userPosts.insert(0, post);
    if (post.isPublic) {
      _publicPosts.insert(0, post);
    }
    _commentsByPost.putIfAbsent(
        post.postId ?? 'local_${_publicPosts.length}', () => []);
  }

  @override
  Future<bool> likePost(String postId) async {
    await Future.delayed(_latency);
    return _random.nextBool();
  }

  @override
  Future<bool> toggleFavoritePost(String postId) async {
    await Future.delayed(_latency);
    return _random.nextBool();
  }

  @override
  Future<void> deletePost(String postId) async {
    await Future.delayed(_latency);
    _publicPosts.removeWhere((post) => post.postId == postId);
  }

  @override
  Stream<List<PostComment>> streamComments(String postId) {
    final controller = _commentControllers.putIfAbsent(postId, () {
      StreamController<List<PostComment>>? streamController;
      streamController =
          StreamController<List<PostComment>>.broadcast(onListen: () {
        final snapshot =
            List<PostComment>.from(_commentsByPost[postId] ?? const []);
        streamController!.add(snapshot);
      });
      return streamController!;
    });

    controller.add(List<PostComment>.from(_commentsByPost[postId] ?? const []));
    return controller.stream;
  }

  @override
  Future<PostComment> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    await Future.delayed(_latency);
    final commentId =
        'comment_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
    final comment = PostComment(
      id: commentId,
      postId: postId,
      userId: _currentUser.uid,
      authorName: _currentUser.username,
      authorAvatarUrl:
          'https://i.pravatar.cc/150?u=${Uri.encodeComponent(_currentUser.uid)}',
      text: text,
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
    );

    final comments = _commentsByPost.putIfAbsent(postId, () => []);
    comments.insert(0, comment);
    _emitCommentUpdate(postId);
    return comment;
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await Future.delayed(_latency);
    final comments = _commentsByPost[postId];
    if (comments == null) {
      return;
    }
    comments.removeWhere((c) => c.id == commentId);
    _emitCommentUpdate(postId);
  }

  @override
  Future<bool> likeComment({
    required String postId,
    required String commentId,
  }) async {
    await Future.delayed(_latency);
    // Mock implementation - just toggle like
    final comments = _commentsByPost[postId];
    if (comments != null) {
      final index = comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final comment = comments[index];
        final newLikeCount = comment.likeCount > 0 ? 0 : 1;
        comments[index] = comment.copyWith(likeCount: newLikeCount);
        _emitCommentUpdate(postId);
        return newLikeCount > 0;
      }
    }
    return false;
  }

  @override
  Stream<List<PostComment>> streamReplies({
    required String postId,
    required String commentId,
  }) {
    final controller = StreamController<List<PostComment>>();
    
    // Mock implementation - return empty replies for now
    controller.add([]);
    
    return controller.stream;
  }

  void _emitCommentUpdate(String postId) {
    final controller = _commentControllers[postId];
    if (controller != null && !controller.isClosed) {
      controller
          .add(List<PostComment>.from(_commentsByPost[postId] ?? const []));
    }
  }

  @override
  Future<void> blockUser(String blockedUid) async {
    await Future.delayed(_latency);
    print('Mock: Blocked user $blockedUid');
  }

  @override
  Future<void> unblockUser(String blockedUid) async {
    await Future.delayed(_latency);
    print('Mock: Unblocked user $blockedUid');
  }

  @override
  Future<void> followUser(String targetUid) async {
    await Future.delayed(_latency);
    print('Mock: Followed user $targetUid');
  }

  @override
  Future<void> unfollowUser(String targetUid) async {
    await Future.delayed(_latency);
    print('Mock: Unfollowed user $targetUid');
  }

  @override
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reasonCode,
    String? detailsText,
    List<String>? evidence,
  }) async {
    await Future.delayed(_latency);
    print('Mock: Reported $targetType $targetId for $reasonCode');
  }

  @override
  Future<List<MatchAnalysis>> getMatches(String uid) async {
    await Future.delayed(const Duration(milliseconds: 400));

    print('🧪 FakeApiService.getMatches called for uid: $uid');
    print('   LLM enabled: $useLLM, API key present: ${geminiApiKey != null}');
    print('   Current user data:');
    print('     - uid: ${_currentUser.uid}');
    print('     - username: ${_currentUser.username}');
    print('     - traits: ${_currentUser.traits}');
    print('     - freeText: "${_currentUser.freeText}"');
    print(
        '     - portrait: ${_currentUser.portrait != null ? "present" : "null"}');
    print('     - userPosts count: ${_currentUser.userPosts.length}');
    print('   Number of mock users: ${_mockUsers.length}');

    if (_mockUsers.isEmpty) {
      print('❌ No mock users available');
      return [];
    }

    List<MatchAnalysis> matches;
    if (useLLM && geminiApiKey != null) {
      // Use LLM-powered matching
      matches = await _getMatchesWithLLM();
    } else {
      // Use traditional algorithm
      matches = await _getMatchesTraditional();
    }

    // Cache the results for future use
    _lastMatchResults = matches;
    print('💾 Cached ${matches.length} match results for future use');

    return matches;
  }

  Future<List<MatchAnalysis>> _getMatchesTraditional() async {
    print('🎭 Using traditional matching algorithm');
    print('   Current user for matching:');
    print('     - traits: ${_currentUser.traits}');
    print('     - freeText: "${_currentUser.freeText}"');

    final List<MapEntry<UserData, double>> scoredUsers = [];

    for (final mockUser in _mockUsers) {
      if (mockUser.uid == _currentUser.uid) continue;

      final userTraits = _currentUser.traits.toSet();
      final mockUserTraits = mockUser.traits.toSet();

      final intersection = userTraits.intersection(mockUserTraits).length;
      final union = userTraits.union(mockUserTraits).length;

      if (union == 0) continue;

      // Base score from traits
      double score = intersection / union;

      // Bonus score from free text analysis
      final textBonus =
          _calculateTextBonus(_currentUser.freeText, mockUser.freeText);
      score += textBonus;

      // Apply a power function to increase score variance for more visual distinction
      score = pow(score, 1.5).toDouble();

      // Ensure score doesn't exceed 1.0
      score = score.clamp(0.0, 1.0);

      if (score > 0.1) {
        // Lowered threshold to get more diverse results
        scoredUsers.add(MapEntry(mockUser, score));
      }
    }

    scoredUsers.sort((a, b) => b.value.compareTo(a.value));

    final topMatches = scoredUsers.take(20);

    final matches = topMatches.map((entry) {
      final mockUser = entry.key;
      final score = entry.value;

      return MatchAnalysis(
        id: 'match_${mockUser.uid}',
        userA: _currentUser,
        userB: mockUser,
        totalScore: score,
        matchSummary:
            "The human equivalent of a rainy day and a good book.", // Fake witty summary
        similarFeatures: {
          'Creative Spark': ScoredFeature(
              score: (_random.nextDouble() * 40 + 60).toInt(),
              explanation:
                  'A shared passion for building worlds and telling stories.'),
          'Introspective Depth': ScoredFeature(
              score: (_random.nextDouble() * 40 + 50).toInt(),
              explanation:
                  'A connection over quiet moments and deep thoughts.'),
          'Shared Aesthetic': ScoredFeature(
              score: (_random.nextDouble() * 30 + 40).toInt(),
              explanation: 'An appreciation for similar atmospheres and art.'),
        },
      );
    }).toList();

    return matches;
  }

  Future<List<MatchAnalysis>> _getMatchesWithLLM() async {
    print('🤖 Using LLM-powered matching algorithm');
    print('   Current user for LLM matching:');
    print('     - traits: ${_currentUser.traits}');
    print('     - freeText: "${_currentUser.freeText}"');

    // Step 1: Pre-filter candidates using traditional algorithm
    final List<MapEntry<UserData, double>> preFilteredCandidates = [];

    for (final mockUser in _mockUsers) {
      if (mockUser.uid == _currentUser.uid) continue;

      final userTraits = _currentUser.traits.toSet();
      final mockUserTraits = mockUser.traits.toSet();

      final intersection = userTraits.intersection(mockUserTraits).length;
      final union = userTraits.union(mockUserTraits).length;

      if (union == 0) continue;

      // Base score from traits
      double formulaScore = intersection / union;

      // Bonus score from free text analysis
      final textBonus =
          _calculateTextBonus(_currentUser.freeText, mockUser.freeText);
      formulaScore += textBonus;

      // Ensure score doesn't exceed 1.0
      formulaScore = formulaScore.clamp(0.0, 1.0);

      // Lower threshold for LLM analysis to get more diverse candidates
      if (formulaScore > 0.05) {
        preFilteredCandidates.add(MapEntry(mockUser, formulaScore));
      }
    }

    // Sort by formula score and take top 10 for LLM analysis
    preFilteredCandidates.sort((a, b) => b.value.compareTo(a.value));
    final topCandidates = preFilteredCandidates.take(10);

    print(
        '📊 Pre-filtered ${topCandidates.length} candidates for LLM analysis');

    // Step 2: Call LLM for each candidate concurrently
    print(
        '🤖 Starting concurrent LLM analysis for ${topCandidates.length} candidates...');

    // Show waiting messages with jokes
    _showWaitingMessages(topCandidates.length);

    final List<Future<MatchAnalysis>> matchFutures =
        topCandidates.map((candidateEntry) {
      final candidate = candidateEntry.key;
      final formulaScore = candidateEntry.value;

      return _analyzeMatchWithLLM(candidate, formulaScore);
    }).toList();

    // Wait for all LLM calls to complete
    final matches = await Future.wait(matchFutures);

    print('✅ All LLM analyses completed (${matches.length} matches)');

    // Sort by final score (highest first)
    matches.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    print('🎯 Generated ${matches.length} matches with LLM analysis');
    return matches;
  }

  double _calculateTextBonus(String text1, String text2) {
    final keywords = [
      'night',
      'book',
      'rain',
      'dream',
      'story',
      'world',
      'sound',
      'listen'
    ];
    final words1 = text1.toLowerCase().split(' ');
    final words2 = text2.toLowerCase().split(' ');

    double bonus = 0;
    for (final keyword in keywords) {
      if (words1.contains(keyword) && words2.contains(keyword)) {
        bonus += 0.1;
      }
    }
    return bonus;
  }

  /// Shows waiting messages with random jokes while LLM analysis is running
  void _showWaitingMessages(int candidateCount) {
    final jokes = [
      "💭 正在分析你们的灵魂契合度...",
      "😄 为什么程序员喜欢黑暗模式？因为光会引起bug！",
      "🔮 正在咨询AI占卜师...",
      "😂 为什么AI不会迷路？因为它总是有地图（map）！",
      "💫 正在计算你们的宇宙连接...",
      "🤖 AI正在思考：这个问题值得用一个神经网络吗？",
      "🌟 寻找你们的星座匹配...",
      "📚 正在翻阅命运之书...",
      "🎭 正在排练你们的相遇剧本...",
      "🎪 欢迎来到匹配马戏团！",
    ];

    print('⏳ 请稍等，我们正在为 $candidateCount 位候选人进行AI深度分析...');

    // Show a random joke
    final randomJoke = jokes[_random.nextInt(jokes.length)];
    print('🎭 $randomJoke');

    print('💡 提示：这可能需要几秒到几十秒，取决于网络和AI响应速度');
  }

  /// Analyzes a single match with LLM
  Future<MatchAnalysis> _analyzeMatchWithLLM(
      UserData candidate, double formulaScore) async {
    print('🔄 Analyzing match with ${candidate.username}...');

    // Call LLM API
    final llmResponse = await _callLLMForMatch(_currentUser, candidate);

    if (llmResponse != null) {
      // Convert AI score from 0-100 to 0.0-1.0
      final aiScore = (llmResponse['totalScore'] as num).toDouble() / 100.0;

      // Calculate final score (weighted combination)
      final finalScore = (formulaScore * 0.3 + aiScore * 0.7).clamp(0.0, 1.0);

      // Parse the similar features map
      final featuresData =
          llmResponse['similarFeatures'] as Map<String, dynamic>? ?? {};
      final similarFeatures = featuresData.map(
        (key, value) => MapEntry(
            key, ScoredFeature.fromJson(value as Map<String, dynamic>)),
      );

      final match = MatchAnalysis(
        id: 'llm_match_${candidate.uid}',
        userA: _currentUser,
        userB: candidate,
        totalScore: finalScore,
        matchSummary:
            llmResponse['summary'] ?? 'A connection waiting to be written.',
        similarFeatures: similarFeatures,
      );

      print(
          '✅ LLM analysis completed for ${candidate.username}: AI=${aiScore.toStringAsFixed(2)}, Final=${finalScore.toStringAsFixed(2)}');
      return match;
    } else {
      print('⚠️ LLM analysis failed for ${candidate.username}, using fallback');
      // Fallback to traditional algorithm but with the new data structure
      final score = pow(formulaScore, 1.5).toDouble().clamp(0.0, 1.0);
      final match = MatchAnalysis(
        id: 'fallback_match_${candidate.uid}',
        userA: _currentUser,
        userB: candidate,
        totalScore: score,
        matchSummary:
            "The human equivalent of a rainy day and a good book.", // Fake witty summary
        similarFeatures: {
          'Creative Spark': ScoredFeature(
              score: (_random.nextDouble() * 40 + 60).toInt(),
              explanation:
                  'A shared passion for building worlds and telling stories.'),
          'Introspective Depth': ScoredFeature(
              score: (_random.nextDouble() * 40 + 50).toInt(),
              explanation:
                  'A connection over quiet moments and deep thoughts.'),
        },
      );
      return match;
    }
  }

  /// Calls the Gemini AI API to analyze a match between two users
  Future<Map<String, dynamic>?> _callLLMForMatch(
      UserData userA, UserData userB) async {
    if (!useLLM || geminiApiKey == null) {
      print('❌ LLM not enabled or API key missing');
      return null;
    }

    print(
        '🔄 Calling LLM API for match: ${userA.username} ↔ ${userB.username}');
    print('   API Key length: ${geminiApiKey!.length}');
    print('   User A traits: ${userA.traits}');
    print('   User B traits: ${userB.traits}');

    try {
      final prompt = '''
You are a witty and insightful matchmaker for a niche, artistic social app.
Your task is to analyze two user profiles and provide a sharp, creative analysis of their compatibility.

**Analyze the following two users:**

**User A:**
- Traits: ${userA.traits.join(", ")}
- Their own words: "${userA.freeText}"

**User B:**
- Traits: ${userB.traits.join(", ")}
- Their own words: "${userB.freeText}"

**Your Output (MUST be a single JSON object):**

1.  **`summary` (string):**
    - Write a **single, witty, and very short summary** of their dynamic (under 15 words).
    - This should feel like a clever joke, a modern slang phrase, or a playful metaphor that captures their connection.
    - **Good examples:** "A classic case of a storyteller meeting their protagonist." or "Basically the same person, but one of them actually writes things down." or "The human equivalent of a rainy day and a good book."

2.  **`totalScore` (number):**
    - Provide a holistic compatibility score from 0 to 100.

3.  **`similarFeatures` (object):**
    - Identify 3-4 key areas of similarity or complementarity.
    - For each area, provide a short title (as the key), and its value should be an object with:
        - **`score`**: A numeric score from 0-100 for that specific feature.
        - **`explanation`**: A brief, insightful explanation.

**Output Format:**
You MUST respond with only a single, valid JSON object. Do not include any text or markdown formatting before or after the JSON object.

```json
{
  "summary": "A witty one-liner about the match.",
  "totalScore": 88,
  "similarFeatures": {
    "Creative Spark": {
      "score": 90,
      "explanation": "Both users share a passion for building worlds and telling stories, suggesting a strong creative synergy."
    },
    "Introspective Depth": {
      "score": 80,
      "explanation": "A shared appreciation for quiet moments and deep thoughts means they'll likely connect on a meaningful level."
    },
    "Shared Aesthetic": {
      "score": 75,
      "explanation": "Their love for 'rainy nights' and 'old books' points to a similar taste in atmosphere and art."
    }
  }
}
```
''';

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey';
      print('🌐 API URL: $url');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      };

      print(
          '📤 Request body length: ${json.encode(requestBody).length} characters');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body length: ${response.body.length} characters');

      if (response.statusCode == 200) {
        print('✅ API call successful, parsing response...');

        try {
          final data = json.decode(response.body);
          print('📋 Parsed JSON keys: ${data.keys.toList()}');

          if (data.containsKey('candidates') && data['candidates'].isNotEmpty) {
            final candidate = data['candidates'][0];
            print('👤 Candidate keys: ${candidate.keys.toList()}');

            if (candidate.containsKey('content') &&
                candidate['content'].containsKey('parts')) {
              final parts = candidate['content']['parts'];
              if (parts.isNotEmpty) {
                final rawText = parts[0]['text'];
                print('📝 Raw LLM response: $rawText');

                // Clean the response
                final jsonText = rawText
                    .replaceAll('```json', '')
                    .replaceAll('```', '')
                    .trim();
                print('🧹 Cleaned JSON text: $jsonText');

                final parsed = json.decode(jsonText);
                print('🎯 Parsed response keys: ${parsed.keys.toList()}');

                if (parsed.containsKey('summary') &&
                    parsed.containsKey('totalScore') &&
                    parsed.containsKey('similarFeatures')) {
                  final features =
                      parsed['similarFeatures'] as Map<String, dynamic>;
                  if (features.isNotEmpty) {
                    print('✅ LLM response validation passed');
                    return parsed;
                  } else {
                    print('❌ LLM response field "similarFeatures" is empty');
                  }
                } else {
                  print(
                      '❌ LLM response missing required fields: summary, totalScore, similarFeatures');
                  print('   Available fields: ${parsed.keys.toList()}');
                }
              } else {
                print('❌ No parts in content');
              }
            } else {
              print('❌ Missing content or parts in candidate');
            }
          } else {
            print('❌ No candidates in response or candidates is empty');
          }
        } catch (parseError) {
          print('❌ Error parsing LLM response: $parseError');
          print('   Raw response body: ${response.body}');
        }
      } else {
        print('❌ API call failed with status ${response.statusCode}');

        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          print('❌ Error response: $errorData');

          if (errorData.containsKey('error')) {
            final error = errorData['error'];
            print('❌ Error code: ${error['code']}');
            print('❌ Error message: ${error['message']}');
            print('❌ Error status: ${error['status']}');
          }
        } catch (errorParseError) {
          print('❌ Could not parse error response body');
        }

        // Provide helpful hints based on status code
        if (response.statusCode == 401) {
          print('💡 Hint: Check if your API key is valid');
        } else if (response.statusCode == 429) {
          print('💡 Hint: Rate limit exceeded - wait and try again');
        } else if (response.statusCode == 500) {
          print('💡 Status 500: Server error - try again later');
        }
      }

      print('🚫 LLM API call failed, returning null');
      return null;
    } catch (e, stackTrace) {
      print('💥 Exception calling LLM API: $e');
      print('   Stack trace: $stackTrace');

      if (e.toString().contains('SocketException')) {
        print('💡 Network error - check internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        print('💡 Request timeout - API may be slow or unreachable');
      }

      return null;
    }
  }
}


  // --- Match Report Methods ---

  @override
  Future<void> saveMatchRecord(MatchRecord record) async {
    await Future.delayed(_latency);
    print('✅ FakeAPI: Match record saved: ${record.id}');
  }

  @override
  Future<List<MatchRecord>> getMatchHistory({
    required String userId,
    DateRange? dateRange,
    MatchAction? filterAction,
    int? limit,
    String? startAfter,
  }) async {
    await Future.delayed(_latency);
    return [];
  }

  @override
  Future<void> updateMatchAction({
    required String userId,
    required String matchRecordId,
    required MatchAction action,
    int? chatMessageCount,
  }) async {
    await Future.delayed(_latency);
    print('✅ FakeAPI: Match action updated');
  }

  @override
  Future<Map<String, dynamic>> getMatchFrequencyWithUser({
    required String userId,
    required String matchedUserId,
    DateRange? dateRange,
  }) async {
    await Future.delayed(_latency);
    return {
      'totalMatches': 0,
      'chattedCount': 0,
      'avgCompatibilityScore': 0.0,
      'records': <MatchRecord>[],
      'firstMatchDate': null,
      'lastMatchDate': null,
    };
  }

  @override
  Future<MatchReport> generateMatchReport({
    required String userId,
    required DateRange dateRange,
  }) async {
    await Future.delayed(_latency);
    return MatchReport(
      userId: userId,
      dateRange: dateRange,
      statistics: MatchStatistics(
        totalMatches: 0,
        chattedCount: 0,
        skippedCount: 0,
        avgCompatibility: 0.0,
        maxCompatibility: 0.0,
        totalChatMessages: 0,
        actionDistribution: {'none': 0, 'chatted': 0, 'skipped': 0},
      ),
      traitAnalysis: [],
      topMatches: [],
      trends: [],
    );
  }

  @override
  Future<MatchReport?> getCachedReport({
    required String userId,
    required DateRange dateRange,
  }) async {
    await Future.delayed(_latency);
    return null;
  }

  @override
  Future<String> requestAIAnalysis({
    required String userId,
    required DateRange dateRange,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return '这是模拟AI分析。实际应用中会显示详细的匹配洞察。';
  }

  @override
  Future<Uint8List> exportReportToPDF({
    required MatchReport report,
  }) async {
    await Future.delayed(_latency);
    throw UnimplementedError('PDF export not implemented in FakeAPI');
  }

  @override
  Future<YearlyAIAnalysis> requestYearlyAIAnalysis({
    required String userId,
    required DateRange dateRange,
  }) async {
    await Future.delayed(_latency);
    return YearlyAIAnalysis(
      userId: userId,
      dateRange: dateRange,
      overallSummary: '在${dateRange.label}期间，你展现出独特的社交特征，注重真实连接和深度交流。',
      insights: {
        'matchPattern': '你倾向于与兴趣相投的人建立联系',
        'communicationStyle': '你的沟通风格真诚而开放',
        'preferences': '你重视共同价值观和深度对话',
      },
      recommendations: [
        '继续保持开放的心态',
        '给每个匹配更多了解的机会',
        '在对话中展现你的独特个性',
      ],
      personalityTraits: {
        'openness': 0.75,
        'authenticity': 0.85,
        'engagement': 0.70,
      },
      topPreferences: ['深度交流', '共同兴趣', '真实连接'],
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<YearlyAIAnalysis?> getCachedYearlyAIAnalysis({
    required String userId,
    required DateRange dateRange,
  }) async {
    await Future.delayed(_latency);
    // Fake service does not persist analyses; return null
    return null;
  }

  @override
  Future<List<ChatHistorySummary>> getChatHistorySummaries({
    required String userId,
    DateRange? dateRange,
  }) async {
    await Future.delayed(_latency);
    return [];
  }

  @override
  Future<int> getChatMessageCount(String conversationId) async {
    await Future.delayed(_latency);
    return 0;
  }

  @override
  Future<void> upgradeMembership({
    required MembershipTier tier,
    required int durationDays,
    String? subscriptionId,
  }) async {
    await Future.delayed(_latency);
    print('🎭 [FAKE API] Upgraded membership to ${tier.name}');
  }

  @override
  Future<void> cancelMembership() async {
    await Future.delayed(_latency);
    print('🎭 [FAKE API] Cancelled membership');
  }
}
