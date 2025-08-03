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
} 