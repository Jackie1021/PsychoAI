import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/pages/feature_selection_page.dart';

class MoodSelectionPage extends StatefulWidget {
  final UserData currentUser;

  const MoodSelectionPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<MoodSelectionPage> createState() => _MoodSelectionPageState();
}

class _MoodSelectionPageState extends State<MoodSelectionPage> 
    with TickerProviderStateMixin {
  final ApiService _apiService = locator<ApiService>();
  
  List<String> _availableKeywords = [];
  List<String> _selectedKeywords = [];
  bool _isLoadingKeywords = true;
  bool _isPersonalized = false;
  String _keywordSource = '';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _loadPersonalizedKeywords();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalizedKeywords() async {
    try {
      // First check if user should get demo personalized keywords (simulate learning data)
      final shouldShowDemo = widget.currentUser.uid.contains('alice') || 
                            widget.currentUser.uid.contains('bob') ||
                            widget.currentUser.email?.contains('alice') == true ||
                            widget.currentUser.email?.contains('bob') == true;
      
      if (shouldShowDemo) {
        // 🎯 DEMO: Show personalized keywords for demo purposes
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
        
        final personalizedDemoKeywords = [
          "寻找创作灵感", "渴望深度对话", "需要情感共鸣", "探索艺术美学",
          "享受安静思考", "追求精神契合", "喜欢温暖陪伴", "重视真诚交流",
          "创意思维活跃", "内心敏感细腻", "期待理解支持", "热爱文艺生活"
        ];
        
        if (mounted) {
          setState(() {
            _availableKeywords = personalizedDemoKeywords;
            _keywordSource = 'personalized';
            _isPersonalized = true;
            _isLoadingKeywords = false;
          });
          _slideController.forward();
        }
        return;
      }
      
      // Try to get personalized keywords from backend
      final result = await _apiService.getPersonalizedMoodKeywords(widget.currentUser.uid);
      
      if (mounted) {
        setState(() {
          _availableKeywords = List<String>.from(result['keywords'] ?? []);
          _keywordSource = result['source'] ?? 'unknown';
          _isPersonalized = _keywordSource == 'personalized';
          _isLoadingKeywords = false;
        });
        
        _slideController.forward();
      }
    } catch (e) {
      print('❌ Error loading personalized keywords: $e');
      
      // Fallback to default keywords
      if (mounted) {
        setState(() {
          _availableKeywords = [
            '寻找共鸣', '深度交流', '真诚相待', '温暖陪伴', 
            '理解支持', '精神契合', '创意分享', '成长伙伴',
            '安静思考', '活力满满', '探索新鲜', '享受当下',
            '艺术灵感', '知性对话', '浪漫情怀', '冒险精神'
          ];
          _keywordSource = 'default';
          _isPersonalized = false;
          _isLoadingKeywords = false;
        });
        
        _slideController.forward();
      }
    }
  }

  void _toggleKeyword(String keyword) {
    setState(() {
      if (_selectedKeywords.contains(keyword)) {
        _selectedKeywords.remove(keyword);
      } else {
        if (_selectedKeywords.length < 5) {
          _selectedKeywords.add(keyword);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('最多只能选择5个关键词'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    });
  }

  void _proceedToMatching() {
    if (_selectedKeywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请至少选择一个关键词来描述您当前的状态'),
          backgroundColor: const Color(0xFF992121),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Navigate to feature selection with mood context
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FeatureSelectionPage(
          moodKeywords: _selectedKeywords,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4F4A45)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '今日状态',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4F4A45),
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: _buildHeaderSection(),
              ),
              
              const SizedBox(height: 32),
              
              SlideTransition(
                position: _slideAnimation,
                child: _buildPersonalizationInfo(),
              ),
              
              const SizedBox(height: 24),
              
              SlideTransition(
                position: _slideAnimation,
                child: _buildKeywordSection(),
              ),
              
              const SizedBox(height: 32),
              
              SlideTransition(
                position: _slideAnimation,
                child: _buildSelectedKeywordsSection(),
              ),
              
              const SizedBox(height: 40),
              
              SlideTransition(
                position: _slideAnimation,
                child: _buildContinueButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF992121).withOpacity(0.1),
            const Color(0xFFE6A5A5).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF992121).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF992121),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi ${widget.currentUser.username}!',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4F4A45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '选择几个关键词来描述您今天的心情和状态',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationInfo() {
    if (!_isPersonalized) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Colors.amber[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI已根据您的历史偏好个性化这些关键词',
              style: TextStyle(
                fontSize: 13,
                color: Colors.amber[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordSection() {
    if (_isLoadingKeywords) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF992121)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择关键词 (最多5个)',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4F4A45),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableKeywords.map((keyword) {
            final isSelected = _selectedKeywords.contains(keyword);
            return GestureDetector(
              onTap: () => _toggleKeyword(keyword),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? const Color(0xFF992121) 
                    : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? const Color(0xFF992121) 
                      : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                        ? const Color(0xFF992121).withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4F4A45),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectedKeywordsSection() {
    if (_selectedKeywords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已选择 (${_selectedKeywords.length}/5)',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4F4A45),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF992121).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF992121).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedKeywords.map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF992121),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      keyword,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _toggleKeyword(keyword),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedKeywords.isNotEmpty ? _proceedToMatching : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF992121),
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _selectedKeywords.isNotEmpty ? 8 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 20),
            const SizedBox(width: 8),
            Text(
              '开始匹配',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}