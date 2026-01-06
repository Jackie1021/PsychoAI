import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/profile_card.dart';
import 'package:flutter_app/models/profile_card_theme.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/services/profile_card_service.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/widgets/profile_card_preview.dart';

class ProfileCardEditorPage extends StatefulWidget {
  const ProfileCardEditorPage({super.key});

  @override
  State<ProfileCardEditorPage> createState() => _ProfileCardEditorPageState();
}

class _ProfileCardEditorPageState extends State<ProfileCardEditorPage>
    with SingleTickerProviderStateMixin {
  final ProfileCardService _service = ProfileCardService();
  final ApiService _apiService = locator<ApiService>();

  late TabController _tabController;
  ProfileCard? _originalCard;
  ProfileCard? _editedCard;
  ProfileCardCustomization _customization = const ProfileCardCustomization();
  UserData? _userData;
  List<Post> _userPosts = [];
  List<MatchRecord> _matchHistory = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not logged in');

      final profileCard = await _service.getProfileCard(userId);
      final userData = await _apiService.getUser(userId);
      final posts = await _apiService.getMyPosts(userId);

      // Load match history
      List<MatchRecord> matches = [];
      try {
        matches = await _apiService.getMatchHistory(userId: userId, limit: 10);
        print('📊 Loaded ${matches.length} match records');
      } catch (e) {
        print('⚠️ Could not load match history: $e');
      }

      if (profileCard == null) {
        final newCard = ProfileCard.fromUserData(userData);
        await _service.createProfileCard(userData);
        _originalCard = newCard;
        _editedCard = newCard;
      } else {
        _originalCard = profileCard;
        _editedCard = profileCard;
      }

      final customizationData = await _service.getCustomization(userId);
      if (customizationData != null) {
        _customization = customizationData;
      }

      // Sync profile card with latest user data
      await _service.syncProfileCardWithUserData(userId, userData);

      // Update match count if needed
      if (matches.isNotEmpty &&
          _editedCard!.matchesCount != matches.length) {
        await _service.updateMatchCount(userId, matches.length);
        _editedCard = _editedCard!.copyWith(matchesCount: matches.length);
      }

      // Reload the profile card to get updated statistics
      final updatedCard = await _service.getProfileCard(userId);
      if (updatedCard != null) {
        _originalCard = updatedCard;
        // Update the card with current actual counts for preview accuracy
        _editedCard = updatedCard.copyWith(
          postsCount: _userPosts.length,
          matchesCount: matches.length,
        );
      }

      setState(() {
        _userData = userData;
        _userPosts = posts;
        _matchHistory = matches;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading profile card: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_editedCard == null) return;

    setState(() => _isSaving = true);

    try {
      await _service.updateProfileCard(_editedCard!);
      await _service.saveCustomization(
        FirebaseAuth.instance.currentUser!.uid,
        _customization,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile card saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, _editedCard);
      }
    } catch (e) {
      print('❌ Error saving profile card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Edit Profile Card',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3E2A2A),
          ),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Content'),
            Tab(text: 'Theme'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContentTab(theme),
                _buildThemeTab(theme),
                _buildPreviewTab(theme),
              ],
            ),
    );
  }

  Widget _buildContentTab(ThemeData theme) {
    if (_editedCard == null || _userData == null) {
      return const Center(child: Text('No data'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Basic Info',
          icon: Icons.person_outline,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Show Bio',
              subtitle: _customization.showBio
                  ? (_editedCard!.bio.isEmpty
                      ? '✓ Show bio section (add bio in profile settings)'
                      : '✓ Display: "${_editedCard!.bio}"')
                  : '✗ Hide bio section from your profile card',
              value: _customization.showBio,
              onChanged: (val) {
                setState(() {
                  _customization = _customization.copyWith(showBio: val);
                });
              },
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'Show Traits',
              subtitle: _customization.showTraits
                  ? (_editedCard!.highlightedTraits.isEmpty
                      ? '✓ Show traits section (no traits selected)'
                      : '✓ Display ${_editedCard!.highlightedTraits.length} personality traits')
                  : '✗ Hide personality traits from your profile card',
              value: _customization.showTraits,
              onChanged: (val) {
                setState(() {
                  _customization = _customization.copyWith(showTraits: val);
                });
              },
            ),
            if (_customization.showTraits &&
                _editedCard!.highlightedTraits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _editedCard!.highlightedTraits.map((trait) {
                    return Chip(
                      label: Text(trait),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor,
                      ),
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          final newTraits =
                              List<String>.from(_editedCard!.highlightedTraits);
                          newTraits.remove(trait);
                          _editedCard = _editedCard!.copyWith(
                            highlightedTraits: newTraits,
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Statistics',
          icon: Icons.bar_chart_outlined,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Show Statistics',
              subtitle: _customization.showStats
                  ? '✓ Display post count, match count, and view count'
                  : '✗ Hide all statistics from your profile card',
              value: _customization.showStats,
              onChanged: (val) {
                setState(() {
                  _customization = _customization.copyWith(showStats: val);
                });
              },
            ),
            if (_customization.showStats && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPreview(
                        'Posts', _userPosts.length, theme),
                    _buildStatPreview(
                        'Matches', _matchHistory.length, theme),
                    _buildStatPreview('Views', _editedCard!.viewCount, theme),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Featured Content',
          icon: Icons.star_outline,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Show Featured Posts',
              subtitle: _customization.showPosts
                  ? (_userPosts.isEmpty
                      ? '✓ Show posts section (no posts yet)'
                      : '✓ Display featured posts from ${_userPosts.length} available')
                  : '✗ Hide featured posts from your profile card',
              value: _customization.showPosts,
              onChanged: (val) {
                setState(() {
                  _customization = _customization.copyWith(showPosts: val);
                });
              },
            ),
            if (_customization.showPosts && _userPosts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Select up to 3 posts to feature:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _userPosts.length,
                      itemBuilder: (context, index) {
                        final post = _userPosts[index];
                        final isSelected = _editedCard!.featuredPostIds
                            .contains(post.postId);
                        return _buildPostSelector(post, isSelected, theme);
                      },
                    ),
                  ),
                ],
              ),
            const Divider(height: 32),
            _buildSwitchTile(
              title: 'Show Match Records',
              subtitle: _customization.showMatches
                  ? (_matchHistory.isEmpty
                      ? '✓ Show match section (no matches yet)'
                      : '✓ Display ${_matchHistory.length} match records')
                  : '✗ Hide match history from your profile card',
              value: _customization.showMatches,
              onChanged: (val) {
                setState(() {
                  _customization = _customization.copyWith(showMatches: val);
                });
              },
            ),
            if (_customization.showMatches && _matchHistory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Select matches to display publicly (up to 3):',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._matchHistory.take(6).map((match) {
                    final isSelected =
                        _editedCard!.publicMatchIds.contains(match.id ?? '');
                    return _buildMatchSelector(match, isSelected, theme);
                  }),
                  if (_matchHistory.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Showing 6 of ${_matchHistory.length} matches',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Privacy',
          icon: Icons.lock_outline,
          theme: theme,
          children: [
            _buildSwitchTile(
              title: 'Allow Stranger Access',
              subtitle: _editedCard!.privacy.allowStrangerAccess
                  ? 'Anyone can view your card'
                  : 'Only matched users can view',
              value: _editedCard!.privacy.allowStrangerAccess,
              onChanged: (val) {
                setState(() {
                  final newPrivacy = ProfileCardPrivacySettings(
                    showTraits: _editedCard!.privacy.showTraits,
                    showPosts: _editedCard!.privacy.showPosts,
                    showMatches: _editedCard!.privacy.showMatches,
                    showStats: _editedCard!.privacy.showStats,
                    allowStrangerAccess: val,
                  );
                  _editedCard = _editedCard!.copyWith(privacy: newPrivacy);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Choose Your Theme',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3E2A2A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a theme that represents your personality',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: ProfileCardTheme.allThemes.length,
          itemBuilder: (context, index) {
            final themeOption = ProfileCardTheme.allThemes[index];
            final isSelected = _customization.theme.id == themeOption.id;
            return _buildThemeOption(themeOption, isSelected, theme);
          },
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Layout Options',
          icon: Icons.view_compact_outlined,
          theme: theme,
          children: [
            ...ProfileCardLayout.values.map((layout) {
              return RadioListTile<ProfileCardLayout>(
                value: layout,
                groupValue: _customization.theme.layout,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _customization = _customization.copyWith(
                        theme: ProfileCardTheme(
                          id: _customization.theme.id,
                          name: _customization.theme.name,
                          style: _customization.theme.style,
                          gradientColors: _customization.theme.gradientColors,
                          backgroundImageUrl:
                              _customization.theme.backgroundImageUrl,
                          layout: val,
                        ),
                      );
                    });
                  }
                },
                title: Text(_getLayoutName(layout)),
                subtitle: Text(_getLayoutDescription(layout)),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewTab(ThemeData theme) {
    if (_editedCard == null) {
      return const Center(child: Text('No data'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Preview Mode',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  _tabController.animateTo(0);
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                    maxHeight: 700,
                  ),
                  child: ProfileCardPreview(
                    profileCard: _editedCard!,
                    customization: _customization,
                    posts: _userPosts.take(3).toList(),
                    matches: _matchHistory,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3E2A2A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildStatPreview(String label, int value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPostSelector(Post post, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (post.postId == null) return;
          
          final featured = List<String>.from(_editedCard!.featuredPostIds);
          if (isSelected) {
            featured.remove(post.postId);
          } else {
            if (featured.length < 3) {
              featured.add(post.postId!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('You can feature up to 3 posts only')),
              );
              return;
            }
          }
          _editedCard = _editedCard!.copyWith(featuredPostIds: featured);
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (post.media.isNotEmpty && post.media.first.startsWith('http'))
                Image.network(post.media.first, fit: BoxFit.cover)
              else
                Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              if (isSelected)
                Container(
                  color: theme.primaryColor.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      color: theme.primaryColor,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchSelector(
      MatchRecord match, bool isSelected, ThemeData theme) {
    final scorePercentage = (match.compatibilityScore * 100).round();

    return GestureDetector(
      onTap: () {
        setState(() {
          final publicMatches = List<String>.from(_editedCard!.publicMatchIds);
          final matchId = match.id ?? '';
          if (isSelected) {
            publicMatches.remove(matchId);
          } else {
            if (publicMatches.length < 3) {
              publicMatches.add(matchId);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('You can display up to 3 matches only')),
              );
              return;
            }
          }
          _editedCard = _editedCard!.copyWith(publicMatchIds: publicMatches);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              backgroundImage: match.matchedUserAvatar.isNotEmpty
                  ? NetworkImage(match.matchedUserAvatar)
                  : null,
              child: match.matchedUserAvatar.isEmpty
                  ? Icon(Icons.person, color: theme.primaryColor, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.matchedUsername,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.primaryColor
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(match.compatibilityScore)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$scorePercentage%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getScoreColor(match.compatibilityScore),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.matchSummary,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Selection indicator
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? theme.primaryColor : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildThemeOption(
      ProfileCardTheme themeOption, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _customization = _customization.copyWith(theme: themeOption);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (themeOption.gradientColors.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: themeOption.gradientColors
                          .map((c) => _hexToColor(c))
                          .toList(),
                    ),
                  ),
                )
              else
                Container(color: Colors.grey[200]),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeOption.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  String _getLayoutName(ProfileCardLayout layout) {
    switch (layout) {
      case ProfileCardLayout.standard:
        return 'Standard';
      case ProfileCardLayout.compact:
        return 'Compact';
      case ProfileCardLayout.expanded:
        return 'Expanded';
      case ProfileCardLayout.magazine:
        return 'Magazine';
    }
  }

  String _getLayoutDescription(ProfileCardLayout layout) {
    switch (layout) {
      case ProfileCardLayout.standard:
        return 'Classic card layout with balanced spacing';
      case ProfileCardLayout.compact:
        return 'Minimalist design with essential info';
      case ProfileCardLayout.expanded:
        return 'Detailed layout with maximum content';
      case ProfileCardLayout.magazine:
        return 'Creative layout with visual emphasis';
    }
  }
}
