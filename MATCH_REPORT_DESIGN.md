# Match结果保存与年度报告系统设计方案

## 📋 需求概述

实现一个完整的Match历史记录和报告系统，支持：
1. **Match结果保存** - 每次匹配后保存详细记录
2. **历史条目查看** - 显示所有match历史，可点击查看详情
3. **统计报告** - 基于时间区间的数据分析和可视化
4. **AI分析** - 使用LLM对用户匹配模式进行深度分析
5. **PDF导出** - 下载完整报告

---

## 🗂️ 数据模型设计

### 1. MatchRecord（Match记录模型）

```dart
// lib/models/match_record.dart
class MatchRecord {
  final String id;                    // 唯一ID
  final String userId;                // 当前用户ID
  final String matchedUserId;         // 匹配到的用户ID
  final String matchedUsername;       // 匹配用户名
  final String matchedUserAvatar;     // 匹配用户头像
  final double compatibilityScore;    // 兼容性分数 (0.0-1.0)
  final String matchSummary;          // AI生成的匹配摘要
  final Map<String, ScoredFeature> featureScores; // 详细特征分析
  final DateTime createdAt;           // 匹配时间
  final MatchAction action;           // 用户行为（已聊天/跳过/未操作）
  final int chatMessageCount;         // 聊天消息数（如果已聊天）
  final DateTime? lastInteractionAt;  // 最后互动时间
  final Map<String, dynamic> metadata; // 扩展元数据
  
  MatchRecord({
    required this.id,
    required this.userId,
    required this.matchedUserId,
    required this.matchedUsername,
    required this.matchedUserAvatar,
    required this.compatibilityScore,
    required this.matchSummary,
    required this.featureScores,
    required this.createdAt,
    this.action = MatchAction.none,
    this.chatMessageCount = 0,
    this.lastInteractionAt,
    this.metadata = const {},
  });
  
  factory MatchRecord.fromMatchAnalysis(MatchAnalysis analysis, String currentUserId) {
    return MatchRecord(
      id: analysis.id,
      userId: currentUserId,
      matchedUserId: analysis.userB.uid,
      matchedUsername: analysis.userB.username,
      matchedUserAvatar: analysis.userB.avatarUrl ?? '',
      compatibilityScore: analysis.totalScore,
      matchSummary: analysis.matchSummary,
      featureScores: analysis.similarFeatures,
      createdAt: DateTime.now(),
      action: MatchAction.none,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'matchedUserId': matchedUserId,
    'matchedUsername': matchedUsername,
    'matchedUserAvatar': matchedUserAvatar,
    'compatibilityScore': compatibilityScore,
    'matchSummary': matchSummary,
    'featureScores': featureScores.map((k, v) => MapEntry(k, {
      'score': v.score,
      'explanation': v.explanation,
    })),
    'createdAt': createdAt.toIso8601String(),
    'action': action.name,
    'chatMessageCount': chatMessageCount,
    'lastInteractionAt': lastInteractionAt?.toIso8601String(),
    'metadata': metadata,
  };
  
  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['featureScores'] as Map<String, dynamic>? ?? {};
    final featureScores = <String, ScoredFeature>{};
    featuresRaw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        featureScores[key] = ScoredFeature.fromJson(value);
      }
    });
    
    return MatchRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      matchedUserId: json['matchedUserId'] as String,
      matchedUsername: json['matchedUsername'] as String? ?? 'Unknown',
      matchedUserAvatar: json['matchedUserAvatar'] as String? ?? '',
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      matchSummary: json['matchSummary'] as String? ?? '',
      featureScores: featureScores,
      createdAt: DateTime.parse(json['createdAt'] as String),
      action: MatchAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => MatchAction.none,
      ),
      chatMessageCount: json['chatMessageCount'] as int? ?? 0,
      lastInteractionAt: json['lastInteractionAt'] != null
          ? DateTime.parse(json['lastInteractionAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

enum MatchAction {
  none,      // 未操作
  chatted,   // 已聊天
  skipped,   // 已跳过
}
```

### 2. MatchReport（报告统计模型）

```dart
// lib/models/match_report.dart
class MatchReport {
  final String userId;
  final DateRange dateRange;
  final MatchStatistics statistics;
  final List<TraitAnalysis> traitAnalysis;
  final List<TopMatch> topMatches;
  final List<MatchTrend> trends;
  final String? aiInsight;  // AI生成的洞察
  
  MatchReport({
    required this.userId,
    required this.dateRange,
    required this.statistics,
    required this.traitAnalysis,
    required this.topMatches,
    required this.trends,
    this.aiInsight,
  });
}

class MatchStatistics {
  final int totalMatches;           // 总匹配数
  final int chattedCount;           // 已聊天数
  final int skippedCount;           // 已跳过数
  final double avgCompatibility;    // 平均兼容性
  final double maxCompatibility;    // 最高兼容性
  final int totalChatMessages;      // 总聊天消息数
  final Map<String, int> actionDistribution; // 行为分布
  
  MatchStatistics({
    required this.totalMatches,
    required this.chattedCount,
    required this.skippedCount,
    required this.avgCompatibility,
    required this.maxCompatibility,
    required this.totalChatMessages,
    required this.actionDistribution,
  });
}

class TraitAnalysis {
  final String trait;
  final int matchCount;       // 该特征的匹配次数
  final double avgScore;      // 平均得分
  final double successRate;   // 成功率（聊天/总数）
  
  TraitAnalysis({
    required this.trait,
    required this.matchCount,
    required this.avgScore,
    required this.successRate,
  });
}

class TopMatch {
  final MatchRecord record;
  final String reason;  // 为什么是Top Match
  
  TopMatch({required this.record, required this.reason});
}

class MatchTrend {
  final DateTime date;
  final int matchCount;
  final double avgScore;
  
  MatchTrend({
    required this.date,
    required this.matchCount,
    required this.avgScore,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;
  final String label;  // "1个月", "3个月", "半年", "全部"
  
  DateRange({
    required this.start,
    required this.end,
    required this.label,
  });
  
  static DateRange lastMonth() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month - 1, now.day),
      end: now,
      label: '1个月',
    );
  }
  
  static DateRange last3Months() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month - 3, now.day),
      end: now,
      label: '3个月',
    );
  }
  
  static DateRange last6Months() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month - 6, now.day),
      end: now,
      label: '半年',
    );
  }
  
  static DateRange allTime() {
    return DateRange(
      start: DateTime(2020, 1, 1),
      end: DateTime.now(),
      label: '全部',
    );
  }
}
```

---

## 🔥 Firestore数据结构

```
/users/{userId}
  ├── matchRecords (subcollection)
  │   ├── {matchRecordId}
  │   │   ├── id: string
  │   │   ├── userId: string
  │   │   ├── matchedUserId: string
  │   │   ├── matchedUsername: string
  │   │   ├── matchedUserAvatar: string
  │   │   ├── compatibilityScore: number
  │   │   ├── matchSummary: string
  │   │   ├── featureScores: map
  │   │   ├── createdAt: timestamp
  │   │   ├── action: string
  │   │   ├── chatMessageCount: number
  │   │   ├── lastInteractionAt: timestamp
  │   │   └── metadata: map
  │   
  └── matchReports (subcollection - cached reports)
      └── {reportId} (e.g., "2024-Q4", "2024-11")
          ├── statistics: map
          ├── traitAnalysis: array
          ├── topMatches: array
          ├── trends: array
          ├── aiInsight: string
          └── generatedAt: timestamp
```

### Firestore Rules 更新

```javascript
// 在 firestore.rules 中添加
match /users/{userId}/matchRecords/{recordId} {
  allow read: if isOwner(userId);
  allow create: if isOwner(userId);
  allow update: if isOwner(userId);
  allow delete: if false; // 不允许删除历史记录
}

match /users/{userId}/matchReports/{reportId} {
  allow read: if isOwner(userId);
  allow write: if false; // 只能由 Cloud Functions 写入
}
```

---

## 🎨 UI界面设计

### 1. YearlyReportPage（年度报告主页）

**功能：**
- 时间区间选择器（1个月/3个月/半年/全部）
- 统计数据卡片展示
- Match历史列表入口
- AI分析报告入口
- PDF导出按钮

**布局结构：**
```dart
YearlyReportPage
├── AppBar (标题 + 导出PDF按钮)
├── DateRangeSelector (时间区间选择)
├── StatisticsOverview (统计概览卡片)
│   ├── TotalMatchesCard
│   ├── AvgScoreCard
│   ├── ChattedRateCard
│   └── TopTraitsCard
├── ActionButtons
│   ├── ViewMatchHistoryButton → MatchHistoryPage
│   ├── ViewAIAnalysisButton → AIAnalysisPage
│   └── ExportPDFButton
└── TrendChart (趋势图表)
```

### 2. MatchHistoryPage（Match历史列表）

**功能：**
- 显示所有Match记录（可筛选）
- 每个条目显示：头像、用户名、分数、时间、行为状态
- 点击进入详情页

**列表项设计：**
```dart
MatchHistoryItem
├── UserAvatar (圆形头像)
├── UserInfo
│   ├── Username
│   ├── MatchSummary (一句话摘要)
│   └── CompatibilityScore (百分比显示)
├── TimeStamp (相对时间，如"2天前")
├── ActionBadge (聊天/跳过/未操作)
└── ArrowIcon (点击进入详情)
```

### 3. MatchDetailPage（Match详情页）

**功能：**
- 显示完整的Match分析
- 复用现有的 MatchAnalysisPage 组件
- 额外显示历史互动信息（如聊天次数）

### 4. AIAnalysisPage（AI分析报告页）

**功能：**
- 调用后端LLM分析用户的匹配模式
- 显示AI生成的洞察和建议
- 展示个性化的匹配特征分析

**内容结构：**
```dart
AIAnalysisPage
├── LoadingIndicator (生成中)
├── AIInsightCard
│   ├── Title: "你的匹配画像"
│   ├── InsightText (AI生成的分析文本)
│   └── KeyPoints (关键洞察列表)
├── MatchPatternChart (匹配模式可视化)
├── RecommendationsCard
│   └── PersonalizedTips (个性化建议)
└── RegenerateButton (重新分析)
```

---

## 🔌 API服务扩展

### 在 ApiService 中添加新方法

```dart
// lib/services/api_service.dart

abstract class ApiService {
  // ... 现有方法 ...
  
  /// 保存Match记录
  Future<void> saveMatchRecord(MatchRecord record);
  
  /// 获取Match历史（支持分页和筛选）
  Future<List<MatchRecord>> getMatchHistory({
    required String userId,
    DateRange? dateRange,
    MatchAction? filterAction,
    int? limit,
    String? startAfter, // 用于分页
  });
  
  /// 更新Match记录的行为状态
  Future<void> updateMatchAction({
    required String userId,
    required String matchRecordId,
    required MatchAction action,
    int? chatMessageCount,
  });
  
  /// 生成Match报告
  Future<MatchReport> generateMatchReport({
    required String userId,
    required DateRange dateRange,
  });
  
  /// 获取缓存的报告（如果存在）
  Future<MatchReport?> getCachedReport({
    required String userId,
    required DateRange dateRange,
  });
  
  /// 请求AI分析报告
  Future<String> requestAIAnalysis({
    required String userId,
    required DateRange dateRange,
  });
  
  /// 导出PDF报告
  Future<Uint8List> exportReportToPDF({
    required MatchReport report,
  });
}
```

### FirebaseApiService 实现

```dart
// lib/services/firebase_api_service.dart

class FirebaseApiService implements ApiService {
  // ... 现有实现 ...
  
  @override
  Future<void> saveMatchRecord(MatchRecord record) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('matchRecords')
        .doc(record.id)
        .set(record.toJson());
  }
  
  @override
  Future<List<MatchRecord>> getMatchHistory({
    required String userId,
    DateRange? dateRange,
    MatchAction? filterAction,
    int? limit,
    String? startAfter,
  }) async {
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('matchRecords')
        .orderBy('createdAt', descending: true);
    
    // 应用时间范围筛选
    if (dateRange != null) {
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: dateRange.start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: dateRange.end.toIso8601String());
    }
    
    // 应用行为筛选
    if (filterAction != null) {
      query = query.where('action', isEqualTo: filterAction.name);
    }
    
    // 应用分页
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => MatchRecord.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }
  
  @override
  Future<void> updateMatchAction({
    required String userId,
    required String matchRecordId,
    required MatchAction action,
    int? chatMessageCount,
  }) async {
    final updates = {
      'action': action.name,
      'lastInteractionAt': DateTime.now().toIso8601String(),
    };
    
    if (chatMessageCount != null) {
      updates['chatMessageCount'] = chatMessageCount;
    }
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('matchRecords')
        .doc(matchRecordId)
        .update(updates);
  }
  
  @override
  Future<MatchReport> generateMatchReport({
    required String userId,
    required DateRange dateRange,
  }) async {
    // 1. 获取时间范围内的所有记录
    final records = await getMatchHistory(
      userId: userId,
      dateRange: dateRange,
    );
    
    if (records.isEmpty) {
      return _emptyReport(userId, dateRange);
    }
    
    // 2. 计算统计数据
    final statistics = _calculateStatistics(records);
    
    // 3. 分析特征
    final traitAnalysis = _analyzeTraits(records);
    
    // 4. 找出Top Matches
    final topMatches = _findTopMatches(records);
    
    // 5. 生成趋势数据
    final trends = _generateTrends(records, dateRange);
    
    return MatchReport(
      userId: userId,
      dateRange: dateRange,
      statistics: statistics,
      traitAnalysis: traitAnalysis,
      topMatches: topMatches,
      trends: trends,
    );
  }
  
  @override
  Future<String> requestAIAnalysis({
    required String userId,
    required DateRange dateRange,
  }) async {
    final report = await generateMatchReport(
      userId: userId,
      dateRange: dateRange,
    );
    
    // 调用后端Cloud Function进行AI分析
    final callable = _functions.httpsCallable('analyzeMatchPattern');
    final result = await callable.call({
      'userId': userId,
      'statistics': report.statistics.toJson(),
      'traitAnalysis': report.traitAnalysis.map((t) => t.toJson()).toList(),
      'dateRange': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
      },
    });
    
    return result.data['analysis'] as String;
  }
  
  // 辅助方法
  MatchStatistics _calculateStatistics(List<MatchRecord> records) {
    final totalMatches = records.length;
    final chattedCount = records.where((r) => r.action == MatchAction.chatted).length;
    final skippedCount = records.where((r) => r.action == MatchAction.skipped).length;
    
    final avgCompatibility = records.isEmpty
        ? 0.0
        : records.map((r) => r.compatibilityScore).reduce((a, b) => a + b) / records.length;
    
    final maxCompatibility = records.isEmpty
        ? 0.0
        : records.map((r) => r.compatibilityScore).reduce((a, b) => a > b ? a : b);
    
    final totalChatMessages = records
        .map((r) => r.chatMessageCount)
        .fold(0, (sum, count) => sum + count);
    
    final actionDistribution = {
      'none': records.where((r) => r.action == MatchAction.none).length,
      'chatted': chattedCount,
      'skipped': skippedCount,
    };
    
    return MatchStatistics(
      totalMatches: totalMatches,
      chattedCount: chattedCount,
      skippedCount: skippedCount,
      avgCompatibility: avgCompatibility,
      maxCompatibility: maxCompatibility,
      totalChatMessages: totalChatMessages,
      actionDistribution: actionDistribution,
    );
  }
  
  // ... 其他辅助方法实现
}
```

---

## 📲 UI实现要点

### 1. YearlyReportPage 重构

```dart
// lib/pages/yearly_report_page.dart
class YearlyReportPage extends StatefulWidget {
  const YearlyReportPage({super.key});
  
  @override
  State<YearlyReportPage> createState() => _YearlyReportPageState();
}

class _YearlyReportPageState extends State<YearlyReportPage> {
  DateRange _selectedRange = DateRange.last3Months();
  MatchReport? _report;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadReport();
  }
  
  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');
      
      final apiService = locator<ApiService>();
      final report = await apiService.generateMatchReport(
        userId: userId,
        dateRange: _selectedRange,
      );
      
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading report: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _onDateRangeChanged(DateRange newRange) {
    setState(() => _selectedRange = newRange);
    _loadReport();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Report', style: GoogleFonts.cormorantGaramond()),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportPDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // 时间选择器
                SliverToBoxAdapter(
                  child: DateRangeSelector(
                    selectedRange: _selectedRange,
                    onChanged: _onDateRangeChanged,
                  ),
                ),
                
                // 统计卡片
                if (_report != null) ...[
                  SliverToBoxAdapter(
                    child: StatisticsOverview(statistics: _report!.statistics),
                  ),
                  
                  // 操作按钮
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _viewHistory,
                              icon: const Icon(Icons.history),
                              label: const Text('查看历史'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _viewAIAnalysis,
                              icon: const Icon(Icons.psychology),
                              label: const Text('AI分析'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 特征分析
                  _buildTraitAnalysisCard(_report!.traitAnalysis),
                  
                  // Top Matches
                  _buildTopMatchesCard(_report!.topMatches),
                  
                  // 趋势图
                  _buildTrendChart(_report!.trends),
                ],
              ],
            ),
    );
  }
  
  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchHistoryPage(dateRange: _selectedRange),
      ),
    );
  }
  
  void _viewAIAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIAnalysisPage(
          userId: FirebaseAuth.instance.currentUser!.uid,
          dateRange: _selectedRange,
        ),
      ),
    );
  }
  
  Future<void> _exportPDF() async {
    if (_report == null) return;
    
    try {
      final apiService = locator<ApiService>();
      final pdfBytes = await apiService.exportReportToPDF(report: _report!);
      
      // 保存或分享PDF
      // 使用 path_provider 和 share_plus 包
      // ... PDF保存逻辑
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('报告已导出')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }
}
```

### 2. MatchHistoryPage 创建

```dart
// lib/pages/match_history_page.dart
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
      
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match History', style: GoogleFonts.cormorantGaramond()),
        actions: [
          PopupMenuButton<MatchAction?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (action) {
              setState(() => _filterAction = action);
              _loadHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              const PopupMenuItem(value: MatchAction.chatted, child: Text('已聊天')),
              const PopupMenuItem(value: MatchAction.skipped, child: Text('已跳过')),
              const PopupMenuItem(value: MatchAction.none, child: Text('未操作')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('暂无匹配记录'))
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
    // 从 MatchRecord 重建 MatchAnalysis
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 30,
                backgroundImage: record.matchedUserAvatar.isNotEmpty
                    ? NetworkImage(record.matchedUserAvatar)
                    : null,
                child: record.matchedUserAvatar.isEmpty
                    ? Text(record.matchedUsername[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 16),
              
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.matchedUsername,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActionBadge(action: record.action),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.matchSummary,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(record.compatibilityScore * 100).toInt()}%',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(record.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.chevron_right),
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
    } else {
      return '${diff.inMinutes}分钟前';
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
```

### 3. AIAnalysisPage 创建

```dart
// lib/pages/ai_analysis_page.dart
class AIAnalysisPage extends StatefulWidget {
  final String userId;
  final DateRange dateRange;
  
  const AIAnalysisPage({
    super.key,
    required this.userId,
    required this.dateRange,
  });
  
  @override
  State<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends State<AIAnalysisPage> {
  String? _analysis;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }
  
  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = locator<ApiService>();
      final analysis = await apiService.requestAIAnalysis(
        userId: widget.userId,
        dateRange: widget.dateRange,
      );
      
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading AI analysis: $e');
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Analysis', style: GoogleFonts.cormorantGaramond()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysis,
            tooltip: 'Regenerate',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'AI正在分析你的匹配模式...',
                    style: GoogleFonts.notoSerifSc(),
                  ),
                ],
              ),
            )
          : _analysis == null
              ? const Center(child: Text('分析失败，请重试'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '你的匹配画像',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _analysis!,
                            style: GoogleFonts.notoSerifSc(
                              fontSize: 16,
                              height: 1.8,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        '基于 ${widget.dateRange.label} 的数据生成',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
```

---

## 🔧 集成到现有系统

### 1. 修改 MatchResultPage

在用户查看match结果后，自动保存记录：

```dart
// lib/pages/match_result_page.dart
class _MatchResultPageState extends State<MatchResultPage> {
  // ... 现有代码 ...
  
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    final apiService = locator<ApiService>();

    if (currentUser == null) {
      _matchesFuture = Future.error('User not authenticated');
      return;
    }

    final uid = currentUser.uid;
    if (widget.useCachedResults) {
      _matchesFuture = apiService.getCachedMatches(uid);
    } else {
      _matchesFuture = apiService.getMatches(uid).then((matches) {
        // 自动保存所有新的match记录
        _saveMatchRecords(matches, uid);
        return matches;
      });
    }
  }
  
  Future<void> _saveMatchRecords(List<MatchAnalysis> matches, String userId) async {
    try {
      final apiService = locator<ApiService>();
      for (final match in matches) {
        final record = MatchRecord.fromMatchAnalysis(match, userId);
        await apiService.saveMatchRecord(record);
      }
    } catch (e) {
      print('Error saving match records: $e');
    }
  }
}
```

### 2. 修改 ChatPage

当用户开始聊天时，更新match记录状态：

```dart
// lib/pages/chat_page.dart
class ChatPage extends StatefulWidget {
  final MatchProfile profile;
  final String? matchRecordId; // 新增：关联的match记录ID
  
  const ChatPage({
    super.key,
    required this.profile,
    this.matchRecordId,
  });
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    _updateMatchAction();
  }
  
  Future<void> _updateMatchAction() async {
    if (widget.matchRecordId == null) return;
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final apiService = locator<ApiService>();
      await apiService.updateMatchAction(
        userId: userId,
        matchRecordId: widget.matchRecordId!,
        action: MatchAction.chatted,
      );
    } catch (e) {
      print('Error updating match action: $e');
    }
  }
}
```

### 3. 更新 ProfilePage

添加"Match报告"入口：

```dart
// lib/pages/profile_page.dart
// 已有的 IconButton，只需确保 YearlyReportPage 完整实现
IconButton(
  icon: const Icon(Icons.timeline_outlined),
  onPressed: () {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const YearlyReportPage(),
    ));
  },
  tooltip: 'View Match Report',
),
```

---

## 🤖 后端Cloud Function（AI分析）

```typescript
// backend/functions/src/analyzeMatchPattern.ts
import * as functions from 'firebase-functions';
import { ChatOpenAI } from '@langchain/openai';

export const analyzeMatchPattern = functions.https.onCall(async (data, context) => {
  // 验证用户身份
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { userId, statistics, traitAnalysis, dateRange } = data;
  
  // 构建AI提示词
  const prompt = `
你是一位专业的社交关系分析师。请根据以下用户的匹配数据，生成一份深入的分析报告。

## 统计数据：
- 总匹配数: ${statistics.totalMatches}
- 已聊天: ${statistics.chattedCount}
- 已跳过: ${statistics.skippedCount}
- 平均兼容性: ${(statistics.avgCompatibility * 100).toFixed(1)}%
- 最高兼容性: ${(statistics.maxCompatibility * 100).toFixed(1)}%

## 特征分析：
${traitAnalysis.map((t: any) => 
  `- ${t.trait}: 匹配${t.matchCount}次，平均分${t.avgScore.toFixed(1)}，成功率${(t.successRate * 100).toFixed(1)}%`
).join('\n')}

## 时间范围：
${dateRange.start} 到 ${dateRange.end}

请生成一份包含以下内容的分析报告：
1. 用户的匹配偏好总结（2-3句话）
2. 最显著的性格特征（基于特征分析）
3. 匹配模式的优势和改进建议
4. 个性化的交友建议

请用温暖、专业的语气，避免过于技术化的表述。字数控制在300-500字。
  `;
  
  try {
    const model = new ChatOpenAI({
      modelName: 'gpt-4',
      temperature: 0.7,
    });
    
    const response = await model.invoke(prompt);
    
    return {
      analysis: response.content,
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error generating AI analysis:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate analysis');
  }
});
```

---

## 📦 依赖包

需要在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  # 现有依赖...
  
  # PDF生成
  pdf: ^3.10.0
  printing: ^5.11.0
  
  # 文件保存
  path_provider: ^2.1.0
  
  # 分享功能
  share_plus: ^7.2.0
  
  # 图表（如果需要更复杂的图表）
  fl_chart: ^0.65.0  # 已有
  
  # 日期处理
  intl: ^0.18.0
```

---

## 🎯 实施步骤

### Phase 1: 数据模型与存储（1-2天）
1. ✅ 创建 `MatchRecord` 和 `MatchReport` 数据模型
2. ✅ 更新 Firestore 安全规则
3. ✅ 实现 `saveMatchRecord` 和 `getMatchHistory` API

### Phase 2: 历史列表页面（1天）
1. ✅ 创建 `MatchHistoryPage` 和 `MatchHistoryItem`
2. ✅ 实现筛选和分页功能
3. ✅ 集成到现有导航

### Phase 3: 报告生成（2天）
1. ✅ 实现 `generateMatchReport` 逻辑
2. ✅ 重构 `YearlyReportPage` 显示真实数据
3. ✅ 添加时间区间选择器
4. ✅ 实现统计卡片和图表

### Phase 4: AI分析（1-2天）
1. ✅ 创建 `AIAnalysisPage`
2. ✅ 实现后端 Cloud Function `analyzeMatchPattern`
3. ✅ 集成LLM调用

### Phase 5: PDF导出（1天）
1. ✅ 实现 `exportReportToPDF` 功能
2. ✅ 设计PDF模板
3. ✅ 添加分享功能

### Phase 6: 集成与测试（1天）
1. ✅ 修改 `MatchResultPage` 自动保存记录
2. ✅ 修改 `ChatPage` 更新行为状态
3. ✅ 端到端测试
4. ✅ UI优化和bug修复

---

## 🎨 UI风格保持

### 遵循现有设计原则：
- **字体**: 
  - 标题使用 `GoogleFonts.cormorantGaramond`
  - 正文使用 `GoogleFonts.notoSerifSc`
- **颜色**: 
  - 主色调保持一致（`Color(0xFFE2E0DE)` 背景）
  - 强调色使用 `Color(0xFF992121)`
- **卡片**: 
  - 圆角 `BorderRadius.circular(12-16)`
  - 阴影 `elevation: 4-8`
- **动画**: 
  - 页面切换使用 `MaterialPageRoute`
  - 加载状态使用 `CircularProgressIndicator`

---

## 🔒 安全与隐私

1. **数据访问控制**: Match记录只能由所有者访问
2. **匿名化**: 导出PDF时可选择匿名化敏感信息
3. **数据保留**: 提供删除旧记录的选项（设置页面）
4. **AI分析**: 不保存AI分析的原始prompt，只保存结果

---

## 📊 性能优化

1. **分页加载**: Match历史使用虚拟滚动和懒加载
2. **缓存报告**: 已生成的报告缓存7天
3. **异步生成**: AI分析异步生成，显示进度
4. **图片优化**: 头像使用缩略图

---

## 🧪 测试计划

1. **单元测试**: 数据模型序列化/反序列化
2. **集成测试**: API服务方法
3. **UI测试**: 关键页面的交互流程
4. **性能测试**: 大量数据下的列表滚动
5. **兼容性测试**: Web/Mobile平台

---

## ✅ 总结

这个设计方案提供了一个完整的Match结果保存和报告系统，核心特点：

✅ **完整数据链路**: 从Match生成 → 保存记录 → 历史查看 → 统计分析 → AI洞察 → PDF导出  
✅ **灵活时间筛选**: 支持1个月/3个月/半年/全部的报告生成  
✅ **丰富可视化**: 统计卡片、趋势图表、特征分析  
✅ **AI增强**: 基于LLM的个性化分析和建议  
✅ **UI一致性**: 严格遵循现有的设计风格和组件库  
✅ **可扩展性**: 模块化设计，易于未来功能扩展  

开始实施时，建议按Phase顺序逐步开发，每个阶段完成后进行测试和验证。
