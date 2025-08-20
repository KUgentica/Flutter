import 'bookmark.dart';
import 'calendar.dart';
import 'services/bookmark_service.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // 즐겨찾기 목록 (DB에서 로드)
  List<BookmarkItem> _bookmarks = [];
  
  // 캘린더 이벤트 목록
  final List<Event> _events = [];
  final Set<int> _deletedIds = {};

  Set<int> get deletedEventIds => _deletedIds; // calendar.dart에서 참조 가능
  
  // 즐겨찾기 목록 가져오기 (DB에서 로드)
  Future<List<BookmarkItem>> get bookmarks async {
    print('🔍 DataManager.bookmarks 호출됨: _bookmarks.length = ${_bookmarks.length}');
    
    if (_bookmarks.isEmpty) {
      print('📡 DB에서 즐겨찾기 로드 중...');
      print('📡 _loadBookmarksFromDB() 호출 시작...');
      await _loadBookmarksFromDB();
      print('✅ _loadBookmarksFromDB() 호출 완료');
      print('✅ DB에서 즐겨찾기 로드 완료: _bookmarks.length = ${_bookmarks.length}');
    } else {
      print('📡 로컬 캐시에서 즐겨찾기 사용: _bookmarks.length = ${_bookmarks.length}');
    }
    
    // 로컬 캐시의 각 아이템 상태 확인
    for (int i = 0; i < _bookmarks.length; i++) {
      print('🔍 로컬 캐시 아이템 $i: title=${_bookmarks[i].title}, isPinned=${_bookmarks[i].isPinned}');
    }
    
    return List.unmodifiable(_bookmarks);
  }
  
  // DB에서 즐겨찾기 로드
  Future<void> _loadBookmarksFromDB() async {
    try {
      print('📡 _loadBookmarksFromDB() 시작');
      print('📡 BookmarkService.getBookmarks() 호출 중...');
      print('📡 BookmarkService.getBookmarks() 호출 전...');
      
      final dbBookmarks = await BookmarkService.getBookmarks();
      
      print('📡 BookmarkService.getBookmarks() 호출 완료');
      print('✅ DB에서 받은 즐겨찾기: ${dbBookmarks.length}개');
      
      // DB에서 받은 각 아이템의 isPinned 상태 확인
      for (int i = 0; i < dbBookmarks.length; i++) {
        final bookmark = dbBookmarks[i];
        print('🔍 DB에서 받은 아이템 $i: title=${bookmark.title}, isPinned=${bookmark.isPinned}, isPinned 타입=${bookmark.isPinned.runtimeType}');
      }
      
      // DB 데이터로 로컬 캐시 완전 교체
      print('🔄 로컬 캐시 교체 시작...');
      _bookmarks.clear();
      print('🔄 로컬 캐시 클리어 완료');
      _bookmarks.addAll(dbBookmarks);
      print('🔄 로컬 캐시에 DB 데이터 추가 완료');
      
      print('🔄 로컬 캐시 업데이트 완료: _bookmarks.length = ${_bookmarks.length}');
      
      // isPinned 상태 확인
      final pinnedCount = _bookmarks.where((b) => b.isPinned).length;
      print('📌 핀된 즐겨찾기: $pinnedCount개');
      
      // 로컬 캐시의 각 아이템 상태 재확인
      for (int i = 0; i < _bookmarks.length; i++) {
        print('🔍 로컬 캐시 업데이트 후 아이템 $i: title=${_bookmarks[i].title}, isPinned=${_bookmarks[i].isPinned}');
      }
      
    } catch (e) {
      print('💥 즐겨찾기 로드 실패: $e');
      print('💥 오류 스택 트레이스: ${StackTrace.current}');
      _bookmarks = [];
    }
  }
  
  // 캘린더 이벤트 목록 가져오기
  List<Event> get events => List.unmodifiable(_events);

  // 즐겨찾기 추가 (DB에 저장)
  Future<void> addBookmark(BookmarkItem item) async {
    try {
      final success = await BookmarkService.addBookmark(item);
      if (success) {
        // DB 저장 성공 시 로컬 목록에 추가
        if (!_bookmarks.any((bookmark) => bookmark.id == item.id)) {
          _bookmarks.add(item);
        }
        print('즐겨찾기 추가 성공: ${item.title}');
      } else {
        print('즐겨찾기 추가 실패: ${item.title}');
      }
    } catch (e) {
      print('즐겨찾기 추가 중 오류: $e');
    }
  }

  // 즐겨찾기 제거 (DB에서 삭제)
  Future<void> removeBookmark(String id) async {
    try {
      print('🗑️ DataManager.removeBookmark 호출: id=$id');
      
      // 해당 즐겨찾기 항목 찾기
      final bookmark = _bookmarks.firstWhere((b) => b.id == id);
      print('🔍 삭제할 즐겨찾기: ${bookmark.title}, policyId: ${bookmark.policyId}');
      
      final success = await BookmarkService.removeBookmark(bookmark.policyId);
      if (success) {
        // DB 삭제 성공 시 로컬 목록에서 제거
        _bookmarks.removeWhere((bookmark) => bookmark.id == id);
        print('✅ 즐겨찾기 제거 성공: $id (policyId: ${bookmark.policyId})');
      } else {
        print('❌ 즐겨찾기 제거 실패: $id (policyId: ${bookmark.policyId})');
      }
    } catch (e) {
      print('💥 즐겨찾기 제거 중 오류: $e');
    }
  }

  // 즐겨찾기 핀 상태 토글 (DB에 업데이트)
  Future<void> toggleBookmarkPin(String id, bool isPinned) async {
    try {
      print('📌 DataManager.toggleBookmarkPin 호출: id=$id, isPinned=$isPinned');
      
      final success = await BookmarkService.togglePin(id, isPinned);
      if (success) {
        print('✅ BookmarkService.togglePin 성공');
        
        // DB 업데이트 성공 시 로컬 목록만 업데이트 (새로고침 안함)
        final bookmark = _bookmarks.firstWhere((b) => b.id == id);
        bookmark.isPinned = isPinned;
        
        print('🔄 로컬 상태 업데이트 완료: $id, isPinned: $isPinned');
        
        // isPinned 상태 확인
        final pinnedCount = _bookmarks.where((b) => b.isPinned).length;
        print('📌 핀된 즐겨찾기: $pinnedCount개');
        
      } else {
        print('❌ BookmarkService.togglePin 실패');
      }
    } catch (e) {
      print('💥 즐겨찾기 핀 토글 중 오류: $e');
    }
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

  // 즐겨찾기 여부 확인 (DB에서 실시간 확인)
  Future<bool> isBookmarked(String id) async {
    try {
      // 로컬 목록에서 먼저 확인
      if (_bookmarks.any((bookmark) => bookmark.id == id)) {
        return true;
      }
      
      // 로컬에 없으면 DB에서 확인
      final currentUserId = await BookmarkService.getCurrentUserId();
      if (currentUserId != null) {
        // DB에서 즐겨찾기 목록을 새로 로드하여 확인
        await _loadBookmarksFromDB();
        return _bookmarks.any((bookmark) => bookmark.id == id);
      }
      return false;
    } catch (e) {
      print('즐겨찾기 상태 확인 오류: $e');
      return false;
    }
  }
  
  // 즐겨찾기 새로고침 (DB에서 다시 로드)
  Future<void> refreshBookmarks() async {
    await _loadBookmarksFromDB();
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