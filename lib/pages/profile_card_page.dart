import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/profile_card.dart';
import 'package:flutter_app/models/profile_card_theme.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/services/profile_card_service.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/widgets/subscription_prompt_dialog.dart';
import 'package:flutter_app/widgets/profile_card_preview.dart';
import 'package:flutter_app/pages/public_profile_page.dart';

class ProfileCardPage extends StatefulWidget {
  final String userId;

  const ProfileCardPage({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileCardPage> createState() => _ProfileCardPageState();
}

class _ProfileCardPageState extends State<ProfileCardPage>
    with SingleTickerProviderStateMixin {
  final ProfileCardService _service = ProfileCardService();
  final ApiService _apiService = locator<ApiService>();
  ProfileCard? _profileCard;
  ProfileCardCustomization? _customization;
  List<Post> _userPosts = [];
  List<MatchRecord> _matchHistory = [];
  MatchRecord? _topMatch;
  ViewPermission? _permission;
  bool _isLoading = true;
  bool _hasRecordedView = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _loadProfileCard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileCard() async {
    setState(() => _isLoading = true);

    try {
      // Check permission first
      final permission = await _service.checkViewPermission(widget.userId);
      setState(() => _permission = permission);

      if (!permission.canView) {
        setState(() => _isLoading = false);

        if (permission.reason ==
            ViewBlockReason.noSubscriptionAndQuotaExceeded) {
          _showSubscriptionPrompt();
        }
        return;
      }

      // Load profile card
      final profileCard = await _service.getProfileCard(widget.userId);

      if (profileCard == null) {
        throw Exception('Profile card not found');
      }

      // Load customization
      final customization = await _service.getCustomization(widget.userId);

      // Load user posts if customization allows
      List<Post> posts = [];
      if (customization?.showPosts == true) {
        try {
          posts = await _apiService.getMyPosts(widget.userId);
        } catch (e) {
          print('⚠️ Warning: Could not load posts: $e');
        }
      }

      // Load match history if customization allows
      List<MatchRecord> matches = [];
      if (customization?.showMatches == true) {
        try {
          matches = await _apiService.getMatchHistory(
            userId: widget.userId,
            limit: 10,
          );
          print('📊 Loaded ${matches.length} match records');
        } catch (e) {
          print('⚠️ Warning: Could not load matches: $e');
        }
      }

      // Record view (only once)
      if (!_hasRecordedView) {
        await _service.recordView(widget.userId);
        _hasRecordedView = true;
      }

      // Determine top match (highest compatibility) for display on profile top
      MatchRecord? topMatch;
      if (matches.isNotEmpty) {
        topMatch = matches.reduce((a, b) =>
            a.compatibilityScore >= b.compatibilityScore ? a : b);
      }

      setState(() {
        _profileCard = profileCard;
        _customization = customization ?? const ProfileCardCustomization();
        _userPosts = posts;
        _matchHistory = matches;
        _topMatch = topMatch;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      print('❌ Error loading profile card: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile card: $e')),
        );
      }
    }
  }

  void _showSubscriptionPrompt() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      SubscriptionPromptDialog.show(
        context,
        remainingFreeViews: _permission?.remainingFreeViews ?? 0,
        onSubscribe: () {
          // Navigate to subscription page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription feature coming soon!'),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_profileCard != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.more_vert, color: Colors.black87),
              ),
              onPressed: () => _showOptionsMenu(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_permission == null || !_permission!.canView) {
      return _buildBlockedView(theme);
    }

    if (_profileCard == null || _customization == null) {
      return _buildErrorView(theme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ProfileCardPreview(
                  profileCard: _profileCard!,
                  customization: _customization!,
                  posts: _userPosts,
                  matches: _matchHistory,
                  topMatch: _topMatch,
                  isInteractive: false,
                ),
                ),
                const SizedBox(height: 24),
                _buildActionButtons(theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.person_outline,
              label: 'View Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PublicProfilePage(userId: widget.userId),
                  ),
                );
              },
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.message_outlined,
              label: 'Message',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Messaging feature coming soon!')),
                );
              },
              theme: theme,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? theme.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isPrimary ? 0 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isPrimary
                ? null
                : Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : theme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedView(ThemeData theme) {
    String message = 'Cannot view this profile card';
    IconData icon = Icons.block;

    switch (_permission?.reason) {
      case ViewBlockReason.noSubscriptionAndQuotaExceeded:
        message = 'You\'ve used all free views today';
        icon = Icons.lock_outline;
        break;
      case ViewBlockReason.blockedByUser:
        message = 'You cannot view this user\'s profile';
        icon = Icons.block;
        break;
      case ViewBlockReason.privacyRestriction:
        message = 'This profile is private';
        icon = Icons.privacy_tip_outlined;
        break;
      case ViewBlockReason.userSuspended:
        message = 'This user account is suspended';
        icon = Icons.warning_outlined;
        break;
      default:
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_permission?.requiresSubscription == true)
            ElevatedButton.icon(
              onPressed: () => _showSubscriptionPrompt(),
              icon: const Icon(Icons.star),
              label: const Text('Subscribe to View'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Profile card not found',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnCard = currentUserId == widget.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnCard) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profile Card'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile_card_editor')
                      .then((_) => _loadProfileCard());
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_outlined),
                title: const Text('Refresh'),
                onTap: () {
                  Navigator.pop(context);
                  _loadProfileCard();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Block feature coming soon!')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
