import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_app/models/match_analysis.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/comment.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/models/match_report.dart';
import 'package:flutter_app/models/chat_history_summary.dart';
import 'package:flutter_app/models/yearly_ai_analysis.dart';
import 'package:flutter_app/models/conversation.dart';
import 'api_service.dart';

/// Production implementation of [ApiService] that communicates with Firebase backend.
/// This service calls Firebase Cloud Functions for AI-powered operations.
class FirebaseApiService implements ApiService {
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseApiService({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<UserData> getUser(String uid) async {
    try {
      var doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists && _auth.currentUser?.uid == uid) {
        doc = await _ensureUserDocument(uid);
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('User not found');
      }

      return _mapUserData(uid, data);
    } catch (e) {
      print('❌ Error getting user: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUser(UserData user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'username': user.username,
        'name': user.username, // Also store as 'name' for chat compatibility
        'avatarUrl': user.avatarUrl,
        'avatar': user.avatarUrl, // Also store as 'avatar' for chat compatibility
        'bio': user.freeText,
        'freeText': user.freeText,
        'traits': user.traits,
        'membershipTier': user.membershipTier.name,
        'membershipExpiry': user.membershipExpiry != null 
            ? Timestamp.fromDate(user.membershipExpiry!) 
            : null,
        'subscriptionId': user.subscriptionId,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCurrentUserTraits(List<String> traits, String freeText) async {
    // Update user's traits in Firestore immediately
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ No authenticated user to update traits');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'traits': traits,
        'freeText': freeText,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Updated user traits: ${traits.length} traits, freeText length: ${freeText.length}');
      print('   Traits: $traits');
      print('   FreeText: "$freeText"');
    } catch (error) {
      print('❌ Error updating traits: $error');
      rethrow;
    }
  }

  @override
  Future<List<Post>> getPublicPosts() async {
    try {
      final currentUid = _auth.currentUser?.uid;
      Set<String> likedPostIds = {};
      Set<String> favoritedPostIds = {};

      if (currentUid != null) {
        final userRef = _firestore.collection('users').doc(currentUid);
        final snapshots = await Future.wait([
          userRef.collection('likes').get(),
          userRef.collection('favorites').get(),
        ]);

        likedPostIds = snapshots[0].docs.map((doc) => doc.id).toSet();
        favoritedPostIds = snapshots[1].docs.map((doc) => doc.id).toSet();
      }

      final snapshot = await _firestore
          .collection('posts')
          .where('status', isEqualTo: 'visible')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final authorCache = <String, UserData>{};

      final posts = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final userId = data['userId'] as String;

        UserData? author = authorCache[userId];
        if (author == null) {
          try {
            author = await getUser(userId);
            authorCache[userId] = author;
          } catch (e) {
            print('⚠️ Could not fetch author for post ${doc.id}: $e');
            author = UserData(
              uid: userId,
              username: 'Unknown',
              avatarUrl: '',
              userPosts: const [],
              traits: const [],
              freeText: '',
            );
            authorCache[userId] = author;
          }
        }

        final mediaList = (data['media'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();

        final mediaType = _parseMediaType(data['mediaType']);

        return Post(
          postId: doc.id,
          userId: userId,
          author: author?.username ?? 'Unknown',
          authorImageUrl: _resolveAvatarUrl(author, userId),
          content: data['text'] ?? '',
          media: mediaList,
          mediaType: mediaType,
          likes: (data['likeCount'] ?? 0) is int
              ? data['likeCount'] as int
              : (data['likeCount'] as num?)?.toInt() ?? 0,
          comments: (data['commentCount'] ?? 0) is int
              ? data['commentCount'] as int
              : (data['commentCount'] as num?)?.toInt() ?? 0,
          favorites: (data['favoriteCount'] ?? 0) is int
              ? data['favoriteCount'] as int
              : (data['favoriteCount'] as num?)?.toInt() ?? 0,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          status: data['status'],
          mainAxisCellCount: mediaList.isNotEmpty ? 1.5 : 1.2,
          isPublic: data['isPublic'] as bool? ?? data['status'] == 'visible',
          isFavorited: favoritedPostIds.contains(doc.id),
          isLiked: likedPostIds.contains(doc.id),
        );
      }));

      return posts;
    } catch (e) {
      print('❌ Error getting public posts: $e');
      return [];
    }
  }

  @override
  Future<List<Post>> getMyPosts(String uid) async {
    try {
      Set<String> likedPostIds = {};
      Set<String> favoritedPostIds = {};

      final currentUid = _auth.currentUser?.uid;
      if (currentUid != null) {
        final userRef = _firestore.collection('users').doc(currentUid);
        final snapshots = await Future.wait([
          userRef.collection('likes').get(),
          userRef.collection('favorites').get(),
        ]);

        likedPostIds = snapshots[0].docs.map((doc) => doc.id).toSet();
        favoritedPostIds = snapshots[1].docs.map((doc) => doc.id).toSet();
      }

      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'visible')
          .orderBy('createdAt', descending: true)
          .get();

      final author = await getUser(uid);

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final mediaList = (data['media'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
        return Post(
          postId: doc.id,
          userId: uid,
          author: author.username,
          authorImageUrl: _resolveAvatarUrl(author, uid),
          content: data['text'] ?? '',
          media: mediaList,
          mediaType: _parseMediaType(data['mediaType']),
          likes: (data['likeCount'] ?? 0) is int
              ? data['likeCount'] as int
              : (data['likeCount'] as num?)?.toInt() ?? 0,
          comments: (data['commentCount'] ?? 0) is int
              ? data['commentCount'] as int
              : (data['commentCount'] as num?)?.toInt() ?? 0,
          favorites: (data['favoriteCount'] ?? 0) is int
              ? data['favoriteCount'] as int
              : (data['favoriteCount'] as num?)?.toInt() ?? 0,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          status: data['status'],
          mainAxisCellCount: mediaList.isNotEmpty ? 1.5 : 1.2,
          isPublic: data['isPublic'] as bool? ?? data['status'] == 'visible',
          isFavorited: favoritedPostIds.contains(doc.id),
          isLiked: likedPostIds.contains(doc.id),
        );
      }).toList();
    } catch (e) {
      print('❌ Error getting my posts: $e');
      return [];
    }
  }

  @override
  Future<void> createPost(Post post) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      // Upload media to Firebase Storage if there are local files
      List<String> uploadedMediaUrls = [];
      for (String mediaPath in post.media) {
        if (mediaPath.startsWith('http')) {
          // Already a URL, just add it
          uploadedMediaUrls.add(mediaPath);
        } else {
          // Local file, upload it
          final file = File(mediaPath);
          final ext = mediaPath.split('.').last;
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}.$ext';
          final ref = _storage.ref().child('posts/$fileName');

          await ref.putFile(file);
          final downloadUrl = await ref.getDownloadURL();
          uploadedMediaUrls.add(downloadUrl);
        }
      }

      final callable = _functions.httpsCallable('createPost');
      final mediaTypeName = (post.mediaType ??
              (uploadedMediaUrls.isEmpty ? MediaType.text : MediaType.image))
          .toString()
          .split('.')
          .last;
      final result = await callable.call({
        'text': post.content,
        'media': uploadedMediaUrls,
        'isPublic': post.isPublic,
        'mediaType': mediaTypeName,
      });

      print('✅ Post created successfully: ${result.data}');
    } catch (e) {
      print('❌ Error creating post: $e');
      rethrow;
    }
  }

  @override
  Future<bool> likePost(String postId) async {
    try {
      final callable = _functions.httpsCallable('likePost');
      final result = await callable.call({'postId': postId});
      return result.data['liked'] as bool;
    } catch (e) {
      print('❌ Error liking post: $e');
      rethrow;
    }
  }

  @override
  Future<bool> toggleFavoritePost(String postId) async {
    try {
      final callable = _functions.httpsCallable('toggleFavoritePost');
      final result = await callable.call({'postId': postId});
      return result.data['favorited'] as bool;
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePost(String postId, {String? text, bool? isPublic}) async {
    try {
      final callable = _functions.httpsCallable('updatePost');
      await callable.call({
        'postId': postId,
        if (text != null) 'text': text,
        if (isPublic != null) 'isPublic': isPublic,
      });
      print('✅ Post updated successfully');
    } catch (e) {
      print('❌ Error updating post: $e');
      rethrow;
    }
  }

  @override
  Future<List<Post>> getLikedPosts(String userId) async {
    try {
      final callable = _functions.httpsCallable('getLikedPosts');
      final result = await callable.call({'userId': userId});
      
      final postsData = result.data['posts'] as List<dynamic>;
      final currentUid = _auth.currentUser?.uid;
      
      Set<String> likedPostIds = {};
      Set<String> favoritedPostIds = {};
      
      if (currentUid != null) {
        final userRef = _firestore.collection('users').doc(currentUid);
        final snapshots = await Future.wait([
          userRef.collection('likes').get(),
          userRef.collection('favorites').get(),
        ]);
        likedPostIds = snapshots[0].docs.map((doc) => doc.id).toSet();
        favoritedPostIds = snapshots[1].docs.map((doc) => doc.id).toSet();
      }
      
      final authorCache = <String, UserData>{};
      
      return await Future.wait(postsData.map((data) async {
        final userId = data['userId'] as String;
        UserData? author = authorCache[userId];
        
        if (author == null) {
          try {
            author = await getUser(userId);
            authorCache[userId] = author;
          } catch (e) {
            author = UserData(
              uid: userId,
              username: 'Unknown',
              avatarUrl: '',
              userPosts: const [],
              traits: const [],
              freeText: '',
            );
            authorCache[userId] = author;
          }
        }
        
        final mediaList = (data['media'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
        final postId = data['postId'] as String;
        
        return Post(
          postId: postId,
          userId: userId,
          author: author.username,
          authorImageUrl: _resolveAvatarUrl(author, userId),
          content: data['text'] ?? '',
          media: mediaList,
          mediaType: _parseMediaType(data['mediaType']),
          likes: _toInt(data['likeCount']),
          comments: _toInt(data['commentCount']),
          favorites: _toInt(data['favoriteCount']),
          createdAt: _parseTimestamp(data['createdAt']),
          status: data['status'],
          mainAxisCellCount: mediaList.isNotEmpty ? 1.5 : 1.2,
          isPublic: data['isPublic'] as bool? ?? data['status'] == 'visible',
          isFavorited: favoritedPostIds.contains(postId),
          isLiked: likedPostIds.contains(postId),
        );
      }).toList());
    } catch (e) {
      print('❌ Error getting liked posts: $e');
      return [];
    }
  }

  @override
  Future<List<Post>> getFavoritedPosts(String userId) async {
    try {
      final callable = _functions.httpsCallable('getFavoritedPosts');
      final result = await callable.call({'userId': userId});
      
      final postsData = result.data['posts'] as List<dynamic>;
      final currentUid = _auth.currentUser?.uid;
      
      Set<String> likedPostIds = {};
      Set<String> favoritedPostIds = {};
      
      if (currentUid != null) {
        final userRef = _firestore.collection('users').doc(currentUid);
        final snapshots = await Future.wait([
          userRef.collection('likes').get(),
          userRef.collection('favorites').get(),
        ]);
        likedPostIds = snapshots[0].docs.map((doc) => doc.id).toSet();
        favoritedPostIds = snapshots[1].docs.map((doc) => doc.id).toSet();
      }
      
      final authorCache = <String, UserData>{};
      
      return await Future.wait(postsData.map((data) async {
        final userId = data['userId'] as String;
        UserData? author = authorCache[userId];
        
        if (author == null) {
          try {
            author = await getUser(userId);
            authorCache[userId] = author;
          } catch (e) {
            author = UserData(
              uid: userId,
              username: 'Unknown',
              avatarUrl: '',
              userPosts: const [],
              traits: const [],
              freeText: '',
            );
            authorCache[userId] = author;
          }
        }
        
        final mediaList = (data['media'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
        final postId = data['postId'] as String;
        
        return Post(
          postId: postId,
          userId: userId,
          author: author.username,
          authorImageUrl: _resolveAvatarUrl(author, userId),
          content: data['text'] ?? '',
          media: mediaList,
          mediaType: _parseMediaType(data['mediaType']),
          likes: _toInt(data['likeCount']),
          comments: _toInt(data['commentCount']),
          favorites: _toInt(data['favoriteCount']),
          createdAt: _parseTimestamp(data['createdAt']),
          status: data['status'],
          mainAxisCellCount: mediaList.isNotEmpty ? 1.5 : 1.2,
          isPublic: data['isPublic'] as bool? ?? data['status'] == 'visible',
          isFavorited: favoritedPostIds.contains(postId),
          isLiked: likedPostIds.contains(postId),
        );
      }).toList());
    } catch (e) {
      print('❌ Error getting favorited posts: $e');
      return [];
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      final callable = _functions.httpsCallable('deletePost');
      await callable.call({'postId': postId});
      print('✅ Post deleted successfully');
    } catch (e) {
      print('❌ Error deleting post: $e');
      rethrow;
    }
  }

  @override
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reasonCode,
    String? detailsText,
    List<String>? evidence,
  }) async {
    print('🚨 [REPORT] Starting report submission...');
    print('   Target Type: $targetType');
    print('   Target ID: $targetId');
    print('   Reason Code: $reasonCode');
    print('   Details Text: ${detailsText?.length ?? 0} characters');
    print('   Evidence: ${evidence?.length ?? 0} items');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ [REPORT] No authenticated user');
        throw Exception('User not authenticated');
      }
      print('✅ [REPORT] User authenticated: ${user.uid}');

      final callable = _functions.httpsCallable('createReport');
      print('📞 [REPORT] Calling createReport Cloud Function...');

      final callData = {
        'targetType': targetType,
        'targetId': targetId,
        'reasonCode': reasonCode,
        if (detailsText != null && detailsText.trim().isNotEmpty) 'detailsText': detailsText.trim(),
        if (evidence != null && evidence.isNotEmpty) 'evidence': evidence,
      };
      print('📤 [REPORT] Request data: $callData');

      final result = await callable.call(callData);
      print('📥 [REPORT] Response: ${result.data}');
      print('✅ [REPORT] Report submitted successfully');
    } catch (e, stackTrace) {
      print('❌ [REPORT] Error submitting report: $e');
      print('   Stack trace: $stackTrace');

      // Check for specific Firebase Functions errors
      if (e.toString().contains('not-found')) {
        print('💡 [REPORT] Cloud Function not found - check deployment');
      } else if (e.toString().contains('permission-denied')) {
        print('💡 [REPORT] Permission denied - check Firestore rules');
      } else if (e.toString().contains('internal')) {
        print('💡 [REPORT] Internal error - check Cloud Function logs');
      }

      rethrow;
    }
  }

  // --- Helpers ---
  
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  MediaType _parseMediaType(dynamic raw) {
    if (raw == null) {
      return MediaType.text;
    }

    final value = raw.toString();
    for (final mediaType in MediaType.values) {
      if (mediaType.toString().split('.').last == value) {
        return mediaType;
      }
    }
    return MediaType.text;
  }

  String _resolveAvatarUrl(UserData? user, String fallbackSeed) {
    final avatar = user?.avatarUrl;
    if (avatar != null && avatar.isNotEmpty) {
      return avatar;
    }

    final seed = (user?.username ?? fallbackSeed).trim();
    final finalSeed = seed.isEmpty ? fallbackSeed : seed;
    final encoded = Uri.encodeComponent(finalSeed);
    return 'https://ui-avatars.com/api/?name=$encoded';
  }

  @override
  Future<List<MatchAnalysis>> getMatches(String uid) async {
    try {
      // Ensure user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _ensureUserDocument(uid);

      print('🔥 Calling Firebase Cloud Function getMatches for user: $uid');

      // Call the Cloud Function to generate matches with LLM analysis
      final callable = _functions.httpsCallable('getMatches');
      try {
        await callable.call();
      } on FirebaseFunctionsException catch (error) {
        if (error.code == 'not-found') {
          print(
              'ℹ️ getMatches reported missing user. Attempting to recreate profile and retry.');
          await _ensureUserDocument(uid);
          await callable.call();
        } else {
          rethrow;
        }
      }

      print('✅ getMatches Cloud Function completed');

      // Fetch the generated matches from Firestore
      final matchesRef =
          _firestore.collection('matches').doc(uid).collection('candidates');
      final snapshot = await matchesRef.get();

      final matches = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing match data: ${doc.id}');
        try {
          final match = MatchAnalysis.fromJson(data);
          print(
              'Successfully parsed match: ${match.id}, totalScore: ${match.totalScore}');
          return match;
        } catch (e) {
          print('Error parsing match data for ${doc.id}: $e');
          print('Raw data: $data');
          rethrow;
        }
      }).toList();

      // Sort matches by final score (highest first)
      matches.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      print(
          '🎯 Retrieved ${matches.length} matches from Firestore with LLM analysis');
      return matches;
    } catch (e) {
      print('❌ Error in getMatches: $e');
      // In production, you might want to fallback to a simpler matching algorithm
      // For now, rethrow the error
      rethrow;
    }
  }

  @override
  Future<List<MatchAnalysis>> getCachedMatches(String uid) async {
    // For Firebase service, caching is handled by the backend
    // For now, just return empty list as this feature is mainly for development
    print('FirebaseApiService: getCachedMatches not implemented yet');
    return [];
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _ensureUserDocument(
      String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      return snapshot;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != uid) {
      throw Exception('Cannot create profile for another user');
    }

    final username = currentUser.displayName ??
        (currentUser.email != null
            ? currentUser.email!.split('@').first
            : 'User');

    final profile = {
      'uid': uid,
      'username': username,
      'avatarUrl': currentUser.photoURL ?? '',
      'bio': '',
      'traits': [],
      'freeText': '',
      'lastActive': FieldValue.serverTimestamp(),
      'isSuspended': false,
      'reportCount': 0,
      'followersCount': 0,
      'followingCount': 0,
      'postsCount': 0,
      'followedBloggerIds': [],
      'favoritedPostIds': [],
      'favoritedConversationIds': [],
      'likedPostIds': [],
      'privacy': {
        'visibility': 'public',
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    await userRef.set(profile, SetOptions(merge: true));
    return await userRef.get();
  }

  UserData _mapUserData(String uid, Map<String, dynamic> data) {
    // Parse membership tier
    MembershipTier membershipTier = MembershipTier.free;
    if (data.containsKey('membershipTier')) {
      final tierString = data['membershipTier'] as String?;
      if (tierString != null) {
        membershipTier = MembershipTier.values.firstWhere(
          (e) => e.name == tierString,
          orElse: () => MembershipTier.free,
        );
      }
    }
    
    // Parse membership expiry
    DateTime? membershipExpiry;
    if (data.containsKey('membershipExpiry') && data['membershipExpiry'] != null) {
      final expiryValue = data['membershipExpiry'];
      if (expiryValue is Timestamp) {
        membershipExpiry = expiryValue.toDate();
      } else if (expiryValue is String) {
        membershipExpiry = DateTime.tryParse(expiryValue);
      } else if (expiryValue is int) {
        membershipExpiry = DateTime.fromMillisecondsSinceEpoch(expiryValue);
      }
    }
    
    return UserData(
      uid: data['uid'] as String? ?? uid,
      username: data['username'] as String? ?? 'Unknown',
      avatarUrl: data['avatarUrl'] as String?,
      traits: List<String>.from(data['traits'] ?? const []),
      freeText: data['freeText'] as String? ?? data['bio'] as String? ?? '',
      followedBloggerIds:
          List<String>.from(data['followedBloggerIds'] ?? const []),
      favoritedPostIds: List<String>.from(data['favoritedPostIds'] ?? const []),
      favoritedConversationIds:
          List<String>.from(data['favoritedConversationIds'] ?? const []),
      likedPostIds: List<String>.from(data['likedPostIds'] ?? const []),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      isSuspended: data['isSuspended'] as bool? ?? false,
      reportCount: data['reportCount'] as int? ?? 0,
      followersCount: data['followersCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      postsCount: data['postsCount'] as int? ?? 0,
      membershipTier: membershipTier,
      membershipExpiry: membershipExpiry,
      subscriptionId: data['subscriptionId'] as String?,
      userPosts: const [],
    );
  }

  @override
  Stream<List<PostComment>> streamComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('status', isEqualTo: 'visible')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                PostComment.fromJson(doc.data(), id: doc.id, postId: postId))
            .toList());
  }

  @override
  Future<PostComment> addComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    print('💬 [COMMENT] Starting comment submission...');
    print('   Post ID: $postId');
    print('   Text length: ${text.length}');
    print('   Parent Comment ID: $parentCommentId');
    print('   Firebase Auth instance: ${_auth.app.name}');
    print('   Firestore instance: ${_firestore.app.name}');

    // Validate inputs
    if (postId.isEmpty) {
      print('❌ [COMMENT] Post ID is empty');
      throw Exception('Post ID cannot be empty');
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      print('❌ [COMMENT] Comment text is empty after trimming');
      throw Exception('Comment text cannot be empty');
    }

    if (trimmed.length > 2000) {
      print('❌ [COMMENT] Comment text too long: ${trimmed.length} characters (max 2000)');
      throw Exception('Comment text too long (max 2000 characters)');
    }

    print('✅ [COMMENT] Comment text validated: "${trimmed.substring(0, math.min(50, trimmed.length))}${trimmed.length > 50 ? '...' : ''}"');

    final user = _auth.currentUser;
    if (user == null) {
      print('❌ [COMMENT] No authenticated user');
      throw Exception('User not authenticated');
    }
    print('✅ [COMMENT] User authenticated: ${user.uid}');

    try {
      print('🔍 [COMMENT] Checking if post exists...');
      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        print('❌ [COMMENT] Post does not exist: $postId');
        throw Exception('Post does not exist');
      }

      print('✅ [COMMENT] Post exists, status: ${postDoc.data()?['status']}');
      final commentRef = postRef.collection('comments').doc();

      print('📝 [COMMENT] Ensuring user document exists...');
      final userDoc = await _ensureUserDocument(user.uid);
      final userData = userDoc.data() ?? {};
      print('✅ [COMMENT] User document ready');

      final authorName = userData['username'] ??
          user.displayName ??
          (user.email?.split('@').first ?? 'User');

      final authorAvatarUrl = userData['avatarUrl'] ?? user.photoURL ?? '';

      final commentData = {
        'postId': postId,
        'userId': user.uid,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'text': trimmed,
        'status': 'visible',
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
        'replyCount': 0,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      };

      print('🔍 [COMMENT] Validating comment data against Firestore rules...');
      print('   userId: ${commentData['userId']} (should equal auth.uid: ${user.uid})');
      print('   text: "${commentData['text']}" (length: ${(commentData['text'] as String).length})');
      print('   text is string: ${commentData['text'] is String}');
      print('   text length > 0: ${(commentData['text'] as String).isNotEmpty}');
      print('   text length <= 2000: ${(commentData['text'] as String).length <= 2000}');
      print('📋 [COMMENT] Comment data prepared');
      print('   Author Name: ${commentData['authorName']}');
      print('   Avatar URL: ${commentData['authorAvatarUrl']?.isNotEmpty ?? false ? 'present' : 'empty'}');

      print('🔄 [COMMENT] Creating comment document...');
      try {
        print('   📝 Comment data keys: ${commentData.keys.toList()}');
        print('   Comment data types:');
        commentData.forEach((key, value) {
          print('     $key: ${value.runtimeType}');
        });

        // Create comment document directly - Cloud Function will handle counter updates
        await commentRef.set(commentData);
        print('   ✅ Comment document created successfully');
        print('✅ [COMMENT] Comment creation completed successfully');
      } catch (createError) {
        print('❌ [COMMENT] Comment creation failed: $createError');
        // If creation fails due to permission, try to get more details
        if (createError.toString().contains('permission-denied')) {
          print('🔍 [COMMENT] Checking permissions...');
          print('   - User authenticated: ${user != null}');
          print('   - User ID: ${user?.uid}');
          print('   - Post exists: ${postDoc.exists}');
          if (postDoc.exists) {
            print('   - Post data: ${postDoc.data()}');
          }

          // Try to read from the comments subcollection to check permissions
          try {
            final testQuery = await postRef.collection('comments').limit(1).get();
            print('   - Can query comments collection: ${testQuery.docs.isNotEmpty}');
          } catch (queryError) {
            print('   - Cannot query comments collection: $queryError');
          }
        }
        rethrow;
      }

      // Add a small delay to ensure comment is created and Cloud Function has processed it
      await Future.delayed(const Duration(milliseconds: 200));

      print('📖 [COMMENT] Fetching created comment...');
      final created = await commentRef.get();
      if (!created.exists) {
        print('❌ [COMMENT] Created comment document not found');
        throw Exception('Failed to create comment');
      }

      final result = PostComment.fromJson(created.data() ?? commentData,
          id: created.id, postId: postId);
      print('✅ [COMMENT] Comment created successfully: ${result.id}');
      return result;
    } catch (e, stackTrace) {
      print('❌ [COMMENT] Error adding comment: $e');
      print('   Stack trace: $stackTrace');

      // Check for specific Firestore errors
      if (e.toString().contains('permission-denied')) {
        print('💡 [COMMENT] Permission denied - check Firestore rules for posts/$postId/comments');
        print('   Possible causes:');
        print('   - User not authenticated');
        print('   - Comment data doesn\'t match Firestore rules');
        print('   - Post may not exist or be accessible');
        print('   - Firestore emulator may not be running');
      } else if (e.toString().contains('not-found')) {
        print('💡 [COMMENT] Post not found - verify postId exists');
      } else if (e.toString().contains('failed-precondition')) {
        print('💡 [COMMENT] Failed precondition - check if post exists and is accessible');
      } else if (e.toString().contains('cancelled')) {
        print('💡 [COMMENT] Operation cancelled - possible network issue');
      } else if (e.toString().contains('unavailable')) {
        print('💡 [COMMENT] Service unavailable - check Firebase emulator status');
      } else if (e.toString().contains('deadline-exceeded')) {
        print('💡 [COMMENT] Operation timeout - check network connection');
      }

      print('🔍 [COMMENT] Full error details: $e');

      rethrow;
    }
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(commentRef);
      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();
      if (data == null || data['userId'] != user.uid) {
        throw Exception('Cannot delete comment you do not own');
      }

      transaction.delete(commentRef);
      transaction.update(postRef, {
        'commentCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<bool> likeComment({
    required String postId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final likeRef = commentRef.collection('likes').doc(user.uid);
    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      // Unlike
      await likeRef.delete();
      await commentRef.update({
        'likeCount': FieldValue.increment(-1),
      });
      return false;
    } else {
      // Like
      await likeRef.set({
        'likedAt': FieldValue.serverTimestamp(),
      });
      await commentRef.update({
        'likeCount': FieldValue.increment(1),
      });
      return true;
    }
  }

  @override
  Stream<List<PostComment>> streamReplies({
    required String postId,
    required String commentId,
  }) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .where('parentCommentId', isEqualTo: commentId)
        .where('status', isEqualTo: 'visible')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                PostComment.fromJson(doc.data(), id: doc.id, postId: postId))
            .toList());
  }

  @override
  Future<void> followUser(String targetUid) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    if (userId == targetUid) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final targetRef = _firestore.collection('users').doc(targetUid);

      // Use batch to update both documents atomically
      final batch = _firestore.batch();
      batch.set(userRef, {
        'followedBloggerIds': FieldValue.arrayUnion([targetUid]),
        'followingCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      batch.set(targetRef, {
        'followersCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();
      print('✅ followUser: $userId -> $targetUid');
    } catch (e) {
      print('❌ Error following user $targetUid: $e');
      rethrow;
    }
  }

  @override
  Future<void> unfollowUser(String targetUid) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    if (userId == targetUid) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final targetRef = _firestore.collection('users').doc(targetUid);

      final batch = _firestore.batch();
      batch.set(userRef, {
        'followedBloggerIds': FieldValue.arrayRemove([targetUid]),
        'followingCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));

      batch.set(targetRef, {
        'followersCount': FieldValue.increment(-1),
      }, SetOptions(merge: true));

      await batch.commit();
      print('✅ unfollowUser: $userId -/-> $targetUid');
    } catch (e) {
      print('❌ Error unfollowing user $targetUid: $e');
      rethrow;
    }
  }

  @override
  Future<void> blockUser(String blockedUid) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    if (userId == blockedUid) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.set({
        'blockedUserIds': FieldValue.arrayUnion([blockedUid]),
      }, SetOptions(merge: true));

      print('✅ blockUser: $userId blocked $blockedUid');
    } catch (e) {
      print('❌ Error blocking user $blockedUid: $e');
      rethrow;
    }
  }

  @override
  Future<void> unblockUser(String blockedUid) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    if (userId == blockedUid) return;

    try {
      final userRef = _firestore.collection('users').doc(userId);

      await userRef.set({
        'blockedUserIds': FieldValue.arrayRemove([blockedUid]),
      }, SetOptions(merge: true));

      print('✅ unblockUser: $userId unblocked $blockedUid');
    } catch (e) {
      print('❌ Error unblocking user $blockedUid: $e');
      rethrow;
    }
  }

  // ==================== Match Report Methods ====================

  @override
  Future<void> saveMatchRecord(MatchRecord record) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('matchRecords')
          .doc(record.id)
          .set(record.toJson());

      print('✅ Match record saved: ${record.id}');
    } catch (e) {
      print('❌ Error saving match record: $e');
      rethrow;
    }
  }

  @override
  Future<List<MatchRecord>> getMatchHistory({
    required String userId,
    DateRange? dateRange,
    MatchAction? filterAction,
    int? limit,
    String? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('matchRecords')
          .orderBy('createdAt', descending: true);

      // Apply date range filter
      if (dateRange != null) {
        query = query
            .where('createdAt',
                isGreaterThanOrEqualTo: dateRange.start.toIso8601String())
            .where('createdAt',
                isLessThanOrEqualTo: dateRange.end.toIso8601String());
      }

      // Apply action filter
      if (filterAction != null) {
        query = query.where('action', isEqualTo: filterAction.name);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final records = snapshot.docs
          .map((doc) => MatchRecord.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      print('✅ Loaded ${records.length} match records');
      return records;
    } catch (e) {
      print('❌ Error loading match history: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMatchAction({
    required String userId,
    required String matchRecordId,
    required MatchAction action,
    int? chatMessageCount,
  }) async {
    try {
      final updates = <String, dynamic>{
        'action': action.name,
        'lastInteractionAt': DateTime.now().toIso8601String(),
      };

      if (chatMessageCount != null) {
        updates['chatMessageCount'] = chatMessageCount;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('matchRecords')
          .doc(matchRecordId)
          .update(updates);

      print('✅ Match action updated: $matchRecordId -> ${action.name}');
    } catch (e) {
      print('❌ Error updating match action: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMatchFrequencyWithUser({
    required String userId,
    required String matchedUserId,
    DateRange? dateRange,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('matchRecords')
          .where('matchedUserId', isEqualTo: matchedUserId)
          .orderBy('createdAt', descending: true);

      if (dateRange != null) {
        query = query
            .where('createdAt',
                isGreaterThanOrEqualTo: dateRange.start.toIso8601String())
            .where('createdAt',
                isLessThanOrEqualTo: dateRange.end.toIso8601String());
      }

      final snapshot = await query.get();
      final records = snapshot.docs
          .map((doc) => MatchRecord.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      final chattedCount = records.where((r) => r.action == MatchAction.chatted).length;
      final avgScore = records.isEmpty
          ? 0.0
          : records.map((r) => r.compatibilityScore).reduce((a, b) => a + b) / records.length;

      return {
        'totalMatches': records.length,
        'chattedCount': chattedCount,
        'avgCompatibilityScore': avgScore,
        'records': records,
        'firstMatchDate': records.isNotEmpty ? records.last.createdAt : null,
        'lastMatchDate': records.isNotEmpty ? records.first.createdAt : null,
      };
    } catch (e) {
      print('❌ Error getting match frequency: $e');
      return {
        'totalMatches': 0,
        'chattedCount': 0,
        'avgCompatibilityScore': 0.0,
        'records': <MatchRecord>[],
        'firstMatchDate': null,
        'lastMatchDate': null,
      };
    }
  }

  @override
  Future<MatchReport> generateMatchReport({
    required String userId,
    required DateRange dateRange,
  }) async {
    try {
      // 1. Get all records in date range
      final records = await getMatchHistory(
        userId: userId,
        dateRange: dateRange,
      );

      if (records.isEmpty) {
        return _emptyReport(userId, dateRange);
      }

      // 2. Calculate statistics
      final statistics = _calculateStatistics(records);

      // 3. Analyze traits
      final traitAnalysis = _analyzeTraits(records);

      // 4. Find top matches
      final topMatches = _findTopMatches(records);

      // 5. Generate trends
      final trends = _generateTrends(records, dateRange);

      print('✅ Generated match report for ${dateRange.label}');

      return MatchReport(
        userId: userId,
        dateRange: dateRange,
        statistics: statistics,
        traitAnalysis: traitAnalysis,
        topMatches: topMatches,
        trends: trends,
      );
    } catch (e) {
      print('❌ Error generating match report: $e');
      rethrow;
    }
  }

  MatchReport _emptyReport(String userId, DateRange dateRange) {
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

  MatchStatistics _calculateStatistics(List<MatchRecord> records) {
    final totalMatches = records.length;
    final chattedCount =
        records.where((r) => r.action == MatchAction.chatted).length;
    final skippedCount =
        records.where((r) => r.action == MatchAction.skipped).length;

    final avgCompatibility = records.isEmpty
        ? 0.0
        : records.map((r) => r.compatibilityScore).reduce((a, b) => a + b) /
            records.length;

    final maxCompatibility = records.isEmpty
        ? 0.0
        : records
            .map((r) => r.compatibilityScore)
            .reduce((a, b) => a > b ? a : b);

    final totalChatMessages =
        records.map((r) => r.chatMessageCount).fold(0, (sum, count) => sum + count);

    final actionDistribution = {
      'none': records.where((r) => r.action == MatchAction.none).length,
      'chatted': chattedCount,
      'skipped': skippedCount,
    };

    return MatchStatistics(
      totalMatches: totalMatches,
      chattedCount: chattedCount,
      skippedCount: skippedCount,
      avgCompatibility: avgCompatibility,
      maxCompatibility: maxCompatibility,
      totalChatMessages: totalChatMessages,
      actionDistribution: actionDistribution,
    );
  }

  List<TraitAnalysis> _analyzeTraits(List<MatchRecord> records) {
    final traitMap = <String, List<MatchRecord>>{};

    // Group records by traits
    for (final record in records) {
      for (final trait in record.featureScores.keys) {
        traitMap.putIfAbsent(trait, () => []).add(record);
      }
    }

    // Calculate analysis for each trait
    return traitMap.entries.map((entry) {
      final trait = entry.key;
      final traitRecords = entry.value;

      final avgScore = traitRecords
              .map((r) => r.featureScores[trait]?.score ?? 0)
              .reduce((a, b) => a + b) /
          traitRecords.length;

      final chattedCount =
          traitRecords.where((r) => r.action == MatchAction.chatted).length;
      final successRate =
          traitRecords.isEmpty ? 0.0 : chattedCount / traitRecords.length;

      return TraitAnalysis(
        trait: trait,
        matchCount: traitRecords.length,
        avgScore: avgScore,
        successRate: successRate,
      );
    }).toList()
      ..sort((a, b) => b.matchCount.compareTo(a.matchCount)); // Sort by frequency
  }

  List<TopMatch> _findTopMatches(List<MatchRecord> records) {
    // Sort by compatibility score
    final sortedRecords = List<MatchRecord>.from(records)
      ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

    // Take top 3
    final topRecords = sortedRecords.take(3).toList();

    return topRecords.map((record) {
      String reason;
      if (record.action == MatchAction.chatted) {
        reason = '高匹配度且已开始聊天';
      } else if (record.compatibilityScore > 0.8) {
        reason = '超高兼容性 ${(record.compatibilityScore * 100).toInt()}%';
      } else {
        reason = '兼容性 ${(record.compatibilityScore * 100).toInt()}%';
      }

      return TopMatch(record: record, reason: reason);
    }).toList();
  }

  List<MatchTrend> _generateTrends(
      List<MatchRecord> records, DateRange dateRange) {
    // Group by date (by day)
    final dateMap = <String, List<MatchRecord>>{};

    for (final record in records) {
      final dateKey =
          '${record.createdAt.year}-${record.createdAt.month}-${record.createdAt.day}';
      dateMap.putIfAbsent(dateKey, () => []).add(record);
    }

    // Create trends
    final trends = dateMap.entries.map((entry) {
      final dateStr = entry.key;
      final dayRecords = entry.value;

      final avgScore = dayRecords
              .map((r) => r.compatibilityScore)
              .reduce((a, b) => a + b) /
          dayRecords.length;

      final dateParts = dateStr.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      return MatchTrend(
        date: date,
        matchCount: dayRecords.length,
        avgScore: avgScore,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return trends;
  }

  @override
  Future<MatchReport?> getCachedReport({
    required String userId,
    required DateRange dateRange,
  }) async {
    try {
      // For now, we don't cache reports. Could add caching later.
      return null;
    } catch (e) {
      print('❌ Error getting cached report: $e');
      return null;
    }
  }

  @override
  Future<String> requestAIAnalysis({
    required String userId,
    required DateRange dateRange,
  }) async {
    try {
      final report = await generateMatchReport(
        userId: userId,
        dateRange: dateRange,
      );

      // Call Cloud Function for AI analysis
      final callable = _functions.httpsCallable('analyzeMatchPattern');
      final result = await callable.call({
        'userId': userId,
        'statistics': report.statistics.toJson(),
        'traitAnalysis': report.traitAnalysis.map((t) => t.toJson()).toList(),
        'dateRange': {
          'start': dateRange.start.toIso8601String(),
          'end': dateRange.end.toIso8601String(),
          'label': dateRange.label,
        },
      });

      print('✅ AI analysis completed');
      return result.data['analysis'] as String;
    } catch (e) {
      print('❌ Error requesting AI analysis: $e');
      // Return fallback analysis
      return _generateFallbackAnalysis(userId, dateRange);
    }
  }

  String _generateFallbackAnalysis(String userId, DateRange dateRange) {
    return '''
在${dateRange.label}期间，你的匹配之旅展现出独特的个性特征。

通过分析你的匹配记录，我们发现你在寻找志同道合的伙伴时，注重内在的共鸣和深度的交流。你的匹配偏好反映了对真实连接的渴望。

建议：
1. 继续保持开放的心态，给每一个潜在匹配更多了解的机会
2. 在聊天中展现你独特的个性和兴趣
3. 关注那些与你价值观相符的匹配对象

记住，每一次匹配都是一次新的可能性。保持真诚，你会找到真正契合的人。
''';
  }

  @override
  Future<YearlyAIAnalysis> requestYearlyAIAnalysis({
    required String userId,
    required DateRange dateRange,
  }) async {
    try {
      final report = await generateMatchReport(
        userId: userId,
        dateRange: dateRange,
      );

      final chatSummaries = await getChatHistorySummaries(
        userId: userId,
        dateRange: dateRange,
      );

      final callable = _functions.httpsCallable('analyzeYearlyPattern');
      final result = await callable.call({
        'userId': userId,
        'statistics': report.statistics.toJson(),
        'traitAnalysis': report.traitAnalysis.map((t) => t.toJson()).toList(),
        'chatSummaries': chatSummaries.map((c) => c.toJson()).toList(),
        'dateRange': {
          'start': dateRange.start.toIso8601String(),
          'end': dateRange.end.toIso8601String(),
          'label': dateRange.label,
        },
      });

      print('✅ Yearly AI analysis completed');
      print('📋 Raw AI response: ${result.data}');
      
      // Parse the response and construct complete YearlyAIAnalysis
      final responseData = result.data as Map<String, dynamic>;
      final analysis = YearlyAIAnalysis(
        userId: userId,
        dateRange: dateRange,
        overallSummary: responseData['overallSummary'] as String? ?? '',
        insights: Map<String, String>.from(responseData['insights'] ?? {}),
        recommendations: List<String>.from(responseData['recommendations'] ?? []),
        personalityTraits: Map<String, double>.from(
          (responseData['personalityTraits'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toDouble()),
              ) ??
              {},
        ),
        topPreferences: List<String>.from(responseData['topPreferences'] ?? []),
        generatedAt: responseData['generatedAt'] != null 
            ? DateTime.parse(responseData['generatedAt'] as String)
            : DateTime.now(),
      );
      
      // Persist the analysis so it can be shown later without regenerating
      try {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('yearlyAnalyses')
            .doc(dateRange.label);
        await docRef.set(analysis.toJson());
      } catch (e) {
        print('⚠️ Warning: failed to persist yearly AI analysis: $e');
      }

      return analysis;
    } catch (e) {
      print('❌ Error requesting yearly AI analysis: $e');
      return _generateFallbackYearlyAnalysis(userId, dateRange);
    }
  }

  @override
  Future<YearlyAIAnalysis?> getCachedYearlyAIAnalysis({
    required String userId,
    required DateRange dateRange,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('yearlyAnalyses')
          .doc(dateRange.label)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data() as Map<String, dynamic>;
      return YearlyAIAnalysis.fromJson(data);
    } catch (e) {
      print('❌ Error getting cached yearly analysis: $e');
      return null;
    }
  }

  YearlyAIAnalysis _generateFallbackYearlyAnalysis(String userId, DateRange dateRange) {
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
  Future<List<ChatHistorySummary>> getChatHistorySummaries({
    required String userId,
    DateRange? dateRange,
  }) async {
    try {
      Query query = _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('updatedAt', descending: true);

      if (dateRange != null) {
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end));
      }

      final snapshot = await query.get();
      final summaries = <ChatHistorySummary>[];

      for (final doc in snapshot.docs) {
        final conversation = Conversation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        final messageCount = await getChatMessageCount(conversation.id);
        
        if (messageCount > 0) {
          summaries.add(ChatHistorySummary.fromConversation(
            conversation,
            userId,
            messageCount,
          ));
        }
      }

      print('✅ Loaded ${summaries.length} chat history summaries');
      return summaries;
    } catch (e) {
      print('❌ Error getting chat history summaries: $e');
      return [];
    }
  }

  @override
  Future<int> getChatMessageCount(String conversationId) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting chat message count: $e');
      return 0;
    }
  }

  @override
  Future<Uint8List> exportReportToPDF({
    required MatchReport report,
  }) async {
    try {
      throw UnimplementedError('PDF export will be implemented in Phase 5');
    } catch (e) {
      print('❌ Error exporting PDF: $e');
      rethrow;
    }
  }

  @override
  Future<void> upgradeMembership({
    required MembershipTier tier,
    required int durationDays,
    String? subscriptionId,
  }) async {
    try {
      print('🔄 Calling Cloud Function upgradeMembership...');
      print('   - Tier: ${tier.name}');
      print('   - Duration: $durationDays days');
      print('   - Subscription ID: $subscriptionId');

      final callable = _functions.httpsCallable('upgradeMembership');
      final result = await callable.call({
        'tier': tier.name,
        'durationDays': durationDays,
        'subscriptionId': subscriptionId,
      });

      print('✅ Membership upgraded successfully');
      print('   - Result: ${result.data}');
    } catch (e) {
      print('❌ Error upgrading membership: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelMembership() async {
    try {
      print('🔄 Calling Cloud Function cancelMembership...');

      final callable = _functions.httpsCallable('cancelMembership');
      await callable.call();

      print('✅ Membership cancelled successfully');
    } catch (e) {
      print('❌ Error cancelling membership: $e');
      rethrow;
    }
  }
}
