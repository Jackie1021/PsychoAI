import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/models/match_profile.dart';
import 'package:flutter_app/pages/match_result_page.dart';

class AiChatPage extends StatefulWidget {
  final UserData currentUser;

  const AiChatPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ApiService _apiService = locator<ApiService>();
  
  bool _isTyping = false;
  bool _showMatchSuggestion = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  Timer? _analysisTimer;
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));

    _initializeChat();
    _startPeriodicAnalysis();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _analysisTimer?.cancel();
    super.dispose();
  }

  void _initializeChat() {
    _addMessage(ChatMessage(
      text: "Hi ${widget.currentUser.username}! 👋 I'm your AI companion. Feel free to share anything that's on your mind - your thoughts, experiences, or feelings. I'm here to listen and understand.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _startPeriodicAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_messageCount >= 5 && !_showMatchSuggestion) {
        _analyzeConversationForMatching();
      }
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();
    _messageCount++;

    // Show AI typing
    setState(() {
      _isTyping = true;
    });
    _typingAnimationController.repeat();

    try {
      // Get AI response from Gemini
      final response = await _apiService.sendAiChatMessage(
        text, 
        _messages.take(_messages.length - 1).toList(),  // Exclude the message we just added
      );

      // Add AI response
      _addMessage(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      // Check if we should suggest matching
      if (_messageCount >= 3 && !_showMatchSuggestion) {
        _considerMatchingSuggestion();
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text: "I'm having trouble connecting right now. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _isTyping = false;
    });
    _typingAnimationController.stop();
  }

  void _considerMatchingSuggestion() {
    // Randomly suggest matching after some conversation
    if (_messageCount >= 3 && DateTime.now().millisecond % 3 == 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_showMatchSuggestion) {
          _suggestMatching();
        }
      });
    }
  }

  void _suggestMatching() {
    setState(() {
      _showMatchSuggestion = true;
    });

    _addMessage(ChatMessage(
      text: "Based on our conversation, I sense you might benefit from connecting with someone who has similar experiences. Would you like me to help you find a soulmate who truly understands your journey? 💫",
      isUser: false,
      timestamp: DateTime.now(),
      isMatchSuggestion: true,
    ));
  }

  Future<void> _analyzeConversationForMatching() async {
    if (_messages.length < 5) return;

    setState(() {
      _isTyping = true;
    });

    try {
      // Extract conversation for analysis
      final conversation = _messages.map((m) => 
        "${m.isUser ? 'User' : 'AI'}: ${m.text}"
      ).join('\n');

      // Perform LLM analysis and matching
      final matches = await _apiService.analyzeChatAndFindMatches(
        widget.currentUser.uid,
        conversation,
      );

      if (matches.isNotEmpty && mounted) {
        _showSoulmateSuggestion(matches);
      }
    } catch (e) {
      print('Error analyzing conversation: $e');
    }

    setState(() {
      _isTyping = false;
    });
  }

  void _showSoulmateSuggestion(List<MatchProfile> matches) {
    final topMatch = matches.first;
    final keyword = topMatch.analysis?.keyInsights.isNotEmpty == true 
        ? topMatch.analysis!.keyInsights.first
        : "shared experience";

    _addMessage(ChatMessage(
      text: "I found someone special who resonates with your story! 🌟\n\nYour connection point: \"${keyword}\"\n\nWould you like to see this soulmate match?",
      isUser: false,
      timestamp: DateTime.now(),
      isMatchResult: true,
      matchData: matches,
    ));
  }

  void _handleMatchResponse(bool accepted, List<MatchProfile>? matches) {
    if (accepted && matches != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MatchResultPage(),
        ),
      );
    } else {
      _addMessage(ChatMessage(
        text: "No worries! I'll keep our conversation going. Remember, I'm here whenever you need to talk. 💙",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
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
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF992121), Color(0xFFE6A5A5)],
                ),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Companion',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F4A45),
                  ),
                ),
                Text(
                  'Your personal soulmate finder',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF992121), Color(0xFFE6A5A5)],
                ),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                  ? const Color(0xFF992121)
                  : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : const Color(0xFF4F4A45),
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  if (message.isMatchSuggestion) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _analyzeConversationForMatching();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF992121),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Yes, find my soulmate!'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _handleMatchResponse(false, null);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF992121),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Maybe later'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (message.isMatchResult && message.matchData != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _handleMatchResponse(true, message.matchData);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF992121),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Show me! 💫'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _handleMatchResponse(false, null);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF992121),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Not now'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF992121), Color(0xFFE6A5A5)],
              ),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            Colors.grey[400],
                            const Color(0xFF992121),
                            (((_typingAnimation.value + i * 0.3) % 1.0)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF992121), Color(0xFFE6A5A5)],
              ),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isMatchSuggestion;
  final bool isMatchResult;
  final List<MatchProfile>? matchData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isMatchSuggestion = false,
    this.isMatchResult = false,
    this.matchData,
  });
}