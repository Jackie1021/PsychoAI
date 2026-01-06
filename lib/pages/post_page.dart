import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/pages/create_post_page.dart';
import 'package:flutter_app/pages/subscribe_page.dart';
import 'package:flutter_app/widgets/bottom_nav_bar_visibility_notification.dart';
import 'package:flutter_app/widgets/post_card.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';

// The main page displaying the masonry grid of posts
class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  UserData? _currentUser;
  MembershipTier _membershipTier = MembershipTier.free;
  late final ScrollController _scrollController;
  bool _isNavBarVisible = true;
  bool _isLoading = true;
  String? _error;
  
  // Unlock system
  final Set<int> _unlockedPostIndices = {}; // Track which posts are unlocked
  int _freeUnlocksUsed = 0; // Track how many free unlocks used today
  static const int _maxFreeUnlocks = 3; // Max free unlocks per day

  // Posts from backend
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadUserAndPosts();
  }
  
  Future<void> _loadUserAndPosts() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadPosts(),
    ]);
  }
  
  Future<void> _loadCurrentUser() async {
    print('🔄 [POST_PAGE] Loading current user...');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('👤 [POST_PAGE] Firebase user found: ${user.uid}');
        final apiService = locator<ApiService>();
        final userData = await apiService.getUser(user.uid);
        print('✅ [POST_PAGE] User data loaded: ${userData.username}');
        print('   - Membership: ${userData.membershipTier.name}');
        print('   - Has active: ${userData.hasActiveMembership}');
        print('   - Expiry: ${userData.membershipExpiry}');
        print('   - Effective tier: ${userData.effectiveTier.name}');
        
        if (mounted) {
          setState(() {
            _currentUser = userData;
            _membershipTier = userData.effectiveTier;
          });
          print('✅ [POST_PAGE] State updated with membership: ${_membershipTier.name}');
        }
      } else {
        print('⚠️ [POST_PAGE] No Firebase user found');
      }
    } catch (e) {
      print('❌ [POST_PAGE] Error loading user: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = locator<ApiService>();
      final loadedPosts = await apiService.getPublicPosts();
      
      if (mounted) {
        setState(() {
          posts = loadedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading posts: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isNavBarVisible) {
        setState(() {
          _isNavBarVisible = false;
          BottomNavBarVisibilityNotification(false).dispatch(context);
        });
      }
    }
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isNavBarVisible) {
        setState(() {
          _isNavBarVisible = true;
          BottomNavBarVisibilityNotification(true).dispatch(context);
        });
      }
    }
  }

  void _onUnlockPost(int postIndex) {
    final isPremiumUser = _membershipTier != MembershipTier.free;
    
    if (isPremiumUser) {
      // Premium/Pro users can unlock everything
      setState(() {
        _unlockedPostIndices.add(postIndex);
      });
    } else {
      // Free users have limited unlocks
      if (_freeUnlocksUsed < _maxFreeUnlocks) {
        setState(() {
          _unlockedPostIndices.add(postIndex);
          _freeUnlocksUsed++;
        });
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post unlocked! ${_maxFreeUnlocks - _freeUnlocksUsed} free unlocks remaining today.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show upgrade prompt
        _showUpgradeDialog();
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text('Upgrade to Premium'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You\'ve used all 3 free unlocks for today.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Premium Benefits',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildBenefit('Unlock all posts anytime'),
                    _buildBenefit('Unlimited AI-powered matching'),
                    _buildBenefit('No ads'),
                    _buildBenefit('Priority support'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscribePage(),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Refresh user data after subscription
                    _loadCurrentUser();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF992121),
              ),
              icon: const Icon(Icons.workspace_premium, color: Colors.white),
              label: const Text('Upgrade Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLikeToggle(Post post) async {
    print('❤️ [POST_PAGE] Like toggle for post: ${post.postId}');
    print('   - Current isLiked: ${post.isLiked}');
    print('   - Current likes: ${post.likes}');
    
    try {
      final apiService = locator<ApiService>();
      print('🔄 [POST_PAGE] Calling likePost API...');
      final newLikeStatus = await apiService.likePost(post.postId!);
      print('✅ [POST_PAGE] API returned new like status: $newLikeStatus');
      
      // Update post in local list
      if (mounted) {
        setState(() {
          final index = posts.indexWhere((p) => p.postId == post.postId);
          if (index != -1) {
            final oldPost = posts[index];
            posts[index] = posts[index].copyWith(
              isLiked: newLikeStatus,
              likes: posts[index].likes + (newLikeStatus ? 1 : -1),
            );
            print('✅ [POST_PAGE] Updated post in list at index $index');
            print('   - New isLiked: ${posts[index].isLiked}');
            print('   - New likes: ${posts[index].likes}');
          } else {
            print('⚠️ [POST_PAGE] Post not found in list for update');
          }
        });
        
        // Refresh user data to sync liked posts array
        _loadCurrentUser();
      }
    } catch (e) {
      print('❌ [POST_PAGE] Error toggling like: $e');
      print('   Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> _handleFavoriteToggle(Post post) async {
    print('⭐ [POST_PAGE] Favorite toggle for post: ${post.postId}');
    print('   - Current isFavorited: ${post.isFavorited}');
    print('   - Current favorites: ${post.favorites}');
    
    try {
      final apiService = locator<ApiService>();
      print('🔄 [POST_PAGE] Calling toggleFavoritePost API...');
      final newFavoriteStatus = await apiService.toggleFavoritePost(post.postId!);
      print('✅ [POST_PAGE] API returned new favorite status: $newFavoriteStatus');
      
      // Update post in local list
      if (mounted) {
        setState(() {
          final index = posts.indexWhere((p) => p.postId == post.postId);
          if (index != -1) {
            posts[index] = posts[index].copyWith(
              isFavorited: newFavoriteStatus,
              favorites: posts[index].favorites + (newFavoriteStatus ? 1 : -1),
            );
            print('✅ [POST_PAGE] Updated post in list at index $index');
            print('   - New isFavorited: ${posts[index].isFavorited}');
            print('   - New favorites: ${posts[index].favorites}');
          } else {
            print('⚠️ [POST_PAGE] Post not found in list for update');
          }
        });
        
        // Refresh user data to sync favorited posts array
        _loadCurrentUser();
      }
    } catch (e) {
      print('❌ [POST_PAGE] Error toggling favorite: $e');
      print('   Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  Future<void> _handleDeletePost(Post post, int index) async {
    try {
      final apiService = locator<ApiService>();
      await apiService.deletePost(post.postId!);
      
      if (mounted) {
        setState(() {
          posts.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      print('❌ Error deleting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isPremiumUser = _membershipTier != MembershipTier.free;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          if (!isPremiumUser)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Free: ${_maxFreeUnlocks - _freeUnlocksUsed}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscribePage(),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadCurrentUser();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Upgrade',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        child: StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: posts.asMap().entries.map((entry) {
            final index = entry.key;
            final post = entry.value;
            final isUnlocked = isPremiumUser || _unlockedPostIndices.contains(index);
            
            return StaggeredGridTile.count(
              crossAxisCellCount: post.crossAxisCellCount.toInt(),
              mainAxisCellCount: post.mainAxisCellCount,
              child: PostCard(
                post: post, 
                isMember: isPremiumUser,
                isUnlocked: isUnlocked,
                onUnlock: () => _onUnlockPost(index),
                onLikeToggle: () => _handleLikeToggle(post),
                onFavoriteToggle: () => _handleFavoriteToggle(post),
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreatePostPage(),
              fullscreenDialog: true,
            ),
          );

          if (result == true && mounted) {
            // Reload posts after successful creation
            _loadPosts();
          }
        },
        backgroundColor: const Color(0xFF992121),
        child: const Icon(Icons.add, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

