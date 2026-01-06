import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/pages/post_detail_page.dart';
import 'package:flutter_app/pages/profile_card_page.dart';
import 'package:flutter_app/widgets/report_dialog.dart';

/// 统一的帖子卡片组件 - 保持原有的瀑布流UI风格
/// Unified post card component - maintains original waterfall UI style
class PostCard extends StatefulWidget {
  final Post post;
  final bool isMember;
  final bool isUnlocked;
  final bool showOwnerOptions; // 是否显示作者专属选项（编辑、删除）
  final VoidCallback? onUnlock;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.isMember = false,
    this.isUnlocked = true,
    this.showOwnerOptions = false,
    this.onUnlock,
    this.onLikeToggle,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  late bool _isFavorited;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  String? get _firstMediaUrl =>
      widget.post.media.isNotEmpty ? widget.post.media.first : null;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _isFavorited = widget.post.isFavorited;

    if (widget.post.mediaType == MediaType.video && _firstMediaUrl != null) {
      _initializeVideoPlayer();
    }
  }

  void _initializeVideoPlayer() {
    final mediaUrl = _firstMediaUrl!;
    if (mediaUrl.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
    } else {
      _videoController = VideoPlayerController.file(File(mediaUrl));
    }

    _videoController!
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isVideoInitialized = true);
        }
      })
      ..setLooping(true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleLike() {
    if (!widget.isUnlocked) return;
    
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    
    widget.onLikeToggle?.call();
  }

  void _toggleFavorite() {
    if (!widget.isUnlocked) return;
    
    setState(() {
      _isFavorited = !_isFavorited;
    });
    
    widget.onFavoriteToggle?.call();
  }

  void _navigateToDetail() {
    if (!widget.isUnlocked) return;
    
    _videoController?.pause();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailPage(post: widget.post),
      ),
    );
  }

  void _navigateToProfile() {
    if (!widget.isUnlocked) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileCardPage(userId: widget.post.userId),
      ),
    );
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_isVideoInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.showOwnerOptions) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit?.call();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(widget.post.isPublic ? 'Make Private' : 'Make Public'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 实现可见性切换
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report Post'),
                onTap: () {
                  Navigator.pop(context);
                  showReportDialog(
                    context,
                    targetType: 'post',
                    targetId: widget.post.postId ?? 'unknown',
                    targetName: widget.post.content.substring(
                      0,
                      widget.post.content.length > 30 ? 30 : widget.post.content.length,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaWidget() {
    if (_firstMediaUrl == null) {
      return const SizedBox.shrink();
    }

    switch (widget.post.mediaType) {
      case MediaType.image:
        final isFile = !_firstMediaUrl!.startsWith('http');
        return isFile
            ? Image.file(
                File(_firstMediaUrl!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Image.network(
                _firstMediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  );
                },
              );
      case MediaType.video:
        if (_videoController != null && _isVideoInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case MediaType.text:
      case null:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onLongPress: widget.isUnlocked ? _showOptionsMenu : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBFA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Media background
              _buildMediaWidget(),
              
              // Video play/pause button
              if (widget.post.mediaType == MediaType.video && _isVideoInitialized)
                Center(
                  child: IconButton(
                    icon: Icon(
                      _videoController?.value.isPlaying ?? false
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white.withOpacity(0.7),
                      size: 48,
                    ),
                    onPressed: widget.isUnlocked ? _toggleVideoPlayback : null,
                  ),
                ),
              
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(_firstMediaUrl != null ? 0.6 : 0.2),
                        Colors.transparent,
                        Colors.black.withOpacity(0.8)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Post content
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.isUnlocked ? _navigateToDetail : null,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.4,
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    
                    // Author info and actions
                    Row(
                      children: [
                        // Author avatar and name
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.isUnlocked ? _navigateToProfile : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  backgroundImage: widget.post.authorImageUrl.isNotEmpty
                                      ? NetworkImage(widget.post.authorImageUrl)
                                      : null,
                                  backgroundColor: const Color(0xFF992121),
                                  radius: 10,
                                  child: widget.post.authorImageUrl.isEmpty
                                      ? Text(
                                          widget.post.author.isNotEmpty
                                              ? widget.post.author[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    widget.post.author,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Favorite button
                        GestureDetector(
                          onTap: widget.isUnlocked ? _toggleFavorite : null,
                          child: Icon(
                            _isFavorited ? Icons.star : Icons.star_border,
                            color: _isFavorited ? Colors.amber : Colors.white,
                            size: 16,
                          ),
                        ),
                        
                        const SizedBox(width: 6),
                        
                        // Like button
                        GestureDetector(
                          onTap: widget.isUnlocked ? _toggleLike : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? Colors.red : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _likeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Comment button
                        GestureDetector(
                          onTap: widget.isUnlocked ? _navigateToDetail : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.comment_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.post.comments.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // More options button
                        if (widget.isUnlocked)
                          GestureDetector(
                            onTap: _showOptionsMenu,
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Locked overlay
              if (!widget.isUnlocked)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.7)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.4, 1.0],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, color: Colors.white, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              widget.isMember ? 'Tap to unlock' : 'Unlock to view',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: widget.onUnlock,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF992121),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                widget.isMember ? 'Unlock' : 'Free Unlock',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
