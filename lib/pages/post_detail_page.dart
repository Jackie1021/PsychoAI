import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/comment.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/widgets/report_dialog.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  // --- State Variables ---
  late bool _isLiked;
  late int _likeCount;
  late int _initialCommentCount;
  String? get _postId => widget.post.postId;
  final TextEditingController _commentController = TextEditingController();
  Stream<List<PostComment>>? _commentsStream;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    // Initialize state from the widget's data
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _initialCommentCount = widget.post.comments;
    final postId = _postId;
    if (postId != null && postId.isNotEmpty) {
      _commentsStream = locator<ApiService>().streamComments(postId);
    }
    _commentController.addListener(_handleCommentInputChange);
  }

  @override
  void dispose() {
    _commentController.removeListener(_handleCommentInputChange);
    _commentController.dispose();
    super.dispose();
  }

  void _handleCommentInputChange() {
    setState(() {});
  }

  // --- Interaction Handlers ---
  Future<void> _toggleLike() async {
    final postId = _postId;
    if (postId == null || postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to like this post right now.')),
      );
      return;
    }

    final previousState = _isLiked;
    final previousCount = _likeCount;
    final apiService = locator<ApiService>();

    // Optimistic update
    setState(() {
      _isLiked = !previousState;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      final liked = await apiService.likePost(postId);
      if (!mounted) return;
      
      // Update with actual state from server
      setState(() {
        _isLiked = liked;
        // Recalculate based on actual server response
        if (liked != previousState) {
          _likeCount = previousCount + (liked ? 1 : -1);
        } else {
          _likeCount = previousCount;
        }
      });
    } catch (e) {
      if (!mounted) return;
      // Rollback on error
      setState(() {
        _isLiked = previousState;
        _likeCount = previousCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update like. Please try again.')),
      );
    }
  }

  Future<void> _addComment() async {
    final postId = _postId;
    if (postId == null || postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Comments are unavailable for this post.')),
      );
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty || _isPostingComment) {
      return;
    }

    setState(() {
      _isPostingComment = true;
    });

    try {
      await locator<ApiService>().addComment(postId: postId, text: text);
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final commentsStream = _commentsStream;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.author,
            style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                showReportDialog(
                  context,
                  targetType: 'post',
                  targetId: widget.post.postId ?? 'unknown',
                  targetName: widget.post.content.substring(
                      0,
                      widget.post.content.length > 30
                          ? 30
                          : widget.post.content.length),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: commentsStream == null
          ? _buildBody(
              comments: const [],
              isLoading: false,
              commentCount: _initialCommentCount,
            )
          : StreamBuilder<List<PostComment>>(
              stream: commentsStream,
              builder: (context, snapshot) {
                final comments = snapshot.data ?? const [];
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                        comments.isEmpty;
                final commentCount =
                    snapshot.hasData ? comments.length : _initialCommentCount;

                return _buildBody(
                  comments: comments,
                  isLoading: isLoading,
                  commentCount: commentCount,
                );
              },
            ),
      bottomSheet: _buildCommentInputBar(),
    );
  }

  Widget _buildBody({
    required List<PostComment> comments,
    required bool isLoading,
    required int commentCount,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          16.0, 16.0, 16.0, 100.0), // reserve input bar space
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorInfo(),
          const SizedBox(height: 24),
          _buildPostContent(),
          const SizedBox(height: 24),
          _buildLikesAndCommentsStats(commentCount),
          const Divider(height: 48),
          _buildCommentSection(comments, isLoading),
        ],
      ),
    );
  }

  // --- UI Builder Widgets ---
  Widget _buildAuthorInfo() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: widget.post.authorImageUrl.isNotEmpty
              ? NetworkImage(widget.post.authorImageUrl)
              : null,
          child: widget.post.authorImageUrl.isNotEmpty
              ? null
              : Text(
                  widget.post.author.isNotEmpty
                      ? widget.post.author[0].toUpperCase()
                      : '?',
                ),
          radius: 20,
        ),
        const SizedBox(width: 12),
        Text(widget.post.author,
            style: GoogleFonts.cormorantGaramond(
                fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPostContent() {
    // TODO: Add video player support for video posts on this page.
    final bool isImagePost = widget.post.media.isNotEmpty &&
        widget.post.mediaType == MediaType.image;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isImagePost)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.post.media.first.startsWith('http')
                ? Image.network(widget.post.media.first)
                : Image.file(File(widget.post.media.first)),
          ),
        const SizedBox(height: 16),
        Text(widget.post.content,
            style: GoogleFonts.notoSerifSc(fontSize: 16, height: 1.5)),
      ],
    );
  }

  Widget _buildLikesAndCommentsStats(int commentCount) {
    final likedColor = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? likedColor : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text('$_likeCount likes',
                    style: TextStyle(
                        color: _isLiked ? likedColor : Colors.grey[600])),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 4),
            Text('$commentCount comments',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentSection(List<PostComment> comments, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (isLoading && comments.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (comments.isEmpty)
          Text('Be the first to comment!',
              style: GoogleFonts.notoSerifSc(color: Colors.grey[600]))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: comment.authorAvatarUrl.isNotEmpty
                          ? NetworkImage(comment.authorAvatarUrl)
                          : null,
                      radius: 16,
                      child: comment.authorAvatarUrl.isEmpty
                          ? Text(comment.authorName.isNotEmpty
                              ? comment.authorName[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.authorName,
                              style: GoogleFonts.cormorantGaramond(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(comment.text,
                              style: GoogleFonts.notoSerifSc(height: 1.4)),
                          if (comment.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _formatTimestamp(comment.createdAt!),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) =>
                const Divider(thickness: 0.5, height: 24),
          ),
      ],
    );
  }

  Widget _buildCommentInputBar() {
    return Material(
      elevation: 8,
      child: Container(
        padding: EdgeInsets.only(
            left: 16,
            right: 8,
            top: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: _isPostingComment
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send,
                      color: _canSubmitComment
                          ? Theme.of(context).primaryColor
                          : Colors.grey[400]),
              onPressed: _canSubmitComment ? _addComment : null,
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmitComment =>
      !_isPostingComment && _commentController.text.trim().isNotEmpty;

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return '${timestamp.year.toString().padLeft(4, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    }
  }
}
