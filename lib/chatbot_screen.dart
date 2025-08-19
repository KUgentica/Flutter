import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'common_bottom_navigation.dart';

// ⬇️ 링크 클릭을 위해 추가
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 로그인 상태 확인용
import 'services/auth_service.dart'; // MongoDB 저장을 위해 추가

// const String _kChatStoreKey = 'chat_messages_v1'; // 로컬 저장 키 제거


class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with TickerProviderStateMixin {
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

  // 완료 버튼 터치 효과
  bool _isPressed = false;

  // 메시지 애니메이션을 위한 변수들
  final List<bool> _messageAnimations = [];

  // 연결 상태 애니메이션
  late AnimationController _connectionController;
  late Animation<double> _connectionRotation;

  WebSocketChannel? _channel;

  // 폭죽 아이콘 애니메이션
  late AnimationController _partyIconController;
  late Animation<double> _partyIconScale;

  // 키워드 애니메이션 컨트롤러들
  late List<AnimationController> _keywordControllers;
  late List<Animation<double>> _keywordAnimations;

  @override
  void initState() {
    super.initState();
    _initializePartyIconAnimation();
    _initializeConnectionAnimation();
    _loadChatFromMongoDB(); // MongoDB에서 채팅 로드
    _connectWebSocket();
  }

  void _initializePartyIconAnimation() {
    _partyIconController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _partyIconScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _partyIconController, curve: Curves.elasticOut),
    );

    // 애니메이션 자동 반복
    _partyIconController.repeat(reverse: true);

    // 키워드 애니메이션 초기화
    _initializeKeywordAnimations();
  }

  void _initializeKeywordAnimations() {
    _keywordControllers = [];
    _keywordAnimations = [];

    for (int i = 0; i < 10; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 2000 + (i * 200)),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _keywordControllers.add(controller);
      _keywordAnimations.add(animation);

      // 각 키워드마다 다른 타이밍으로 반복 애니메이션
      controller.repeat();
    }
  }

  void _initializeConnectionAnimation() {
    _connectionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _connectionRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _connectionController, curve: Curves.linear),
    );
  }

  /// 🔌 WebSocket 연결
  void _connectWebSocket() {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    const String serverUrl = 'ws://10.0.2.2:3000';

    try {
      _channel = IOWebSocketChannel.connect(serverUrl);

      _channel!.stream.listen(
        _handleServerMessage,
        onError: (error) {
          _onConnectionLost();
        },
        onDone: () {
          _onConnectionLost();
        },
      );

      if (mounted) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _reconnectAttempts = 0;
        });
        // 연결 성공 시 회전 애니메이션 시작
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _connectionController.repeat();
        });
      }
    } catch (e) {
      _onConnectionLost();
    }
  }

  /// 🚨 연결 끊김 시 처리
  void _onConnectionLost() {
    if (!mounted) return;

    // 연결 끊김 시 회전 애니메이션 중지
    _connectionController.stop();

    setState(() {
      _isConnected = false;
      _isConnecting = false;
    });

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _connectWebSocket();
      });
    } else {
      if (mounted) {
        _addMessage("ai", "서버 연결이 불안정합니다. 앱을 다시 시작해주세요.");
      }
    }
  }

  /// 📩 서버 메시지 처리
  void _handleServerMessage(dynamic message) {
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
      _channel!.sink.add(jsonMsg);
    } catch (e) {
      _addMessage("ai", "메시지 전송에 실패했습니다.");
    }
  }

  Future<void> _loadChatFromMongoDB() async {
    try {
      final messages = await AuthService.getMessages();
      if (messages.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);

          // 2) 애니메이션 플래그 길이 맞추기(길이 불일치로 렌더가 스킵되는 문제 방지)
          _messageAnimations
            ..clear()
            ..addAll(List<bool>.filled(_messages.length, true));

          // 3) 웰컴 카드 숨김
          _showWelcomeCard = _messages.isEmpty;
        });

        // 4) 스크롤 맨 아래로
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        debugPrint('[Chatbot] restored ${_messages.length} msgs from MongoDB');
      }
    } catch (e) {
      debugPrint('[Chatbot] restore error: $e');
    }
  }


  Future<void> _saveChatToMongoDB(String role, String text) async {
    try {
      await AuthService.addMessage(role, text);
      debugPrint('[Chatbot] saved message to MongoDB');
    } catch (e) {
      debugPrint('[Chatbot] save to MongoDB error: $e');
    }
  }


  /// 💬 메시지 리스트에 추가
  void _addMessage(String role, String text) {
    if (!mounted) return;

    setState(() {
      _showWelcomeCard = false;
      _messages.add({"role": role, "text": text});
      _messageAnimations.add(false);
    });

    _saveChatToMongoDB(role, text);  // ✅ 저장

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (_messageAnimations.isNotEmpty) {
          _messageAnimations[_messageAnimations.length - 1] = true;
        }
      });
      _scrollToBottom();
    });
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

  // ⬇️ AI 메시지(링크/마크다운 or 정책카드) 렌더러
  Widget _buildAssistantRich(String text, {TextStyle? baseStyle}) {
    // 마크다운 링크가 있으면 Markdown으로 처리
    final hasMarkdownLink = RegExp(
      r'\[(.*?)\]\((https?:\/\/[^\s)]+)\)',
    ).hasMatch(text);
    if (hasMarkdownLink) {
      return MarkdownBody(
        data: text,
        selectable: true,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet(
          p: baseStyle ?? const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        onTapLink: (_, href, __) async {
          if (href == null) return;
          await launchUrlString(href, mode: LaunchMode.externalApplication);
        },
      );
    }

    // 일반 URL만 있으면 Linkify로 자동 링크화
    final hasUrl = RegExp(r'https?://').hasMatch(text);
    if (hasUrl) {
      return Linkify(
        text: text,
        options: const LinkifyOptions(humanize: false),
        onOpen: (link) async {
          final uri = Uri.parse(link.url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        style:
        baseStyle ?? const TextStyle(fontSize: 14, color: Colors.black87),
        linkStyle: const TextStyle(decoration: TextDecoration.underline),
      );
    }

    // 링크 없으면 기본 Text
    return Text(
      text,
      style: baseStyle ?? const TextStyle(fontSize: 14, color: Colors.black87),
    );
  }

  // ⬇️ 정책카드 JSON이면 카드로, 아니면 기존 텍스트로
  Widget _buildAiMessageOrCards(String text) {
    try {
      final obj = jsonDecode(text);
      if (obj is Map && obj["type"] == "policy_cards" && obj["items"] is List) {
        final items = (obj["items"] as List)
            .map(
              (e) =>
              PolicyCardModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
            .toList();
        if (items.isNotEmpty) {
          return PolicyCardsMessage(items: items, previewCount: 3);
        }
      }
    } catch (_) {
      // JSON 아님 → 기존 렌더
    }
    return _buildAssistantRich(
      text,
      baseStyle: const TextStyle(color: Colors.black87, fontSize: 14),
    );
  }

  /// 🧱 메시지 UI
  Widget _buildMessage(Map<String, String> msg, int index) {
    final isUser = msg["role"] == "user";
    final isAnimated =
        index < _messageAnimations.length && _messageAnimations[index];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: isAnimated ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(
          isAnimated ? 0 : (isUser ? 50 : -50),
          0,
          0,
        ),
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF5B9EE1).withValues(alpha: 0.8)
                  : const Color(0xFFE2EEFF).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // ⬇️ 여기 변경: AI 메시지에 카드 렌더 적용
            child: isUser
                ? Text(
              msg["text"] ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            )
                : _buildAiMessageOrCards(msg["text"] ?? ""),
          ),
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
    _partyIconController.dispose();
    _connectionController.dispose();

    // 키워드 애니메이션 컨트롤러들 해제
    for (final controller in _keywordControllers) {
      controller.dispose();
    }

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
                    AnimatedBuilder(
                      animation: _connectionRotation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _isConnected
                              ? _connectionRotation.value * 2 * pi
                              : 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isConnected
                                  ? Colors.green
                                  : _isConnecting
                                  ? Colors.orange
                                  : Colors.red,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  (_isConnected
                                      ? Colors.green
                                      : _isConnecting
                                      ? Colors.orange
                                      : Colors.red)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                        _buildMessage(_messages[index], index),
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
          AnimatedBuilder(
            animation: _partyIconScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _partyIconScale.value,
                child: Container(
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
              );
            },
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
              _buildAnimatedSuggestionChip("일자리", 0),
              _buildAnimatedSuggestionChip("주거", 1),
              _buildAnimatedSuggestionChip("교육", 2),
              _buildAnimatedSuggestionChip("창업", 3),
              _buildAnimatedSuggestionChip("혜택", 4),
              _buildAnimatedSuggestionChip("지원", 5),
              _buildAnimatedSuggestionChip("금융", 6),
              _buildAnimatedSuggestionChip("문화", 7),
              _buildAnimatedSuggestionChip("건강", 8),
              _buildAnimatedSuggestionChip("환경", 9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSuggestionChip(String text, int index) {
    return AnimatedBuilder(
      animation: _keywordAnimations[index],
      builder: (context, child) {
        // 사인 함수를 사용해서 위아래로 움직이는 애니메이션
        final value = _keywordAnimations[index].value;
        final offset = sin(value * 2 * pi) * 4.0; // 4픽셀 위아래 움직임

        return Transform.translate(
          offset: Offset(0, offset),
          child: _buildSuggestionChip(text),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSuggestionPressed(text),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
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
                  decoration: InputDecoration(
                    hintText: "무엇이 궁금하신가요?",
                    prefixIcon: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('대화내용 삭제'),
                            content: const Text('대화내용을 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        if (result == true) {
                          setState(() {
                            _messages.clear();
                            _messageAnimations.clear();
                            _showWelcomeCard = true;
                          });
                          // 서버(chat 컬렉션)에서도 삭제
                          await AuthService.clearChatMessages();
                        }
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: _onCompletePressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(
                    0,
                    _isPressed ? -2 : 0,
                    0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9EE1),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF5B9EE1,
                        ).withValues(alpha: _isPressed ? 0.5 : 0.3),
                        blurRadius: _isPressed ? 15 : 8,
                        offset: Offset(0, _isPressed ? 6 : 2),
                      ),
                    ],
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      fontSize: _isPressed ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    child: const Text("완료"),
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

// ================== 아래부터: 정책 카드 UI 모듈 ==================

class PolicyCardModel {
  final String id;
  final String title;
  final String summary;
  final String region;
  final String period;
  final String ageRange;
  final String incomeRange;
  final String supportScale;
  final String link;

  PolicyCardModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.region,
    required this.period,
    required this.ageRange,
    required this.incomeRange,
    required this.supportScale,
    required this.link,
  });

  factory PolicyCardModel.fromJson(Map<String, dynamic> j) => PolicyCardModel(
    id: (j['id'] ?? '').toString(),
    title: (j['title'] ?? '').toString(),
    summary: (j['summary'] ?? '').toString(),
    region: (j['region'] ?? '전국').toString(),
    period: (j['period'] ?? '정보 없음').toString(),
    ageRange: (j['ageRange'] ?? '제한 없음').toString(),
    incomeRange: (j['incomeRange'] ?? '제한 없음').toString(),
    supportScale: (j['supportScale'] ?? '정보 없음').toString(),
    link: (j['link'] ?? '').toString(),
  );
}

class PolicyCardsMessage extends StatelessWidget {
  final List<PolicyCardModel> items;
  final int previewCount;

  const PolicyCardsMessage({
    super.key,
    required this.items,
    this.previewCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final display = items.take(previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in display) ...[
          _PolicyPreviewCard(
            data: p,
            onTap: () => _showPolicyDetailSheet(context, p),
          ),
          const SizedBox(height: 8),
        ],
        if (items.length > previewCount)
          Text(
            '외 ${items.length - previewCount}건 더 있음 · 키워드로 다시 물어보면 더 좁혀드려요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
      ],
    );
  }

  void _showPolicyDetailSheet(BuildContext context, PolicyCardModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ListView(
                controller: controller,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Color(0xFF5B9EE1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '정책 정보',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Labeled('한 눈에 보는 정책 요약', p.summary),
                  const SizedBox(height: 12),
                  _SectionDivider(),
                  _Labeled('신청 기간', p.period),
                  _Labeled('지역', p.region),
                  _Labeled('연령', p.ageRange),
                  _Labeled('소득', p.incomeRange),
                  _Labeled('지원 규모', p.supportScale),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: p.link.isEmpty
                        ? null
                        : () => launchUrlString(
                      p.link,
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('자세히 보기 / 신청하기'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PolicyPreviewCard extends StatelessWidget {
  final PolicyCardModel data;
  final VoidCallback onTap;

  const _PolicyPreviewCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2EEFF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태/분야 칩 느낌(지역 표기)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2EEFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.region,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.period,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final String value;
  const _Labeled(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '정보 없음' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Divider(
      height: 1,
      thickness: 1,
      color: Colors.black.withOpacity(0.06),
    ),
  );
}
