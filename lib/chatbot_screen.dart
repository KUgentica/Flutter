import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'bookmark.dart';
import 'calendar.dart';
import 'common_bottom_navigation.dart';

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
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;

  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  /// 🔌 WebSocket 연결
  void _connectWebSocket() {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    const String serverUrl = 'ws://10.0.2.2:3000';
    print('🔌 WebSocket 연결 시도: $serverUrl');

    try {
      _channel = IOWebSocketChannel.connect(serverUrl);

      _channel!.stream.listen(
        _handleServerMessage,
        onError: (error) {
          print('❌ WebSocket 에러: $error');
          _onConnectionLost();
        },
        onDone: () {
          print('⚠️ WebSocket 연결 종료');
          _onConnectionLost();
        },
      );

      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _reconnectAttempts = 0;
        });
      }

      print('✅ WebSocket 연결 성공');
    } catch (e) {
      print('❌ WebSocket 연결 실패: $e');
      _onConnectionLost();
    }
  }

  /// 🚨 연결 끊김 시 처리
  void _onConnectionLost() {
    if (!mounted) return;
    
    setState(() {
      _isConnected = false;
      _isConnecting = false;
    });

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      print('🔄 재연결 시도 $_reconnectAttempts/$maxReconnectAttempts');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _connectWebSocket();
      });
    } else {
      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": "서버 연결이 불안정합니다. 앱을 다시 시작해주세요."});
        });
      }
    }
  }

  /// 📩 서버 메시지 처리
  void _handleServerMessage(dynamic message) {
    print('📨 서버 응답: $message');

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map && decoded.containsKey("result")) {
        _addMessage("ai", decoded["result"].toString());
        return;
      }
    } catch (_) {
      // JSON이 아닐 경우 그냥 문자열로 출력
    }

    _addMessage("ai", message.toString());
  }

  /// 📤 메시지 전송
  Future<void> _sendToAgentica(String message) async {
    if (!_isConnected || _channel == null) {
      _addMessage("ai", "서버에 연결되지 않았습니다.");
      return;
    }

    final rpcMsg = {
      "target": "chat",
      "method": "send",
      "parameters": {"message": message},
    };

    try {
      final jsonMsg = jsonEncode(rpcMsg);
      print('📤 전송할 메시지: $jsonMsg');
      _channel!.sink.add(jsonMsg);
    } catch (e) {
      print('❌ 메시지 전송 오류: $e');
      _addMessage("ai", "메시지 전송에 실패했습니다.");
    }
  }

  /// 💬 메시지 리스트에 추가
  void _addMessage(String role, String text) {
    if (!mounted) return;
    
    setState(() {
      _showWelcomeCard = false;
      _messages.add({"role": role, "text": text});
    });
    _scrollToBottom();
  }

  /// ⬇️ 스크롤 맨 아래로 이동
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

  /// 완료 버튼 클릭
  void _onCompletePressed() {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    _searchController.clear();
    FocusScope.of(context).unfocus();
    _addMessage("user", text);
    _sendToAgentica(text);
  }

  /// 추천 질문 클릭
  void _onSuggestionPressed(String suggestion) {
    _addMessage("user", suggestion);
    _sendToAgentica(suggestion);
  }

  /// 🧱 메시지 UI
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
          msg["text"] ?? "",
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _focusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'AI 알리미',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected
                            ? Colors.green
                            : _isConnecting
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnected
                          ? '연결됨'
                          : _isConnecting
                          ? '연결 중...'
                          : '연결 안됨',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isConnected
                            ? Colors.green
                            : _isConnecting
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_showWelcomeCard) ...[
                  _buildWelcomeCard(),
                  const SizedBox(height: 10),
                ],

                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 150),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(_messages[index]),
                  ),
                ),
              ],
            ),
            if (_showWelcomeCard) _buildSuggestions(),
            _buildInputField(),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          NavigationHelper.navigateToScreen(context, index);
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
              'assets/images/party_icon.png',
              width: 86,
              height: 86,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '청년알림E와 대화를 시작해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A2530),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 75,
      child: Column(
        children: [
                      Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildSuggestionChip("일자리"),
                _buildSuggestionChip("주거"),
                _buildSuggestionChip("교육"),
                _buildSuggestionChip("창업"),
                _buildSuggestionChip("혜택"),
                _buildSuggestionChip("지원"),
                _buildSuggestionChip("금융"),
                _buildSuggestionChip("문화"),
                _buildSuggestionChip("건강"),
                _buildSuggestionChip("환경"),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _onSuggestionPressed(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 15,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  focusNode: _focusNode,
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "무엇이 궁금하신가요?",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _onCompletePressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9EE1),
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: const Text(
                    "완료",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}