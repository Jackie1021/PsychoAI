import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/models/profile_card.dart';
import 'package:flutter_app/models/profile_card_theme.dart';
import 'package:flutter_app/models/post.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/widgets/profile_card_match_section.dart';

class ProfileCardPreview extends StatelessWidget {
  final ProfileCard profileCard;
  final ProfileCardCustomization customization;
  final List<Post> posts;
  final List<MatchRecord> matches;
  final MatchRecord? topMatch;
  final bool isInteractive;

  const ProfileCardPreview({
    super.key,
    required this.profileCard,
    required this.customization,
    this.posts = const [],
    this.matches = const [],
    this.topMatch,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 800),
      child: SingleChildScrollView(
        child: _buildCardByLayout(context),
      ),
    );
  }

  Widget _buildCardByLayout(BuildContext context) {
    switch (customization.theme.layout) {
      case ProfileCardLayout.compact:
        return _buildCompactCard(context);
      case ProfileCardLayout.expanded:
        return _buildExpandedCard(context);
      case ProfileCardLayout.magazine:
        return _buildMagazineCard(context);
      case ProfileCardLayout.standard:
      default:
        return _buildStandardCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            _buildBackground(),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.95),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customization.showAvatar) _buildAvatar(theme),
                    if (customization.showAvatar) const SizedBox(height: 20),
                    _buildUsername(theme),
                    if (topMatch != null) ...[
                      const SizedBox(height: 12),
                      _buildTopMatchHighlight(theme),
                    ],
                    if (customization.showBio && profileCard.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildBio(theme),
                    ],
                    if (customization.showTraits &&
                        profileCard.highlightedTraits.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildTraits(theme),
                    ],
                    if (customization.showStats) ...[
                      const SizedBox(height: 24),
                      _buildStats(theme),
                    ],
                    if (customization.showPosts &&
                        posts.isNotEmpty &&
                        profileCard.featuredPostIds.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildFeaturedPosts(theme),
                    ],
                    if (customization.showMatches && matches.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildMatchesSection(theme),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            _buildBackground(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.9),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (customization.showAvatar) ...[
                    _buildCompactAvatar(theme),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUsername(theme),
                        if (topMatch != null) ...[
                          const SizedBox(height: 6),
                          _buildTopMatchHighlight(theme),
                        ],
                        if (customization.showBio &&
                            profileCard.bio.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            profileCard.bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (customization.showStats) ...[
                          const SizedBox(height: 12),
                          _buildCompactStats(theme),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              _buildBackground(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.95),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customization.showAvatar) _buildAvatar(theme),
                    if (customization.showAvatar) const SizedBox(height: 20),
                    _buildUsername(theme),
                    if (topMatch != null) ...[
                      const SizedBox(height: 12),
                      _buildTopMatchHighlight(theme),
                    ],
                    if (customization.showBio && profileCard.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildBio(theme),
                    ],
                    if (customization.showTraits &&
                        profileCard.highlightedTraits.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildTraits(theme),
                    ],
                    if (customization.showStats) ...[
                      const SizedBox(height: 24),
                      _buildStats(theme),
                    ],
                    if (customization.showPosts && posts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildExpandedPosts(theme),
                    ],
                    if (customization.showMatches && matches.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildMatchesSection(theme),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagazineCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            _buildBackground(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: customization.theme.gradientColors
                          .map((c) => _hexToColor(c))
                          .toList(),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: customization.showAvatar
                              ? _buildMagazineAvatar(theme)
                              : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 600),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -32, 0),
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUsername(theme),
                        if (topMatch != null) ...[
                          const SizedBox(height: 12),
                          _buildTopMatchHighlight(theme),
                        ],
                        if (customization.showBio &&
                            profileCard.bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildBio(theme),
                        ],
                        if (customization.showTraits &&
                            profileCard.highlightedTraits.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildTraits(theme),
                        ],
                        if (customization.showStats) ...[
                          const SizedBox(height: 24),
                          _buildStats(theme),
                        ],
                        if (customization.showMatches && matches.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildMatchesSection(theme),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (customization.customBackgroundUrl != null) {
      return Image.network(
        customization.customBackgroundUrl!,
        fit: BoxFit.cover,
      );
    }

    if (customization.theme.gradientColors.isEmpty) {
      return Container(color: Colors.white);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: customization.theme.gradientColors
              .map((c) => _hexToColor(c))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            backgroundImage: profileCard.avatarUrl != null
                ? NetworkImage(profileCard.avatarUrl!)
                : null,
            child: profileCard.avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: theme.primaryColor,
                  )
                : null,
          ),
        ),
        if (profileCard.membershipTier != MembershipTier.free)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[700]!, Colors.amber[400]!],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 18,
            ),
          ),
      ],
    );
  }

  Widget _buildCompactAvatar(ThemeData theme) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          backgroundImage: profileCard.avatarUrl != null
              ? NetworkImage(profileCard.avatarUrl!)
              : null,
          child: profileCard.avatarUrl == null
              ? Icon(
                  Icons.person,
                  size: 35,
                  color: theme.primaryColor,
                )
              : null,
        ),
        if (profileCard.membershipTier != MembershipTier.free)
          Container(
            padding: const EdgeInsets.all(4),
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
              size: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildMagazineAvatar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 55,
        backgroundColor: Colors.white,
        backgroundImage: profileCard.avatarUrl != null
            ? NetworkImage(profileCard.avatarUrl!)
            : null,
        child: profileCard.avatarUrl == null
            ? Icon(
                Icons.person,
                size: 50,
                color: theme.primaryColor,
              )
            : null,
      ),
    );
  }

  Widget _buildUsername(ThemeData theme) {
    return Text(
      profileCard.username,
      style: GoogleFonts.cormorantGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3E2A2A),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTopMatchHighlight(ThemeData theme) {
    if (topMatch == null) return const SizedBox.shrink();

    final m = topMatch!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                m.matchedUserAvatar.isNotEmpty ? NetworkImage(m.matchedUserAvatar) : null,
            backgroundColor: theme.primaryColor.withOpacity(0.08),
            child: m.matchedUserAvatar.isEmpty ? Icon(Icons.person, color: theme.primaryColor) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.matchedUsername,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  m.matchSummary,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(m.compatibilityScore).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getScoreColor(m.compatibilityScore).withOpacity(0.3)),
            ),
            child: Text(
              '${(m.compatibilityScore * 100).toInt()}%',
              style: TextStyle(
                color: _getScoreColor(m.compatibilityScore),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        profileCard.bio,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTraits(ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: profileCard.highlightedTraits.map((trait) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.15),
                theme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            trait,
            style: TextStyle(
              fontSize: 13,
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('Posts', profileCard.postsCount, theme),
        _buildStatDivider(),
        _buildStat('Matches', profileCard.matchesCount, theme),
        _buildStatDivider(),
        _buildStat('Views', profileCard.viewCount, theme),
      ],
    );
  }

  Widget _buildCompactStats(ThemeData theme) {
    return Row(
      children: [
        _buildCompactStat(Icons.edit_note, profileCard.postsCount, theme),
        const SizedBox(width: 16),
        _buildCompactStat(Icons.favorite_border, profileCard.matchesCount, theme),
        const SizedBox(width: 16),
        _buildCompactStat(Icons.visibility, profileCard.viewCount, theme),
      ],
    );
  }

  Widget _buildStat(String label, int value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(IconData icon, int value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildFeaturedPosts(ThemeData theme) {
    final featuredPosts = posts
        .where((p) => p.postId != null && profileCard.featuredPostIds.contains(p.postId!))
        .take(3)
        .toList();

    if (featuredPosts.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Posts',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3E2A2A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: featuredPosts.map((post) {
            return Expanded(
              child: Container(
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (post.media?.isNotEmpty == true) &&
                          (post.media!.first.startsWith('http'))
                      ? Image.network(post.media!.first, fit: BoxFit.cover)
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              post.content ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpandedPosts(ThemeData theme) {
    final displayPosts = posts.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Posts',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3E2A2A),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: displayPosts.length,
          itemBuilder: (context, index) {
            final post = displayPosts[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: post.media.isNotEmpty &&
                        post.media.first.startsWith('http')
                    ? Image.network(post.media.first, fit: BoxFit.cover)
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            post.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMatchesSection(ThemeData theme) {
    // Get matches that are marked as public
    final publicMatches = matches
        .where((m) => m.id != null && profileCard.publicMatchIds.contains(m.id!))
        .toList();

    return ProfileCardMatchSection(
      matches: publicMatches,
      maxDisplay: 3,
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return const Color(0xFF4CAF50);
    if (score >= 0.6) return const Color(0xFF2196F3);
    if (score >= 0.4) return const Color(0xFFFF9800);
    return Colors.grey;
  }
}
