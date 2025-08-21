import 'package:calender_bookmark/models/calendarEvent.dart';

import 'bookmark.dart';
import 'calendar.dart';
import 'models/bookmarkItem.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  List<BookmarkItem> _bookmarks = [];
  
  final List<CalendarEvent> _events = [];
  final Set<int> _deletedIds = {};

  Set<int> get deletedEventIds => _deletedIds;

  final List<Map<String, String>> _chatMessages = [];
  bool _showWelcomeCard = true;
  bool _isConnected = false;
  
  List<Map<String, String>> get chatMessages => List.unmodifiable(_chatMessages);
  
  void addChatMessage(String role, String text) {
    _chatMessages.add({"role": role, "text": text});
    _showWelcomeCard = false;
  }
  
  void setChatMessages(List<Map<String, String>> messages) {
    _chatMessages.clear();
    _chatMessages.addAll(messages);
    _showWelcomeCard = _chatMessages.isEmpty;
  }
  
  void clearChatMessages() {
    _chatMessages.clear();
    _showWelcomeCard = true;
  }
  
  bool get showWelcomeCard => _showWelcomeCard;
  
  void setConnectionStatus(bool isConnected) {
    _isConnected = isConnected;
  }
  
  bool get isConnected => _isConnected;
} 