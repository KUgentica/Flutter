import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../bookmark.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart'; // Added missing import for Color

class BookmarkService {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android 에뮬레이터용
  // static const String baseUrl = 'http://172.20.10.8:8080'; // 실제 기기용 (컴퓨터 IP)
  
  // 현재 사용자 ID 가져오기
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email'); // 현재는 이메일을 ID로 사용
  }
  
  // 즐겨찾기 목록 가져오기
  static Future<List<BookmarkItem>> getBookmarks() async {
    try {
      final userId = await getCurrentUserId();
      print('🔍 즐겨찾기 목록 요청: userId=$userId');
      
      final url = '$baseUrl/bookmark/user/$userId';
      print('📡 요청 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: await AuthService.getAuthHeaders(),
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 헤더: ${response.headers}');
      
      if (response.statusCode == 200) {
        print('📥 응답 본문: ${response.body}');
        
        final responseData = jsonDecode(response.body);
        print('🔍 파싱된 응답 데이터: $responseData');
        print('🔍 응답 데이터 타입: ${responseData.runtimeType}');
        
        // 응답 구조 확인
        if (responseData is Map) {
          print('🔍 응답 키들: ${responseData.keys.toList()}');
          print('🔍 bookmarks 키 존재 여부: ${responseData.containsKey('bookmarks')}');
          if (responseData.containsKey('bookmarks')) {
            print('🔍 bookmarks 값: ${responseData['bookmarks']}');
            print('🔍 bookmarks 타입: ${responseData['bookmarks'].runtimeType}');
          }
        }
        
        // 올바른 경로로 데이터 추출
        List<dynamic> bookmarksData;
        if (responseData is Map && responseData.containsKey('bookmarks')) {
          bookmarksData = responseData['bookmarks'];
          print('✅ bookmarks 키에서 데이터 추출: ${bookmarksData.length}개');
        } else if (responseData is List) {
          bookmarksData = responseData;
          print('✅ 직접 List로 데이터 추출: ${bookmarksData.length}개');
        } else {
          print('❌ 예상치 못한 응답 구조: $responseData');
          return [];
        }
        
        print('🔍 즐겨찾기 데이터 개수: ${bookmarksData.length}');
        
        final bookmarks = bookmarksData.map<BookmarkItem>((item) {
          print('🔍 DB 응답 아이템: title=${item['title']}, pinned=${item['pinned']}, pinned 타입=${item['pinned']?.runtimeType}');
          print('🔍 전체 아이템 데이터: $item');
          
          // pinned 필드를 isPinned로 매핑
          final isPinned = item['pinned'] ?? item['isPinned'] ?? false;
          print('🔍 매핑된 isPinned: $isPinned, 타입: ${isPinned.runtimeType}');
          
          return BookmarkItem(
            title: item['title'] ?? '제목 없음',
            description: item['description'] ?? '설명 없음',
            time: item['time'] ?? '시간 없음',
            id: item['id'] ?? item['policyId'] ?? '',
            userId: item['userId'] ?? userId,
            policyId: item['policyId'] ?? item['id'] ?? '', // policyId 추가
            isPinned: isPinned, // pinned 필드 사용
            detailData: BookmarkDetailData(
              title: item['title'] ?? '제목 없음',
              bannerTitle: item['bannerTitle'] ?? '',
              bannerSubtitle: item['bannerSubtitle'] ?? '',
              description: item['description'] ?? '설명 없음',
              leftAmount: item['leftAmount'] ?? '',
              rightAmount: item['rightAmount'] ?? '',
              leftColor: _parseColor(item['leftColor']),
              rightColor: _parseColor(item['rightColor']),
            ),
          );
        }).toList();
        
        print('✅ 즐겨찾기 목록 성공! 결과 개수: ${bookmarks.length}');
        return bookmarks;
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        print('❌ 오류 응답: ${response.body}');
        return [];
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return [];
    }
  }
  
  // 즐겨찾기 추가
  static Future<bool> addBookmark(BookmarkItem bookmark) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        print('❌ 사용자 ID가 없습니다. 로그인이 필요합니다.');
        return false;
      }
      
      print('🔍 즐겨찾기 추가: title=${bookmark.title}, userId=$userId');
      print('📡 요청 URL: $baseUrl/bookmark/add');
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookmark/add'),
        headers: await AuthService.getAuthHeaders(),
        body: jsonEncode({
          'userId': userId,
          'policyId': bookmark.id,
          'title': bookmark.title,
          'description': bookmark.description,
          'time': bookmark.time,
          'isPinned': bookmark.isPinned,
          'category': bookmark.detailData.bannerTitle,
          'amount': bookmark.detailData.leftAmount,
          'deadline': bookmark.detailData.rightAmount,
        }),
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ 즐겨찾기 추가 성공!');
        return true;
      } else {
        print('❌ 즐겨찾기 추가 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return false;
    }
  }
  
  // 즐겨찾기 제거
  static Future<bool> removeBookmark(String policyId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        print('❌ 사용자 ID가 없습니다. 로그인이 필요합니다.');
        return false;
      }
      
      print('🔍 즐겨찾기 제거: policyId=$policyId, userId=$userId');
      print('📡 요청 URL: $baseUrl/bookmark/remove');
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookmark/remove'),
        headers: await AuthService.getAuthHeaders(),
        body: jsonEncode({
          'userId': userId,
          'policyId': policyId,
        }),
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ 즐겨찾기 제거 성공!');
        return true;
      } else {
        print('❌ 즐겨찾기 제거 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return false;
    }
  }
  
  // 즐겨찾기 핀 상태 토글
  static Future<bool> togglePin(String policyId, bool isPinned) async {
    try {
      print('🔍 즐겨찾기 핀 토글: policyId=$policyId, isPinned=$isPinned');
      print('📡 요청 URL: $baseUrl/bookmark/toggle-pin');
      
      final response = await http.post(
        Uri.parse('$baseUrl/bookmark/toggle-pin'),
        headers: await AuthService.getAuthHeaders(),
        body: jsonEncode({
          'policyId': policyId,
          'isPinned': isPinned,
        }),
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ 즐겨찾기 핀 토글 성공!');
        return true;
      } else {
        print('❌ 즐겨찾기 핀 토글 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return false;
    }
  }
  
  // 색상 파싱 헬퍼
  static Color _parseColor(dynamic colorData) {
    if (colorData == null) return Colors.grey;
    if (colorData is String) {
      // 색상 이름이나 hex 코드 처리
      switch (colorData.toLowerCase()) {
        case 'blue': return Colors.blue;
        case 'green': return Colors.green;
        case 'red': return Colors.red;
        case 'orange': return Colors.orange;
        case 'purple': return Colors.purple;
        case 'pink': return Colors.pink;
        case 'teal': return Colors.teal;
        case 'cyan': return Colors.cyan;
        case 'amber': return Colors.amber;
        case 'indigo': return Colors.indigo;
        default: return Colors.grey;
      }
    }
    return Colors.grey;
  }
}
