import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/models/match_analysis.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/match_report.dart';
import 'package:flutter_app/pages/match_analysis_page.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';

class MatchHistoryPage extends StatefulWidget {
  final DateRange? dateRange;

  const MatchHistoryPage({super.key, this.dateRange});

  @override
  State<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends State<MatchHistoryPage> {
  List<MatchRecord> _records = [];
  bool _isLoading = true;
  MatchAction? _filterAction;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      final apiService = locator<ApiService>();
      final records = await apiService.getMatchHistory(
        userId: userId,
        dateRange: widget.dateRange,
        filterAction: _filterAction,
      );

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E0DE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Match History',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<MatchAction?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (action) {
              setState(() => _filterAction = action);
              _loadHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              const PopupMenuItem(
                  value: MatchAction.chatted, child: Text('已聊天')),
              const PopupMenuItem(
                  value: MatchAction.skipped, child: Text('已跳过')),
              const PopupMenuItem(
                  value: MatchAction.none, child: Text('未操作')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无匹配记录',
                        style: GoogleFonts.notoSerifSc(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _records.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return MatchHistoryItem(
                      record: record,
                      onTap: () => _viewDetail(record),
                    );
                  },
                ),
    );
  }

  void _viewDetail(MatchRecord record) {
    // Reconstruct MatchAnalysis from MatchRecord
    final analysis = MatchAnalysis(
      id: record.id,
      userA: UserData(uid: record.userId, username: 'You'),
      userB: UserData(
        uid: record.matchedUserId,
        username: record.matchedUsername,
        avatarUrl: record.matchedUserAvatar,
      ),
      totalScore: record.compatibilityScore,
      matchSummary: record.matchSummary,
      similarFeatures: record.featureScores,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchAnalysisPage(analysis: analysis),
      ),
    );
  }
}

class MatchHistoryItem extends StatelessWidget {
  final MatchRecord record;
  final VoidCallback onTap;

  const MatchHistoryItem({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF992121).withOpacity(0.1),
                backgroundImage: record.matchedUserAvatar.isNotEmpty
                    ? NetworkImage(record.matchedUserAvatar)
                    : null,
                child: record.matchedUserAvatar.isEmpty
                    ? Text(
                        record.matchedUsername[0].toUpperCase(),
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF992121),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.matchedUsername,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActionBadge(action: record.action),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.matchSummary,
                      style: GoogleFonts.notoSerifSc(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Color(0xFF992121),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(record.compatibilityScore * 100).toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF992121),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(record.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

class _ActionBadge extends StatelessWidget {
  final MatchAction action;

  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (action) {
      case MatchAction.chatted:
        color = Colors.green;
        label = '已聊天';
        icon = Icons.chat;
        break;
      case MatchAction.skipped:
        color = Colors.grey;
        label = '已跳过';
        icon = Icons.skip_next;
        break;
      case MatchAction.none:
        color = Colors.orange;
        label = '未操作';
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
