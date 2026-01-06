import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/models/match_record.dart';
import 'package:flutter_app/models/chat_history_summary.dart';
import 'package:flutter_app/models/yearly_ai_analysis.dart';
import 'package:flutter_app/pages/profile_card_page.dart';
import 'package:flutter_app/pages/chat_page_new.dart' as chat;
import 'package:flutter_app/providers/chat_provider.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_app/models/match_report.dart';

class YearlyReportPage extends StatefulWidget {
  const YearlyReportPage({super.key});

  @override
  State<YearlyReportPage> createState() => _YearlyReportPageState();
}

class _YearlyReportPageState extends State<YearlyReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRange _selectedRange = DateRange.last3Months();
  List<MatchRecord> _matchRecords = [];
  List<ChatHistorySummary> _chatHistories = [];
  YearlyAIAnalysis? _aiAnalysis;
  bool _isLoading = true;
  bool _isLoadingAI = false;
  Set<String> _expandedMatchIds = {};

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
      if (userId == null) throw Exception('Not authenticated');

      final apiService = locator<ApiService>();
      
      final records = await apiService.getMatchHistory(
        userId: userId,
        dateRange: _selectedRange,
      );

      final chatSummaries = await apiService.getChatHistorySummaries(
        userId: userId,
        dateRange: _selectedRange,
      );

      // Try to load cached AI analysis for this date range if available
      try {
        final cached = await apiService.getCachedYearlyAIAnalysis(
          userId: userId,
          dateRange: _selectedRange,
        );
        if (cached != null) {
          _aiAnalysis = cached;
        }
      } catch (e) {
        print('⚠️ Could not load cached AI analysis: $e');
      }

      if (mounted) {
        setState(() {
          _matchRecords = records;
          _chatHistories = chatSummaries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAIAnalysis() async {
    setState(() => _isLoadingAI = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      final apiService = locator<ApiService>();
      final analysis = await apiService.requestYearlyAIAnalysis(
        userId: userId,
        dateRange: _selectedRange,
      );

      if (mounted) {
        setState(() {
          _aiAnalysis = analysis;
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      print('❌ Error loading AI analysis: $e');
      if (mounted) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load AI analysis: $e')),
        );
      }
    }
  }

  void _onDateRangeChanged(DateRange newRange) {
    setState(() {
      _selectedRange = newRange;
      _aiAnalysis = null;
    });
    _loadData();
  }

  void _toggleMatchExpansion(String matchId) {
    setState(() {
      if (_expandedMatchIds.contains(matchId)) {
        _expandedMatchIds.remove(matchId);
      } else {
        _expandedMatchIds.add(matchId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E0DE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2E0DE),
        elevation: 0,
        title: Text(
          'My Report',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.w600,
            fontSize: 26,
            color: const Color(0xFF2C2C2C),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2C2C2C)),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF992121),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF992121),
          labelStyle: GoogleFonts.josefinSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Matches'),
            Tab(text: 'Chats'),
            Tab(text: 'AI Analysis'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDateRangeSelector(),
          _buildSummaryCards(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF992121)),
                  ))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMatchesTab(),
                      _buildChatsTab(),
                      _buildAIAnalysisTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final ranges = [
      DateRange.lastMonth(),
      DateRange.last3Months(),
      DateRange.last6Months(),
      DateRange.allTime(),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ranges.map((range) {
            final isSelected = range.label == _selectedRange.label;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: isSelected ? const Color(0xFF992121) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: isSelected ? 4 : 0,
                child: InkWell(
                  onTap: () => _onDateRangeChanged(range),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      range.label,
                      style: GoogleFonts.josefinSans(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalMatches = _matchRecords.length;
    final totalChats = _chatHistories.length;
    final avgScore = _matchRecords.isEmpty
        ? 0.0
        : _matchRecords.map((r) => r.compatibilityScore).reduce((a, b) => a + b) / _matchRecords.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Matches',
              totalMatches.toString(),
              Icons.favorite,
              const Color(0xFF992121),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Chats',
              totalChats.toString(),
              Icons.chat_bubble,
              const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Score',
              '${(avgScore * 100).toInt()}%',
              Icons.star,
              const Color(0xFFF9A825),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.josefinSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C2C2C),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.josefinSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_matchRecords.isEmpty) {
      return _buildEmptyState(
        'No matches yet',
        'Start matching to see your history here',
        Icons.favorite_border,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matchRecords.length,
      itemBuilder: (context, index) {
        final record = _matchRecords[index];
        final isExpanded = _expandedMatchIds.contains(record.id);
        return _buildMatchRecordCard(record, isExpanded);
      },
    );
  }

  Widget _buildMatchRecordCard(MatchRecord record, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleMatchExpansion(record.id),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: record.matchedUserAvatar.isNotEmpty
                          ? NetworkImage(record.matchedUserAvatar)
                          : null,
                      backgroundColor: const Color(0xFF992121).withOpacity(0.2),
                      child: record.matchedUserAvatar.isEmpty
                          ? Text(
                              record.matchedUsername.isNotEmpty ? record.matchedUsername[0].toUpperCase() : '?',
                              style: GoogleFonts.josefinSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF992121),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.matchedUsername,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(record.createdAt),
                            style: GoogleFonts.josefinSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(record.compatibilityScore).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getScoreColor(record.compatibilityScore).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${(record.compatibilityScore * 100).toInt()}%',
                        style: GoogleFonts.josefinSans(
                          color: _getScoreColor(record.compatibilityScore),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (record.matchSummary.isNotEmpty) ...[
                        Text(
                          'Match Summary',
                          style: GoogleFonts.josefinSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          record.matchSummary,
                          style: GoogleFonts.josefinSans(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'View Profile',
                              Icons.person,
                              () => _viewProfile(record),
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              'Start Chat',
                              Icons.chat_bubble,
                              () => _startChat(record),
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatsTab() {
    if (_chatHistories.isEmpty) {
      return _buildEmptyState(
        'No chat history',
        'Start chatting with your matches',
        Icons.chat_bubble_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistories.length,
      itemBuilder: (context, index) {
        final chat = _chatHistories[index];
        return _buildChatHistoryCard(chat);
      },
    );
  }

  Widget _buildChatHistoryCard(ChatHistorySummary chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChatFromHistory(chat),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: chat.matchedUserAvatar.isNotEmpty
                      ? NetworkImage(chat.matchedUserAvatar)
                      : null,
                  backgroundColor: const Color(0xFF992121).withOpacity(0.2),
                  child: chat.matchedUserAvatar.isEmpty
                      ? Text(
                          chat.matchedUsername.isNotEmpty ? chat.matchedUsername[0].toUpperCase() : '?',
                          style: GoogleFonts.josefinSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF992121),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.matchedUsername,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2C2C2C),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${chat.totalMessages} msgs',
                              style: GoogleFonts.josefinSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E88E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chat.lastMessageText.isNotEmpty ? chat.lastMessageText : 'Start a conversation...',
                        style: GoogleFonts.josefinSans(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatChatTime(chat.lastMessageAt),
                        style: GoogleFonts.josefinSans(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIAnalysisTab() {
    if (_aiAnalysis == null && !_isLoadingAI) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Get AI Insights',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Discover patterns in your matches and get personalized recommendations',
                textAlign: TextAlign.center,
                style: GoogleFonts.josefinSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadAIAnalysis,
              icon: const Icon(Icons.psychology),
              label: Text(
                'Generate AI Analysis',
                style: GoogleFonts.josefinSans(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF992121),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingAI) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF992121)),
            ),
            SizedBox(height: 24),
            Text('Analyzing your match patterns...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIOverviewCard(),
          const SizedBox(height: 16),
          _buildPersonalityTraitsChart(),
          const SizedBox(height: 16),
          _buildInsightsSection(),
          const SizedBox(height: 16),
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildAIOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF992121), Color(0xFFB74040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF992121).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'AI Analysis Summary',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _aiAnalysis?.overallSummary ?? '',
            style: GoogleFonts.josefinSans(
              fontSize: 15,
              color: Colors.white,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Generated on ${DateFormat('MMM dd, yyyy').format(_aiAnalysis?.generatedAt ?? DateTime.now())}',
            style: GoogleFonts.josefinSans(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          if (_aiAnalysis != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _loadAIAnalysis,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('Regenerate Analysis', style: GoogleFonts.josefinSans()),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalityTraitsChart() {
    if (_aiAnalysis == null || _aiAnalysis!.personalityTraits.isEmpty) {
      return const SizedBox.shrink();
    }

    final traits = _aiAnalysis!.personalityTraits;
    final maxValue = traits.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality Traits',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 20),
          ...traits.entries.map((entry) {
            final percentage = (entry.value * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _capitalizeFirst(entry.key),
                        style: GoogleFonts.josefinSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: GoogleFonts.josefinSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF992121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF992121)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    if (_aiAnalysis == null || _aiAnalysis!.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: const Color(0xFF992121), size: 24),
              const SizedBox(width: 12),
              Text(
                'Key Insights',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._aiAnalysis!.insights.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF992121),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizeFirst(entry.key.replaceAll('_', ' ')),
                          style: GoogleFonts.josefinSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value,
                          style: GoogleFonts.josefinSans(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_aiAnalysis == null || _aiAnalysis!.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: const Color(0xFF1E88E5), size: 24),
              const SizedBox(width: 12),
              Text(
                'Recommendations',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._aiAnalysis!.recommendations.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: GoogleFonts.josefinSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.josefinSans(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.josefinSans(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF992121) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.josefinSans(
                  color: isPrimary ? Colors.white : Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return const Color(0xFF4CAF50);
    if (score >= 0.6) return const Color(0xFF2196F3);
    if (score >= 0.4) return const Color(0xFFFF9800);
    return Colors.grey;
  }

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(time);
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _viewProfile(MatchRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileCardPage(userId: record.matchedUserId),
      ),
    );
  }

  void _startChat(MatchRecord record) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      print('🔄 Creating or getting conversation for match: ${record.id}');
      
      // Get or create conversation and get the actual conversation ID
      final conversationId = await chatProvider.createOrGetConversation(
        otherUserId: record.matchedUserId,
        matchId: record.id,
      );

      if (conversationId.isEmpty) {
        throw Exception('Failed to create or locate conversation (empty id).');
      }

      print('✅ Got conversation ID: $conversationId');

      // Wait for the provider to load the conversation
      int attempts = 0;
      const maxAttempts = 25; // 5 seconds total
      while (attempts < maxAttempts) {
        if (chatProvider.getConversationById(conversationId) != null) {
          print('✅ Conversation loaded in provider');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }

      if (chatProvider.getConversationById(conversationId) == null) {
        print('⚠️ Conversation not found in provider after waiting, but continuing anyway');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => chat.ChatPage(
              conversationId: conversationId,
              otherUserId: record.matchedUserId,
              matchId: record.id,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  void _openChatFromHistory(ChatHistorySummary chatSummary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => chat.ChatPage(
          conversationId: chatSummary.conversationId,
          otherUserId: chatSummary.matchedUserId,
          matchId: chatSummary.matchId,
        ),
      ),
    );
  }
}
