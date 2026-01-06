import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';

class EditPostPage extends StatefulWidget {
  final Post post;

  const EditPostPage({super.key, required this.post});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController _textController;
  late bool _isPublic;
  bool _isUpdating = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.post.content);
    _isPublic = widget.post.isPublic;
    _textController.addListener(() {
      if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (!_hasChanges && _isPublic == widget.post.isPublic) {
      Navigator.pop(context);
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final apiService = locator<ApiService>();
      await apiService.updatePost(
        widget.post.postId!,
        text: text != widget.post.content ? text : null,
        isPublic: _isPublic != widget.post.isPublic ? _isPublic : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Widget _buildMediaPreview() {
    if (widget.post.media.isEmpty) {
      return const SizedBox.shrink();
    }

    final mediaUrl = widget.post.media.first;
    Widget preview;

    if (widget.post.mediaType == MediaType.image) {
      preview = mediaUrl.startsWith('http')
          ? Image.network(mediaUrl, fit: BoxFit.cover, width: double.infinity)
          : Image.file(File(mediaUrl),
              fit: BoxFit.cover, width: double.infinity);
    } else if (widget.post.mediaType == MediaType.video) {
      preview = Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.play_circle_outline, size: 60),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: preview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Post',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _updatePost,
                child: Text(
                  'Save',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF992121),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media preview (read-only)
                    _buildMediaPreview(),
                    if (widget.post.media.isNotEmpty) const SizedBox(height: 16),

                    // Note about media
                    if (widget.post.media.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Media cannot be changed. You can only edit text and visibility.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Text editor
                    TextField(
                      controller: _textController,
                      maxLines: 10,
                      autofocus: true,
                      style: GoogleFonts.notoSerifSc(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Edit your content...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF992121),
                            width: 2,
                          ),
                        ),
                        hintStyle: GoogleFonts.notoSerifSc(
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Visibility toggle
            SwitchListTile(
              title: Text(
                'Make post public',
                style: GoogleFonts.cormorantGaramond(fontSize: 16),
              ),
              subtitle: Text(
                _isPublic
                    ? 'Visible to everyone in the community.'
                    : 'Only visible to you in your sanctuary.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              value: _isPublic,
              onChanged: (bool value) {
                setState(() {
                  _isPublic = value;
                  _hasChanges = true;
                });
              },
              activeColor: const Color(0xFF992121),
            ),
          ],
        ),
      ),
    );
  }
}
