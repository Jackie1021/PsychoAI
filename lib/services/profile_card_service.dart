import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/profile_card.dart';
import 'package:flutter_app/models/profile_card_theme.dart';
import 'package:flutter_app/models/user_data.dart';

/// Reason why user cannot view profile card
enum ViewBlockReason {
  noSubscriptionAndQuotaExceeded,
  blockedByUser,
  privacyRestriction,
  userSuspended,
  notFound,
}

/// View permission result
class ViewPermission {
  final bool canView;
  final ViewBlockReason? reason;
  final int remainingFreeViews;
  final bool requiresSubscription;

  const ViewPermission({
    required this.canView,
    this.reason,
    required this.remainingFreeViews,
    this.requiresSubscription = false,
  });

  ViewPermission copyWith({
    bool? canView,
    ViewBlockReason? reason,
    int? remainingFreeViews,
    bool? requiresSubscription,
  }) {
    return ViewPermission(
      canView: canView ?? this.canView,
      reason: reason ?? this.reason,
      remainingFreeViews: remainingFreeViews ?? this.remainingFreeViews,
      requiresSubscription: requiresSubscription ?? this.requiresSubscription,
    );
  }
}

/// Service for managing profile card views and permissions
class ProfileCardService {
  static const int FREE_VIEWS_PER_DAY = 3;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user can view target's profile card
  Future<ViewPermission> checkViewPermission(String targetUserId) async {
    try {
      if (_currentUserId == null) {
        return ViewPermission(
          canView: false,
          reason: ViewBlockReason.privacyRestriction,
          remainingFreeViews: 0,
        );
      }

      // Own profile card is always viewable
      if (_currentUserId == targetUserId) {
        return ViewPermission(
          canView: true,
          remainingFreeViews: FREE_VIEWS_PER_DAY,
        );
      }

      // Check if target user exists and get their privacy settings
      final targetUserDoc =
          await _firestore.collection('users').doc(targetUserId).get();

      if (!targetUserDoc.exists) {
        return ViewPermission(
          canView: false,
          reason: ViewBlockReason.notFound,
          remainingFreeViews: 0,
        );
      }

      final targetUser = UserData.fromJson(targetUserDoc.data()!);

      // Check if user is suspended
      if (targetUser.isSuspended) {
        return ViewPermission(
          canView: false,
          reason: ViewBlockReason.userSuspended,
          remainingFreeViews: 0,
        );
      }

      // Check privacy settings
      final privacyDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('private')
          .doc('privacy_settings')
          .get();

      if (privacyDoc.exists) {
        // Will implement full privacy check later
        // For now, check basic blocked status
      }

      // Get profile card
      final profileCardDoc =
          await _firestore.collection('profileCards').doc(targetUserId).get();

      if (!profileCardDoc.exists) {
        return ViewPermission(
          canView: false,
          reason: ViewBlockReason.notFound,
          remainingFreeViews: 0,
        );
      }

      final profileCard = ProfileCard.fromJson(profileCardDoc.data()!);

      // Check if stranger access is allowed
      if (!profileCard.privacy.allowStrangerAccess) {
        // TODO: Check if users are friends
        return ViewPermission(
          canView: false,
          reason: ViewBlockReason.privacyRestriction,
          remainingFreeViews: 0,
        );
      }

      // Check subscription status
      final hasSubscription = await hasActiveSubscription();

      if (hasSubscription) {
        return ViewPermission(
          canView: true,
          remainingFreeViews: FREE_VIEWS_PER_DAY, // Unlimited for subscribers
        );
      }

      // Check daily quota for free users
      final usedViews = await getTodayUsedViews();
      final remaining = FREE_VIEWS_PER_DAY - usedViews;

      if (remaining > 0) {
        return ViewPermission(
          canView: true,
          remainingFreeViews: remaining,
        );
      }

      return ViewPermission(
        canView: false,
        reason: ViewBlockReason.noSubscriptionAndQuotaExceeded,
        remainingFreeViews: 0,
        requiresSubscription: true,
      );
    } catch (e) {
      print('❌ Error checking view permission: $e');
      return ViewPermission(
        canView: false,
        reason: ViewBlockReason.privacyRestriction,
        remainingFreeViews: 0,
      );
    }
  }

  /// Record a profile card view
  Future<void> recordView(String targetUserId) async {
    if (_currentUserId == null || _currentUserId == targetUserId) return;

    try {
      final today = _getTodayDateString();
      final dailyViewRef = _firestore
          .collection('profileCardViews')
          .doc(_currentUserId)
          .collection('daily')
          .doc(today);

      await _firestore.runTransaction((transaction) async {
        final dailyDoc = await transaction.get(dailyViewRef);

        if (dailyDoc.exists) {
          final data = dailyDoc.data()!;
          final viewedUserIds =
              List<String>.from(data['viewedUserIds'] as List? ?? []);

          if (!viewedUserIds.contains(targetUserId)) {
            transaction.update(dailyViewRef, {
              'count': FieldValue.increment(1),
              'viewedUserIds': FieldValue.arrayUnion([targetUserId]),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        } else {
          transaction.set(dailyViewRef, {
            'count': 1,
            'viewedUserIds': [targetUserId],
            'date': today,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Record in history
      await _firestore
          .collection('profileCardViews')
          .doc(_currentUserId)
          .collection('history')
          .add({
        'viewerUserId': _currentUserId,
        'targetUserId': targetUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Increment view count on profile card
      await _firestore.collection('profileCards').doc(targetUserId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Error recording view: $e');
    }
  }

  /// Get today's used view count
  Future<int> getTodayUsedViews() async {
    if (_currentUserId == null) return 0;

    try {
      final today = _getTodayDateString();
      final dailyDoc = await _firestore
          .collection('profileCardViews')
          .doc(_currentUserId)
          .collection('daily')
          .doc(today)
          .get();

      if (dailyDoc.exists) {
        return (dailyDoc.data()?['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Error getting today used views: $e');
      return 0;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    if (_currentUserId == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();

      if (!userDoc.exists) return false;

      final userData = UserData.fromJson(userDoc.data()!);
      return userData.hasActiveMembership;
    } catch (e) {
      print('❌ Error checking subscription: $e');
      return false;
    }
  }

  /// Get profile card by user ID
  Future<ProfileCard?> getProfileCard(String userId) async {
    try {
      final doc = await _firestore.collection('profileCards').doc(userId).get();

      if (!doc.exists) return null;

      return ProfileCard.fromJson(doc.data()!);
    } catch (e) {
      print('❌ Error getting profile card: $e');
      return null;
    }
  }

  /// Update user's profile card
  Future<void> updateProfileCard(ProfileCard profileCard) async {
    if (_currentUserId == null || _currentUserId != profileCard.uid) {
      throw Exception('Unauthorized to update profile card');
    }

    try {
      await _firestore
          .collection('profileCards')
          .doc(profileCard.uid)
          .set(profileCard.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('❌ Error updating profile card: $e');
      rethrow;
    }
  }

  /// Create profile card from user data
  Future<void> createProfileCard(UserData userData) async {
    try {
      final profileCard = ProfileCard.fromUserData(userData);
      await _firestore
          .collection('profileCards')
          .doc(userData.uid)
          .set(profileCard.toJson());
    } catch (e) {
      print('❌ Error creating profile card: $e');
      rethrow;
    }
  }

  /// Sync profile card with latest user data
  Future<void> syncProfileCardWithUserData(
      String userId, UserData userData) async {
    try {
      final existingCard = await getProfileCard(userId);

      if (existingCard == null) {
        await createProfileCard(userData);
        return;
      }

      // Update with latest user data but preserve card-specific settings
      final updatedCard = existingCard.copyWith(
        username: userData.username,
        avatarUrl: userData.avatarUrl,
        bio: userData.freeText,
        highlightedTraits: userData.traits.take(5).toList(),
        postsCount: userData.postsCount,
        membershipTier: userData.membershipTier,
        lastUpdated: DateTime.now(),
      );

      await updateProfileCard(updatedCard);
    } catch (e) {
      print('❌ Error syncing profile card: $e');
      rethrow;
    }
  }

  /// Update match count from match history
  Future<void> updateMatchCount(String userId, int matchCount) async {
    try {
      await _firestore.collection('profileCards').doc(userId).update({
        'matchesCount': matchCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating match count: $e');
    }
  }

  /// Add a match to public match list
  Future<void> addPublicMatch(String userId, String matchId) async {
    try {
      await _firestore.collection('profileCards').doc(userId).update({
        'publicMatchIds': FieldValue.arrayUnion([matchId]),
        'matchesCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error adding public match: $e');
    }
  }

  /// Remove a match from public match list
  Future<void> removePublicMatch(String userId, String matchId) async {
    try {
      await _firestore.collection('profileCards').doc(userId).update({
        'publicMatchIds': FieldValue.arrayRemove([matchId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error removing public match: $e');
    }
  }

  /// Update featured posts
  Future<void> updateFeaturedPosts(
      String userId, List<String> postIds) async {
    if (_currentUserId == null || _currentUserId != userId) {
      throw Exception('Unauthorized');
    }

    try {
      await _firestore.collection('profileCards').doc(userId).update({
        'featuredPostIds': postIds.take(3).toList(), // Max 3
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating featured posts: $e');
      rethrow;
    }
  }

  /// Like a profile card
  Future<void> likeProfileCard(String targetUserId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('profileCards').doc(targetUserId).update({
        'likeCount': FieldValue.increment(1),
      });

      // Record like in user's liked list
      await _firestore.collection('users').doc(_currentUserId).update({
        'likedProfileCardIds': FieldValue.arrayUnion([targetUserId]),
      });
    } catch (e) {
      print('❌ Error liking profile card: $e');
    }
  }

  /// Unlike a profile card
  Future<void> unlikeProfileCard(String targetUserId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore.collection('profileCards').doc(targetUserId).update({
        'likeCount': FieldValue.increment(-1),
      });

      await _firestore.collection('users').doc(_currentUserId).update({
        'likedProfileCardIds': FieldValue.arrayRemove([targetUserId]),
      });
    } catch (e) {
      print('❌ Error unliking profile card: $e');
    }
  }

  /// Get today's date string (YYYY-MM-DD)
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get profile card customization
  Future<ProfileCardCustomization?> getCustomization(String userId) async {
    try {
      final doc = await _firestore
          .collection('profileCards')
          .doc(userId)
          .collection('settings')
          .doc('customization')
          .get();

      if (!doc.exists) return null;

      return ProfileCardCustomization.fromJson(doc.data()!);
    } catch (e) {
      print('❌ Error getting customization: $e');
      return null;
    }
  }

  /// Save profile card customization
  Future<void> saveCustomization(
      String userId, ProfileCardCustomization customization) async {
    if (_currentUserId == null || _currentUserId != userId) {
      throw Exception('Unauthorized');
    }

    try {
      await _firestore
          .collection('profileCards')
          .doc(userId)
          .collection('settings')
          .doc('customization')
          .set(customization.toJson(), SetOptions(merge: true));
    } catch (e) {
      print('❌ Error saving customization: $e');
      rethrow;
    }
  }
}
