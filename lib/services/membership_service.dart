import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/user_data.dart';

/// 会员系统管理类
class MembershipService {
  static const String _keyIsMember = 'is_member';
  static const String _keyDailyViewCount = 'daily_view_count';
  static const String _keyLastResetDate = 'last_reset_date';
  static const int maxDailyViews = 10; // 免费用户每日限制

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 从 Firestore 检查会员状态
  static Future<bool> isMember() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final tierString = data['membershipTier'] as String?;
      
      if (tierString == null || tierString == 'free') return false;

      // Check expiry
      final expiryValue = data['membershipExpiry'];
      if (expiryValue == null) return true; // Lifetime membership

      DateTime? expiry;
      if (expiryValue is Timestamp) {
        expiry = expiryValue.toDate();
      } else if (expiryValue is String) {
        expiry = DateTime.tryParse(expiryValue);
      }

      if (expiry == null) return false;
      return expiry.isAfter(DateTime.now());
    } catch (e) {
      print('Error checking membership: $e');
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsMember) ?? false;
    }
  }

  /// 设置会员状态（仅用于本地缓存）
  static Future<void> setMemberStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsMember, status);
  }

  /// 获取今日剩余查看次数
  static Future<int> getRemainingViews() async {
    if (await isMember()) return -1; // -1 表示无限制

    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    
    final count = prefs.getInt(_keyDailyViewCount) ?? 0;
    return maxDailyViews - count;
  }

  /// 消耗一次查看次数
  static Future<bool> consumeView() async {
    if (await isMember()) return true; // 会员直接通过

    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);

    final count = prefs.getInt(_keyDailyViewCount) ?? 0;
    if (count >= maxDailyViews) {
      return false; // 超出限制
    }

    await prefs.setInt(_keyDailyViewCount, count + 1);
    return true;
  }

  /// 重置每日计数（如果是新的一天）
  static Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_keyLastResetDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastReset != today) {
      await prefs.setInt(_keyDailyViewCount, 0);
      await prefs.setString(_keyLastResetDate, today);
    }
  }

  /// 获取今日已使用次数
  static Future<int> getTodayUsedViews() async {
    if (await isMember()) return 0;

    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return prefs.getInt(_keyDailyViewCount) ?? 0;
  }

  /// 升级到会员（更新 Firestore）
  static Future<void> upgradeMembership({
    required MembershipTier tier,
    required DateTime expiry,
    String? subscriptionId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _firestore.collection('users').doc(user.uid).update({
      'membershipTier': tier.name,
      'membershipExpiry': Timestamp.fromDate(expiry),
      'subscriptionId': subscriptionId,
      'lastActive': FieldValue.serverTimestamp(),
    });

    // Update local cache
    await setMemberStatus(tier != MembershipTier.free);

    // Log subscription
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('subscriptions')
        .add({
      'tier': tier.name,
      'startDate': FieldValue.serverTimestamp(),
      'expiryDate': Timestamp.fromDate(expiry),
      'subscriptionId': subscriptionId,
      'status': 'active',
    });
  }

  /// 取消会员
  static Future<void> cancelMembership() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _firestore.collection('users').doc(user.uid).update({
      'membershipTier': MembershipTier.free.name,
      'membershipExpiry': null,
      'lastActive': FieldValue.serverTimestamp(),
    });

    await setMemberStatus(false);
  }
}

/// 通知其他组件刷新会员状态
class MembershipChangeNotifier extends ChangeNotifier {
  bool _isMember = false;
  int _remainingViews = MembershipService.maxDailyViews;
  MembershipTier _tier = MembershipTier.free;
  DateTime? _expiry;

  bool get isMember => _isMember;
  int get remainingViews => _remainingViews;
  MembershipTier get tier => _tier;
  DateTime? get expiry => _expiry;

  Future<void> refresh() async {
    _isMember = await MembershipService.isMember();
    _remainingViews = await MembershipService.getRemainingViews();
    
    // Get tier from Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final tierString = data['membershipTier'] as String?;
          if (tierString != null) {
            _tier = MembershipTier.values.firstWhere(
              (e) => e.name == tierString,
              orElse: () => MembershipTier.free,
            );
          }

          final expiryValue = data['membershipExpiry'];
          if (expiryValue is Timestamp) {
            _expiry = expiryValue.toDate();
          }
        }
      }
    } catch (e) {
      print('Error loading membership tier: $e');
    }
    
    notifyListeners();
  }

  Future<void> setMemberStatus(bool status) async {
    await MembershipService.setMemberStatus(status);
    await refresh();
  }

  Future<void> upgrade({
    required MembershipTier tier,
    required DateTime expiry,
    String? subscriptionId,
  }) async {
    await MembershipService.upgradeMembership(
      tier: tier,
      expiry: expiry,
      subscriptionId: subscriptionId,
    );
    await refresh();
  }

  Future<void> cancel() async {
    await MembershipService.cancelMembership();
    await refresh();
  }
}
