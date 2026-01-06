import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/pages/yearly_report_page.dart';
import 'package:flutter_app/pages/edit_profile_page.dart';
import 'package:flutter_app/pages/edit_post_page.dart';
import 'package:flutter_app/pages/match_history_page.dart';
import 'package:flutter_app/pages/post_detail_page.dart';
import 'package:flutter_app/pages/profile_card_page.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/models/user_data.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserData? _userData;
  List<Post> _userPosts = [];
  List<MatchRecord> _topMatches = [];
  bool _isLoading = true;
  String _currentSection = 'posts'; // 'posts', 'liked', 'favorited', 'matches'

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final apiService = locator<ApiService>();
        final userData = await apiService.getUser(currentUser.uid);
        final userPosts = await apiService.getMyPosts(currentUser.uid);
        
        List<MatchRecord> topMatches = [];
        try {
          final allMatches = await apiService.getMatchHistory(
            userId: currentUser.uid,
          );
          // Sort by compatibility score descending and take top 5
          allMatches.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
          topMatches = allMatches.take(5).toList();
        } catch (e) {
          print('⚠️ Error loading matches: $e');
        }

        if (mounted) {
          setState(() {
            _userData = userData;
            _userPosts = userPosts;
            _topMatches = topMatches;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSectionData() async {
    print('📂 [PROFILE_PAGE] Loading section data: $_currentSection');
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ [PROFILE_PAGE] No current user found');
        return;
      }

      print('👤 [PROFILE_PAGE] Current user: ${currentUser.uid}');
      final apiService = locator<ApiService>();
      
      // Always reload user data to sync liked/favorited arrays
      final userData = await apiService.getUser(currentUser.uid);
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
      
      if (_currentSection == 'liked') {
        print('🔄 [PROFILE_PAGE] Fetching liked posts...');
        final posts = await apiService.getLikedPosts(currentUser.uid);
        print('✅ [PROFILE_PAGE] Loaded ${posts.length} liked posts');
        if (mounted) setState(() => _userPosts = posts);
      } else if (_currentSection == 'favorited') {
        print('🔄 [PROFILE_PAGE] Fetching favorited posts...');
        final posts = await apiService.getFavoritedPosts(currentUser.uid);
        print('✅ [PROFILE_PAGE] Loaded ${posts.length} favorited posts');
        if (mounted) setState(() => _userPosts = posts);
      } else if (_currentSection == 'posts') {
        print('🔄 [PROFILE_PAGE] Fetching my posts...');
        final posts = await apiService.getMyPosts(currentUser.uid);
        print('✅ [PROFILE_PAGE] Loaded ${posts.length} my posts');
        if (mounted) setState(() => _userPosts = posts);
      }
    } catch (e) {
      print('❌ [PROFILE_PAGE] Error loading section data: $e');
      print('   Section: $_currentSection');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  void _refresh() {
    setState(() => _currentSection = 'posts');
    _loadUserData();
  }

  Future<void> _handleDeletePost(Post post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiService = locator<ApiService>();
      await apiService.deletePost(post.postId!);
      
      if (mounted) {
        setState(() {
          _userPosts.removeWhere((p) => p.postId == post.postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _handleEditPost(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostPage(post: post),
      ),
    );

    if (result == true) {
      _loadSectionData();
    }
  }

  Future<void> _handleLikeToggle(Post post) async {
    print('❤️ [PROFILE_PAGE] Like toggle for post: ${post.postId}');
    
    try {
      final apiService = locator<ApiService>();
      final newLikeStatus = await apiService.likePost(post.postId!);
      print('✅ [PROFILE_PAGE] API returned new like status: $newLikeStatus');
      
      // Reload section data to reflect changes
      await _loadSectionData();
    } catch (e) {
      print('❌ [PROFILE_PAGE] Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> _handleFavoriteToggle(Post post) async {
    print('⭐ [PROFILE_PAGE] Favorite toggle for post: ${post.postId}');
    
    try {
      final apiService = locator<ApiService>();
      final newFavoriteStatus = await apiService.toggleFavoritePost(post.postId!);
      print('✅ [PROFILE_PAGE] API returned new favorite status: $newFavoriteStatus');
      
      // Reload section data to reflect changes
      await _loadSectionData();
    } catch (e) {
      print('❌ [PROFILE_PAGE] Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Sanctuary',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: _userData),
                ),
              ).then((_) => _loadUserData());
            },
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/profile_card_editor')
                  .then((_) => _refresh());
            },
            tooltip: 'Edit Profile Card',
          ),
          IconButton(
            icon: const Icon(Icons.credit_card_outlined),
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileCardPage(userId: userId),
                  ),
                );
              }
            },
            tooltip: 'View Profile Card',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                children: [
                  _buildProfileHeader(theme),
                  const Divider(height: 1),
                  
                  if (_topMatches.isNotEmpty) ...[
                    _buildMatchHighlights(theme),
                    const Divider(height: 1),
                  ],
                  
                  _buildSectionSelector(theme),
                  _buildContentSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: _userData),
                ),
              );
              if (result != null) _loadUserData();
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: _userData?.avatarUrl != null && _userData!.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _userData!.avatarUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.person, size: 50, color: theme.primaryColor),
                ),
                // Membership badge - bottom right
                if (_userData?.hasActiveMembership == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _userData!.membershipTier == MembershipTier.pro
                              ? [Colors.amber, Colors.orange]
                              : [Colors.purple, Colors.deepPurple],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (_userData!.membershipTier == MembershipTier.pro
                                    ? Colors.amber
                                    : Colors.purple)
                                .withOpacity(0.5),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _userData!.membershipTier == MembershipTier.pro
                            ? Icons.workspace_premium
                            : Icons.star,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _userData?.username ?? 'Anonymous',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          if (_userData?.freeText.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _userData!.freeText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          const SizedBox(height: 16),

          if (_userData?.traits.isNotEmpty == true)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _userData!.traits.map((trait) {
                return Chip(
                  label: Text(trait),
                  labelStyle: TextStyle(fontSize: 12, color: theme.primaryColor),
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          
          if (_userData != null) ...[
            const SizedBox(height: 20),
            _buildProfileStats(theme),
          ],
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(userData: _userData),
                      ),
                    );
                    if (result != null) _loadUserData();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHighlights(ThemeData theme) {
    if (_topMatches.isEmpty) return const SizedBox.shrink();
    
    final topMatch = _topMatches.first;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Match',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const YearlyReportPage(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTopMatchCard(topMatch, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMatchCard(MatchRecord match, ThemeData theme) {
    final scoreColor = _getScoreColor(match.compatibilityScore);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.2),
            scoreColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const YearlyReportPage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    backgroundImage: match.matchedUserAvatar.isNotEmpty
                        ? NetworkImage(match.matchedUserAvatar)
                        : null,
                    child: match.matchedUserAvatar.isEmpty
                        ? Text(
                            match.matchedUsername[0].toUpperCase(),
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.matchedUsername,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${(match.compatibilityScore * 100).toInt()}% Match',
                              style: GoogleFonts.josefinSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _getActionIcon(match.action),
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getActionText(match.action),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getActionText(MatchAction action) {
    switch (action) {
      case MatchAction.chatted:
        return 'Chatted';
      case MatchAction.skipped:
        return 'Skipped';
      case MatchAction.none:
        return 'Pending';
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  IconData _getActionIcon(MatchAction action) {
    switch (action) {
      case MatchAction.chatted:
        return Icons.chat;
      case MatchAction.skipped:
        return Icons.skip_next;
      case MatchAction.none:
        return Icons.hourglass_empty;
    }
  }

  Widget _buildSectionSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildSectionButton('My Posts', 'posts', Icons.grid_on, theme),
          const SizedBox(width: 8),
          _buildSectionButton('Favorites', 'favorited', Icons.star, theme),
          const SizedBox(width: 8),
          _buildSectionButton('Liked', 'liked', Icons.favorite, theme),
        ],
      ),
    );
  }

  Widget _buildSectionButton(String label, String section, IconData icon, ThemeData theme) {
    final isSelected = _currentSection == section;
    return Expanded(
      child: Material(
        color: isSelected ? theme.primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _currentSection = section);
            _loadSectionData();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey[700]),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme) {
    if (_userPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.edit_note_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: _userPosts.map((post) {
          return StaggeredGridTile.count(
            crossAxisCellCount: post.crossAxisCellCount.round(),
            mainAxisCellCount: post.mainAxisCellCount,
            child: _PostCard(
              post: post,
              showOwnerOptions: _currentSection == 'posts',
              onEdit: () => _handleEditPost(post),
              onDelete: () => _handleDeletePost(post),
              onLike: () => _handleLikeToggle(post),
              onFavorite: () => _handleFavoriteToggle(post),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_currentSection) {
      case 'favorited':
        return 'No favorited posts yet.\nFavorite posts you love!';
      case 'liked':
        return 'No liked posts yet.\nStart exploring!';
      default:
        return 'Your space is empty.\nCreate your first post!';
    }
  }

  Widget _buildProfileStats(ThemeData theme) {
    final user = _userData;
    if (user == null) return const SizedBox.shrink();

    final stats = [
      _ProfileStat(label: 'Posts', value: user.postsCount),
      _ProfileStat(label: 'Likes', value: user.likedPostIds.length),
      _ProfileStat(label: 'Favorites', value: user.favoritedPostIds.length),
      _ProfileStat(label: 'Followers', value: user.followersCount),
      _ProfileStat(label: 'Following', value: user.followedBloggerIds.length),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
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
}

class _ProfileStat {
  final String label;
  final int value;

  const _ProfileStat({required this.label, required this.value});
}

class _PostCard extends StatelessWidget {
  final Post post;
  final bool showOwnerOptions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onFavorite;

  const _PostCard({
    required this.post,
    this.showOwnerOptions = false,
    this.onEdit,
    this.onDelete,
    this.onLike,
    this.onFavorite,
  });

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showOwnerOptions) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(post.isPublic ? 'Make Private' : 'Make Public'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
            if (showOwnerOptions) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(post: post),
          ),
        );
      },
      onLongPress: () => _showOptionsMenu(context),
      child: Container(
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
                        style: GoogleFonts.notoSerifSc(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              
              if (!post.isPublic)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Private',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (showOwnerOptions)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showOptionsMenu(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 18,
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
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          onLike?.call();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              post.isLiked ? Icons.favorite : Icons.favorite_border,
                              color: post.isLiked ? Colors.red : Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likes}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          onFavorite?.call();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              post.isFavorited ? Icons.star : Icons.star_border,
                              color: post.isFavorited ? Colors.amber : Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.favorites}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.comment, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${post.comments}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
