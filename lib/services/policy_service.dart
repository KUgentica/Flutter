import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/policy.dart'; // ★ Policy 모델을 임포트합니다.

class PolicyService {
  static const String baseUrl = "http://13.125.176.46:8080"; // Android 에뮬레이터용

  // 정책 검색 (반환 타입을 List<Policy>로 변경)
  static Future<List<Policy>> searchPolicies(String query) async {
    try {
      final url = Uri.parse('$baseUrl/policy/search?query=${Uri.encodeComponent(query)}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        final List<Policy> policies = data.map((item) {
          return Policy.fromMap(item);
        }).toList();
        return policies;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 추천 정책 가져오기 (반환 타입을 List<Policy>로 변경)
  static Future<List<Policy>> getRecommendedPolicies() async {
    try {
      final url = Uri.parse('$baseUrl/policy/recommended');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        final List<Policy> policies = data.map((item) => Policy.fromMap(item)).toList();
        return policies;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 센터 검색 (이 메소드는 별도의 모델이 없으므로 기존 구조를 유지합니다)
  static Future<List<Map<String, dynamic>>> searchCenters(String query) async {
    try {
      final url = Uri.parse('$baseUrl/policy/search/centers?query=${Uri.encodeComponent(query)}');
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<Map<String, dynamic>> centers = List<Map<String, dynamic>>.from(data);
        return centers;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
