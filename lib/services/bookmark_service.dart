import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bookmarkItem.dart';
import '../models/policy.dart';
import '../models/calendarEvent.dart';
import 'auth_service.dart';

class BookmarkService {
  static const String baseUrl = AuthService.baseUrl;

  /// Fetches the user's bookmarks from the server.
  static Future<List<BookmarkItem>> getBookmarks() async {
    // ... (기존 코드와 동일, 변경 없음)
    try {
      final url = Uri.parse('$baseUrl/star/get');
      final response = await http.get(
        url,
        headers: await AuthService.getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> bookmarksData = jsonDecode(utf8.decode(response.bodyBytes));
        return bookmarksData.map((item) => BookmarkItem.fromServerMap(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveBookmark({
    required String itemId,
    required String itemType,
    required String title,
    required String description,
    String? deadline,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/star/save');

      final requestBody = {
        'itemId': itemId,
        'itemType': itemType,
        'title': title,
        'description': description,
        if (deadline != null && deadline.isNotEmpty) 'deadline': deadline, // 마감일이 있으면 추가
      };

      final response = await http.post(
        url,
        headers: await AuthService.getAuthHeaders(),
        body: jsonEncode(requestBody),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeBookmark(String itemId) async {
    try {
      final url = Uri.parse('$baseUrl/star/delete/$itemId');
      final response = await http.delete(
        url,
        headers: await AuthService.getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> togglePin(String itemId) async {
    try {
      final url = Uri.parse('$baseUrl/star/pin/$itemId');
      final response = await http.patch(
        url,
        headers: await AuthService.getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Fetches calendar events for a specific month and year.
  static Future<List<CalendarEvent>> getCalendarEvents(int year, int month) async {
    // ... (기존 코드와 동일, 변경 없음)
    try {
      final url = Uri.parse('$baseUrl/star/getCalendar/$year/$month');
      
      final response = await http.get(
        url,
        headers: await AuthService.getAuthHeaders(),
      );

      
      if (response.statusCode == 200) {
        final List<dynamic> eventsData = jsonDecode(utf8.decode(response.bodyBytes));

        final events = eventsData.map((item) => CalendarEvent.fromJson(item)).toList();
        for (var event in events) {
          print('   - ${event.title} (${event.date})');
        }
        
        return events;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}