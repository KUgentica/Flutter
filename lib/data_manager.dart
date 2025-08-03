import 'bookmark.dart';
import 'calendar.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // 즐겨찾기 목록
  final List<BookmarkItem> _bookmarks = [];
  
  // 캘린더 이벤트 목록
  final List<Event> _events = [];
  final Set<int> _deletedIds = {};

  Set<int> get deletedEventIds => _deletedIds; // calendar.dart에서 참조 가능
  // 즐겨찾기 목록 가져오기
  List<BookmarkItem> get bookmarks => List.unmodifiable(_bookmarks);
  
  // 캘린더 이벤트 목록 가져오기
  List<Event> get events => List.unmodifiable(_events);

  // 즐겨찾기 추가
  void addBookmark(BookmarkItem item) {
    // 중복 체크
    if (!_bookmarks.any((bookmark) => bookmark.id == item.id)) {
      _bookmarks.add(item);
    }
  }

  // 즐겨찾기 제거
  void removeBookmark(String id) {
    _bookmarks.removeWhere((bookmark) => bookmark.id == id);
    // 북마크와 관련된 삭제 처리만 포함
  }

  // 캘린더 이벤트 추가
  void addEvent(Event event) {
    // 중복 체크
    if (!_events.any((e) => e.id == event.id)) {
      _events.add(event);
    }
  }

  // 캘린더 이벤트 제거
  void removeEvent(int id) {
    _events.removeWhere((event) => event.id == id);
    _deletedIds.add(id); // 삭제 ID 기록
  }

  // 즐겨찾기 여부 확인
  bool isBookmarked(String id) {
    return _bookmarks.any((bookmark) => bookmark.id == id);
  }
  
  // 채팅 관련 상태 저장
  final List<Map<String, String>> _chatMessages = [];
  bool _showWelcomeCard = true;
  bool _isConnected = false;
  
  // 채팅 메시지 목록 가져오기
  List<Map<String, String>> get chatMessages => List.unmodifiable(_chatMessages);
  
  // 채팅 메시지 추가
  void addChatMessage(String role, String text) {
    _chatMessages.add({"role": role, "text": text});
    _showWelcomeCard = false;
  }
  
  // 채팅 메시지 목록 설정
  void setChatMessages(List<Map<String, String>> messages) {
    _chatMessages.clear();
    _chatMessages.addAll(messages);
    _showWelcomeCard = _chatMessages.isEmpty;
  }
  
  // 채팅 메시지 초기화
  void clearChatMessages() {
    _chatMessages.clear();
    _showWelcomeCard = true;
  }
  
  // 웰컴 카드 표시 여부
  bool get showWelcomeCard => _showWelcomeCard;
  
  // 연결 상태 설정
  void setConnectionStatus(bool isConnected) {
    _isConnected = isConnected;
  }
  
  // 연결 상태 가져오기
  bool get isConnected => _isConnected;
} 