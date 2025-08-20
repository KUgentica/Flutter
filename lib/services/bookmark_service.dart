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
      print('💥 Error getting bookmarks: $e');
      return [];
    }
  }

  /// ⭐️ [수정됨] 즐겨찾기를 저장합니다.
  /// 이제 Policy 객체 대신 itemId, itemType 등 필요한 정보만 받습니다.
  static Future<bool> saveBookmark({
    required String itemId,
    required String itemType,
    required String title,
    required String description,
    String? deadline, // 마감일 정보 추가
  }) async {
    try {
      final url = Uri.parse('$baseUrl/star/save');
      print('📡 Saving bookmark to: $url');
      print('📋 북마크 데이터:');
      print('   - itemId: $itemId');
      print('   - itemType: $itemType');
      print('   - title: $title');
      print('   - description: ${description.length > 50 ? '${description.substring(0, 50)}...' : description}');
      print('   - deadline: ${deadline ?? 'null'} (길이: ${deadline?.length ?? 0})');

      // ⭐️ 백엔드의 SaveBookmarkRequest DTO에 맞는 형태로 body 구성
      final requestBody = {
        'itemId': itemId,
        'itemType': itemType,
        'title': title,
        'description': description,
        if (deadline != null && deadline.isNotEmpty) 'deadline': deadline, // 마감일이 있으면 추가
      };

      print('📤 전송할 requestBody: $requestBody');

      final response = await http.post(
        url,
        headers: await AuthService.getAuthHeaders(),
        body: jsonEncode(requestBody),
      );

      print('📥 Save Bookmark Response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      // 201 Created 또는 200 OK 등 성공 상태 코드를 확인
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('💥 Error saving bookmark: $e');
      return false;
    }
  }


  /// Removes a bookmark.
  static Future<bool> removeBookmark(String itemId) async {
    // ... (기존 코드와 동일, policyId를 itemId로 사용하는 것이 좋음)
    try {
      final url = Uri.parse('$baseUrl/star/delete/$itemId');
      final response = await http.delete(
        url,
        headers: await AuthService.getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('💥 Error deleting bookmark: $e');
      return false;
    }
  }

  /// Toggles the pin status of a bookmark.
  static Future<bool> togglePin(String itemId) async {
    // ... (기존 코드와 동일, policyId를 itemId로 사용하는 것이 좋음)
    try {
      final url = Uri.parse('$baseUrl/star/pin/$itemId');
      final response = await http.patch(
        url,
        headers: await AuthService.getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('💥 Error toggling pin: $e');
      return false;
    }
  }
  
  /// Fetches calendar events for a specific month and year.
  static Future<List<CalendarEvent>> getCalendarEvents(int year, int month) async {
    // ... (기존 코드와 동일, 변경 없음)
    try {
      final url = Uri.parse('$baseUrl/star/getCalendar/$year/$month');
      print('📅 캘린더 이벤트 요청: $year년 $month월');
      print('📡 요청 URL: $url');
      
      final response = await http.get(
        url,
        headers: await AuthService.getAuthHeaders(),
      );
      
      print('📥 캘린더 이벤트 응답: ${response.statusCode}');
      print('📥 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> eventsData = jsonDecode(utf8.decode(response.bodyBytes));
        print('📊 파싱된 이벤트 데이터: $eventsData');
        
        final events = eventsData.map((item) => CalendarEvent.fromJson(item)).toList();
        print('✅ 최종 이벤트 목록: ${events.length}개');
        for (var event in events) {
          print('   - ${event.title} (${event.date})');
        }
        
        return events;
      }
      return [];
    } catch (e) {
      print('💥 Error getting calendar events: $e');
      return [];
    }
  }
}