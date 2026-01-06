import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/models/match_record.dart';

class ProfileCardMatchSection extends StatelessWidget {
  final List<MatchRecord> matches;
  final int maxDisplay;
  final VoidCallback? onSeeMore;

  const ProfileCardMatchSection({
    super.key,
    required this.matches,
    this.maxDisplay = 3,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayMatches = matches.take(maxDisplay).toList();

    if (displayMatches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.favorite_border,
              size: 32,
              color: theme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No public matches yet',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Match History',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E2A2A),
              ),
            ),
            if (matches.length > maxDisplay && onSeeMore != null)
              TextButton(
                onPressed: onSeeMore,
                child: Text(
                  'See All (${matches.length})',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayMatches.map((match) => _buildMatchCard(match, theme)),
      ],
    );
  }

  Widget _buildMatchCard(MatchRecord match, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Match Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                backgroundImage: match.matchedUserAvatar.isNotEmpty
                    ? NetworkImage(match.matchedUserAvatar)
                    : null,
                child: match.matchedUserAvatar.isEmpty
                    ? Icon(Icons.person, color: theme.primaryColor)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(match.compatibilityScore),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Match Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.matchedUsername,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  match.matchSummary,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScoreBadge(match.compatibilityScore, theme),
                    const SizedBox(width: 12),
                    _buildActionBadge(match.action, theme),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(double score, ThemeData theme) {
    final percentage = (score * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getScoreColor(score).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart,
            size: 14,
            color: _getScoreColor(score),
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getScoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBadge(MatchAction action, ThemeData theme) {
    IconData icon;
    Color color;
    String label;

    switch (action) {
      case MatchAction.chatted:
        icon = Icons.chat_bubble;
        color = Colors.green;
        label = 'Chatted';
        break;
      case MatchAction.skipped:
        icon = Icons.close;
        color = Colors.orange;
        label = 'Skipped';
        break;
      case MatchAction.none:
        icon = Icons.schedule;
        color = Colors.grey;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.grey;
  }
}
