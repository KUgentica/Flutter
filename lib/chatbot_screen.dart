import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bookmark.dart';
import 'calendar.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  int _selectedIndex = 2;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showWelcomeCard = true;
  final List<Map<String, String>> _messages = [];

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

  Future<String> _sendToAgentica(String message) async {
    final url = Uri.parse("http://10.0.2.2:3000/chat");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "(응답 없음)";
      } else {
        return "서버 오류: ${response.statusCode}";
      }
    } catch (e) {
      return "연결 실패: $e";
    }
  }

  void _onCompletePressed() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _showWelcomeCard = false;
      _messages.add({"role": "user", "text": text});
    });

    _searchController.clear();
    FocusScope.of(context).unfocus();

    final reply = await _sendToAgentica(text);

    setState(() {
      _messages.add({"role": "ai", "text": reply});
    });
    _scrollToBottom();
  }

  void _onSuggestionPressed(String suggestion) {
    setState(() {
      _showWelcomeCard = false;
      _messages.add({"role": "user", "text": suggestion});
    });
    _sendToAgentica(suggestion).then((reply) {
      setState(() {
        _messages.add({"role": "ai", "text": reply});
      });
      _scrollToBottom();
    });
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF5B9EE1) : const Color(0xFFE2EEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg["text"]!,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF1A1B1C),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Text(
                'AI 알리미',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1B1C),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 웰컴 카드
            if (_showWelcomeCard)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDFEFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/party_popper.png',
                        width: 86,
                        height: 86,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '청년알림E에 오신 것을\n환영합니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2530),
                      ),
                    ),
                  ],
                ),
              ),
            // 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            // 추천 질문들
            if (_showWelcomeCard)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '민생지원금 신청',
                    '청년 지원금 안내',
                    '일자리 정보',
                    '정책 문의',
                  ].map((suggestion) => GestureDetector(
                    onTap: () => _onSuggestionPressed(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A1B1C),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            
            // 검색 입력
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 8,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: '메시지를 입력하세요...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: const BorderSide(color: Color(0xFF5B9EE1)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _onCompletePressed(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _onCompletePressed,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5B9EE1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 네비게이션
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFFE2EEFF),
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, "홈", 0),
                _buildNavItem(Icons.star, "즐겨찾기", 1),
                const SizedBox(width: 60),
                _buildNavItem(Icons.calendar_today, "캘린더", 3),
                _buildNavItem(Icons.more_horiz, "더보기", 4),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _selectedIndex == 2 ? -12 : -7,
              child: GestureDetector(
                onTap: () => _onItemTapped(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedIndex == 2
                          ? const Color(0xFF6498E2)
                          : const Color(0xFFB0C9EE),
                      width: 5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/chat_bubble.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: _selectedIndex == 2
                            ? Colors.black
                            : const Color(0xFF888888),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "chat-bot",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _selectedIndex == 2
                              ? Colors.black
                              : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, isSelected ? -5 : 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : const Color(0xFF61646B),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : const Color(0xFF61646B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // 즐겨찾기 탭을 누르면 BookmarkScreen으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BookmarkScreen()),
      );
    } else if (index == 3) {
      // 캘린더 탭을 누르면 CalendarScreen으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CalendarScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
} 