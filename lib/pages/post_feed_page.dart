import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/pages/create_post_page.dart';
import 'package:flutter_app/pages/post_detail_page.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/services/membership_service.dart';
import 'package:flutter_app/widgets/bottom_nav_bar_visibility_notification.dart';

class PostFeedPage extends StatefulWidget {
  const PostFeedPage({super.key});

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {
  final _scrollController = ScrollController();
  final _membershipNotifier = MembershipChangeNotifier();
  
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isNavBarVisible = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _membershipNotifier.addListener(_onMembershipChanged);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _membershipNotifier.removeListener(_onMembershipChanged);
    _membershipNotifier.dispose();
    super.dispose();
  }

  void _onMembershipChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _membershipNotifier.refresh();
      final apiService = locator<ApiService>();
      final posts = await apiService.getPublicPosts();
      
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _scrollListener() {
    const threshold = 100.0;
    final isScrollingDown = _scrollController.position.userScrollDirection == ScrollDirection.reverse;
    final shouldHide = isScrollingDown && _scrollController.offset > threshold;

    if (_isNavBarVisible == shouldHide) {
      setState(() => _isNavBarVisible = !shouldHide);
      BottomNavBarVisibilityNotification(isVisible: _isNavBarVisible).dispatch(context);
    }
  }

  Future<void> _onPostTap(Post post) async {
    // 检查查看限制
    final canView = await MembershipService.consumeView();
    
    if (!canView) {
      _showMembershipDialog();
      return;
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(post: post),
        ),
      );
      // 刷新以更新点赞等状态
      _loadData();
    }
  }

  void _showMembershipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Daily Limit Reached',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'You\'ve reached your daily limit of 10 post views.\n\n'
          'Upgrade to membership for unlimited access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUpgradeDialog();
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upgrade to Member',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Member Benefits:'),
            const SizedBox(height: 12),
            _buildBenefit('Unlimited post views'),
            _buildBenefit('Unlimited matches'),
            _buildBenefit('Advanced AI matching'),
            _buildBenefit('Priority support'),
            const SizedBox(height: 16),
            const Text(
              'For demo purposes, membership is free!',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _membershipNotifier.setMemberStatus(true);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Welcome to membership! 🎉'),
                  ),
                );
              }
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _onCreatePost() async {
    final result = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );

    if (result != null) {
      _loadData(); // 刷新列表
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Feed',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        actions: [
          // 显示剩余查看次数
          if (!_membershipNotifier.isMember)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_membershipNotifier.remainingViews} left',
                  style: TextStyle(
                    color: _membershipNotifier.remainingViews < 3
                        ? Colors.red
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add_outlined,
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
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to share something',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: StaggeredGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: _posts.map((post) {
                              return StaggeredGridTile.count(
                                crossAxisCellCount: post.crossAxisCellCount,
                                mainAxisCellCount: post.mainAxisCellCount,
                                child: PostCard(
                                  post: post,
                                  isMember: _membershipNotifier.isMember,
                                  onTap: () => _onPostTap(post),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreatePost,
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}
