import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';

/// Public profile page that anyone can view (subject to privacy settings)
class PublicProfilePage extends StatefulWidget {
  final String userId;

  const PublicProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  UserData? _userData;
  List<Post> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = FirebaseAuth.instance.currentUser?.uid == widget.userId;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final apiService = locator<ApiService>();
      final userData = await apiService.getUser(widget.userId);
      final userPosts = await apiService.getMyPosts(widget.userId);

      // Check if following
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && currentUserId != widget.userId) {
        final currentUserData = await apiService.getUser(currentUserId);
        _isFollowing =
            currentUserData.followedBloggerIds.contains(widget.userId);
      }

      if (mounted) {
        setState(() {
          _userData = userData;
          _userPosts = userPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userData?.username ?? 'Profile',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.more_vert),
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
    if (_userData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'User not found',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Profile Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar with membership badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    backgroundImage: _userData!.avatarUrl != null &&
                            _userData!.avatarUrl!.isNotEmpty
                        ? NetworkImage(_userData!.avatarUrl!)
                        : null,
                    child: _userData!.avatarUrl == null ||
                            _userData!.avatarUrl!.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: theme.primaryColor,
                          )
                        : null,
                  ),
                  if (_userData!.membershipTier != MembershipTier.free)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[700]!, Colors.amber[400]!],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Username
              Text(
                _userData!.username,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Bio
              if (_userData!.freeText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _userData!.freeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Traits
              if (_userData!.traits.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _userData!.traits.map((trait) {
                    return Chip(
                      label: Text(trait),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor,
                      ),
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Stats
              _buildProfileStats(theme),
              const SizedBox(height: 24),

              // Action buttons
              if (!_isCurrentUser) _buildActionButtons(theme),
            ],
          ),
        ),

        const Divider(),

        // Posts Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Posts',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        _userPosts.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: StaggeredGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _userPosts.map((post) {
                    return StaggeredGridTile.count(
                      crossAxisCellCount: post.crossAxisCellCount.round(),
                      mainAxisCellCount: post.mainAxisCellCount,
                      child: _PostCard(post: post),
                    );
                  }).toList(),
                ),
              ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileStats(ThemeData theme) {
    final user = _userData!;

    final stats = [
      _ProfileStat(label: 'Posts', value: user.postsCount),
      _ProfileStat(label: 'Followers', value: user.followersCount),
      _ProfileStat(label: 'Following', value: user.followedBloggerIds.length),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 32,
      runSpacing: 12,
      children: stats
          .map(
            (stat) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _toggleFollow,
            icon: Icon(_isFollowing ? Icons.check : Icons.person_add),
            label: Text(_isFollowing ? 'Following' : 'Follow'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isFollowing ? Colors.grey[300] : theme.primaryColor,
              foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message feature coming soon!')),
              );
            },
            icon: const Icon(Icons.message_outlined),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFollow() async {
    final apiService = locator<ApiService>();
    final previous = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);
    try {
      if (_isFollowing) {
        await apiService.followUser(widget.userId);
      } else {
        await apiService.unfollowUser(widget.userId);
      }
    } catch (e) {
      print('❌ Error toggling follow: $e');
      // revert optimistic update
      if (mounted) setState(() => _isFollowing = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update follow status')),
      );
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report User'),
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
        ),
      ),
    );
  }
}

class _ProfileStat {
  final String label;
  final int value;

  const _ProfileStat({required this.label, required this.value});
}

class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.media.isNotEmpty && post.media.first.startsWith('http'))
              Image.network(post.media.first, fit: BoxFit.cover)
            else if (post.media.isNotEmpty)
              Image.asset(
                post.media.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.image_not_supported)),
              )
            else
              Container(
                color: Colors.grey[200],
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      post.content,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likes}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
