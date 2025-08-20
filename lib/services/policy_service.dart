import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/policy.dart'; // ★ Policy 모델을 임포트합니다.

class PolicyService {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android 에뮬레이터용

  // 정책 검색 (반환 타입을 List<Policy>로 변경)
  static Future<List<Policy>> searchPolicies(String query) async {
    try {
      print('🔍 정책 검색 시도: $query');
      final url = Uri.parse('$baseUrl/policy/search?query=${Uri.encodeComponent(query)}');
      print('📡 요청 URL: $url');
      
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // ★ API 응답(Map)을 Policy 객체 목록으로 변환합니다.
        final List<Policy> policies = data.map((item) {
          // fromMap 팩토리 생성자를 사용하여 객체를 생성합니다.
          return Policy.fromMap(item);
        }).toList();
        
        print('✅ 정책 검색 성공! 결과 개수: ${policies.length}');
        return policies;
      } else {
        print('❌ 정책 검색 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return [];
    }
  }

  // 추천 정책 가져오기 (반환 타입을 List<Policy>로 변경)
  static Future<List<Policy>> getRecommendedPolicies() async {
    try {
      print('🔍 추천 정책 요청');
      final url = Uri.parse('$baseUrl/policy/recommended');
      print('📡 요청 URL: $url');
      
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // ★ API 응답(Map)을 Policy 객체 목록으로 변환합니다.
        final List<Policy> policies = data.map((item) => Policy.fromMap(item)).toList();
        
        print('✅ 추천 정책 성공! 결과 개수: ${policies.length}');
        return policies;
      } else {
        print('❌ 추천 정책 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return [];
    }
  }

  // 센터 검색 (이 메소드는 별도의 모델이 없으므로 기존 구조를 유지합니다)
  static Future<List<Map<String, dynamic>>> searchCenters(String query) async {
    try {
      print('🔍 센터 검색 시도: $query');
      final url = Uri.parse('$baseUrl/policy/search/centers?query=${Uri.encodeComponent(query)}');
      print('📡 요청 URL: $url');
      
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<Map<String, dynamic>> centers = List<Map<String, dynamic>>.from(data);
        
        print('✅ 센터 검색 성공! 결과 개수: ${centers.length}');
        return centers;
      } else {
        print('❌ 센터 검색 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return [];
    }
  }
}
