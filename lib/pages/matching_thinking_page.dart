import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'match_result_page.dart';

class MatchingThinkingPage extends StatefulWidget {
  final List<String> selectedTraits;
  final String freeText;

  const MatchingThinkingPage({
    super.key,
    required this.selectedTraits,
    required this.freeText,
  });

  @override
  State<MatchingThinkingPage> createState() => _MatchingThinkingPageState();
}

class _MatchingThinkingPageState extends State<MatchingThinkingPage>
    with TickerProviderStateMixin {
  final List<ThinkingStep> _thinkingSteps = [];
  int _currentStepIndex = 0;
  int _currentSubStepIndex = 0;
  String _currentDisplayText = '';
  int _currentCharIndex = 0;
  late AnimationController _typingController;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  Timer? _stepTimer;
  Timer? _typingTimer;
  bool _isSkipped = false;
  
  @override
  void initState() {
    super.initState();
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _initializeThinkingSteps();
    _startThinkingProcess();
  }

  @override
  void dispose() {
    _typingController.dispose();
    _loadingController.dispose();
    _stepTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _initializeThinkingSteps() {
    _thinkingSteps.addAll([
      ThinkingStep(
        title: '🧠 Analyzing User Profile',
        subSteps: [
          'Parsing user input characteristics...',
          'Detected traits: ${widget.selectedTraits.join(', ')}',
          'Analyzing description: "${widget.freeText}"',
          'Identifying core emotional needs: ${_getEmotionalNeed()}',
          'Evaluating support type preferences: ${_getSupportType()}',
          'Generating psychological profile...',
          '✓ User profile analysis complete',
        ],
      ),
      ThinkingStep(
        title: '📊 Building Matching Model',
        subSteps: [
          'Loading psychological matching algorithms...',
          'Constructing similarity model based on CBT principles',
          'Dimension 1: Cognitive similarity assessment',
          'Dimension 2: Emotional support compatibility',
          'Dimension 3: Shared experience resonance',
          'Dimension 4: Value alignment evaluation',
          'Dimension 5: Communication style compatibility',
          '✓ Multi-dimensional matching model established',
        ],
      ),
      ThinkingStep(
        title: '🔍 Scanning User Database',
        subSteps: [
          'Connecting to user database...',
          'Scanning ${_getRandomUserCount()} registered users',
          'Applying privacy filters...',
          'Filtering active users: ${_getActiveUserCount()} found',
          'Excluding incompatible trait combinations...',
          'Pre-screening candidates: ${_getCandidateCount()} eligible',
          '✓ Candidate pool established',
        ],
      ),
      ThinkingStep(
        title: '⚖️ Deep Compatibility Analysis',
        subSteps: [
          'Running deep analysis for each candidate...',
          'Computing trait overlap: ${_getRandomPercentage()}%',
          'Evaluating complementarity index: ${_getRandomPercentage()}%',
          'Analyzing support potential: ${_getRandomPercentage()}%',
          'Checking communication style match: ${_getRandomPercentage()}%',
          'Calculating comprehensive scores...',
          'Applying diversity balancing algorithms...',
          '✓ Compatibility scoring complete',
        ],
      ),
      ThinkingStep(
        title: '🎯 Personalized Recommendations',
        subSteps: [
          'Analyzing user interaction history...',
          'Considering geographical proximity...',
          'Evaluating activity pattern alignment...',
          'Applying ML-optimized weightings...',
          'Generating personalized recommendation list...',
          '✓ Recommendation algorithm optimization complete',
        ],
      ),
      ThinkingStep(
        title: '✅ Finalizing Results',
        subSteps: [
          'Organizing matching results...',
          'Found ${_getMatchCount()} high-quality matches',
          'Ranking by compatibility scores...',
          'Preparing detailed match explanations...',
          '✓ Matching process complete!',
        ],
      ),
    ]);
  }

  String _generateTraitAnalysis() {
    final traits = widget.selectedTraits;
    if (traits.isEmpty) {
      return '用户未选择特定特征，我将基于开放性和包容性进行匹配。';
    }
    
    return '检测到用户特征: ${traits.join(', ')}\n'
           '分析关键词: "${widget.freeText}"\n'
           '识别核心需求：寻求${_getEmotionalNeed()}和${_getSupportType()}';
  }

  String _getEmotionalNeed() {
    final needs = ['understanding', 'empathy', 'support', 'companionship', 'encouragement'];
    return needs[DateTime.now().millisecond % needs.length];
  }

  String _getSupportType() {
    final types = ['emotional support', 'practical advice', 'experience sharing', 'mutual encouragement'];
    return types[DateTime.now().millisecond % types.length];
  }

  int _getRandomUserCount() {
    return 150 + (DateTime.now().millisecond % 200);
  }

  int _getActiveUserCount() {
    return 80 + (DateTime.now().millisecond % 60);
  }

  int _getCandidateCount() {
    return 20 + (DateTime.now().millisecond % 30);
  }

  int _getRandomPercentage() {
    return 70 + (DateTime.now().millisecond % 25);
  }

  int _getMatchCount() {
    return 3 + (DateTime.now().millisecond % 4);
  }

  void _startThinkingProcess() {
    _showNextStep();
  }

  void _skipThinking() {
    setState(() {
      _isSkipped = true;
    });
    _typingTimer?.cancel();
    _stepTimer?.cancel();
    _navigateToResults();
  }

  void _showNextStep() {
    if (_isSkipped) return;
    
    if (_currentStepIndex >= _thinkingSteps.length) {
      _navigateToResults();
      return;
    }

    final step = _thinkingSteps[_currentStepIndex];
    setState(() {
      step.isVisible = true;
      step.isTyping = true;
      _currentSubStepIndex = 0;
      _currentDisplayText = '';
      _currentCharIndex = 0;
    });

    _showNextSubStep();
  }

  void _showNextSubStep() {
    if (_isSkipped) return;
    
    final step = _thinkingSteps[_currentStepIndex];
    
    if (_currentSubStepIndex >= step.subSteps.length) {
      // Current step completed
      setState(() {
        step.isComplete = true;
        step.isTyping = false;
      });
      
      Timer(const Duration(milliseconds: 800), () {
        _currentStepIndex++;
        _showNextStep();
      });
      return;
    }

    final currentSubStep = step.subSteps[_currentSubStepIndex];
    _currentDisplayText = '';
    _currentCharIndex = 0;
    
    _typeText(currentSubStep);
  }

  void _typeText(String text) {
    if (_isSkipped) return;
    
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_isSkipped) {
        timer.cancel();
        return;
      }
      
      if (_currentCharIndex >= text.length) {
        timer.cancel();
        // Wait before showing next sub-step
        Timer(const Duration(milliseconds: 600), () {
          _currentSubStepIndex++;
          _showNextSubStep();
        });
        return;
      }

      setState(() {
        _currentDisplayText = text.substring(0, _currentCharIndex + 1);
        _currentCharIndex++;
      });
    });
  }

  void _navigateToResults() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MatchResultPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Skip button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Intelligent Matching',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          'Psycho AI is performing deep analysis for matching...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Skip button
                  TextButton.icon(
                    onPressed: _isSkipped ? null : _skipThinking,
                    icon: const Icon(Icons.fast_forward, size: 16),
                    label: const Text('Skip'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStepIndex + (_currentSubStepIndex / (_thinkingSteps.isNotEmpty ? _thinkingSteps[_currentStepIndex < _thinkingSteps.length ? _currentStepIndex : _thinkingSteps.length - 1].subSteps.length : 1))) / _thinkingSteps.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStepIndex + 1} / ${_thinkingSteps.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.5 + 0.5 * _loadingAnimation.value,
                        child: Text(
                          'Thinking...',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Thinking steps
              Expanded(
                child: ListView.builder(
                  itemCount: _thinkingSteps.length,
                  itemBuilder: (context, index) {
                    final step = _thinkingSteps[index];
                    return _buildThinkingStep(step, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingStep(ThinkingStep step, int index) {
    final isCurrentStep = index == _currentStepIndex;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(step.isVisible ? 16 : 0),
      decoration: BoxDecoration(
        color: step.isVisible 
            ? Colors.white
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: step.isVisible 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: Border.all(
          color: step.isComplete 
              ? Colors.green.withOpacity(0.3)
              : step.isVisible
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.transparent,
          width: 1,
        ),
      ),
      child: step.isVisible 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step header
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: step.isComplete
                            ? Colors.green
                            : step.isTyping
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        step.isComplete 
                            ? Icons.check
                            : step.isTyping
                                ? Icons.psychology
                                : Icons.pending,
                        size: 16,
                        color: step.isComplete || step.isTyping 
                            ? Colors.white 
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: step.isComplete 
                              ? Colors.green[700]
                              : step.isTyping
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[700],
                        ),
                      ),
                    ),
                    if (step.isTyping && !step.isComplete)
                      AnimatedBuilder(
                        animation: _loadingAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.5 + 0.5 * _loadingAnimation.value,
                            child: const Icon(
                              Icons.more_horiz,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                  ],
                ),
                
                // Sub-steps content
                if (step.isVisible) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show completed sub-steps
                        if (step.isComplete) ...[
                          for (int i = 0; i < step.subSteps.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.subSteps[i],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ] else if (isCurrentStep) ...[
                          // Show current typing sub-steps
                          for (int i = 0; i < _currentSubStepIndex; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.subSteps[i],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Current typing text
                          if (_currentSubStepIndex < step.subSteps.length) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _loadingAnimation,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: 0.6 + 0.4 * _loadingAnimation.value,
                                        child: Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _currentDisplayText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).primaryColor,
                                        height: 1.3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class ThinkingStep {
  final String title;
  final List<String> subSteps;
  bool isVisible;
  bool isTyping;
  bool isComplete;

  ThinkingStep({
    required this.title,
    required this.subSteps,
    this.isVisible = false,
    this.isTyping = false,
    this.isComplete = false,
  });
}