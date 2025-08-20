import 'dart:convert';
import 'package:http/http.dart' as http;

class PolicyService {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android 에뮬레이터용
  // static const String baseUrl = 'http://172.20.10.8:8080'; // 실제 기기용 (컴퓨터 IP)
  
  // 정책 검색
  static Future<List<Map<String, dynamic>>> searchPolicies(String query) async {
    try {
      print('🔍 정책 검색 시도: $query');
      print('📡 요청 URL: $baseUrl/policy/search?query=$query');
      
      final response = await http.get(
        Uri.parse('$baseUrl/policy/search?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> policies = data.map((item) {
          return {
            'id': item['id'],
            'title': item['plcyTitle'] ?? '제목 없음',
            'description': item['plcyExplnCn'] ?? '설명 없음',
            'category': item['plcyKywdNm'] ?? '카테고리 없음',
            'aplyYmd': item['aplyYmd'] ?? '',
            'deadline': item['aplyYmd'] ?? '기한 없음',
            'zipCd': item['zipCd'] ?? '',
            'location': item['zipCd'] ?? '지역 없음',
            'amount': _formatAmount(item['earnMinAmt'], item['earnMaxAmt']),
            'minAge': item['sprtTrgtMinAge'],
            'maxAge': item['sprtTrgtMaxAge'],
            'applyMethod': item['plcyAplyMthdCn'],
            'applyUrl': item['aplyUrlAddr'],
            'refUrl1': item['refUrlAddr1'],
            'refUrl2': item['refUrlAddr2'],
            // 원본 주요 필드도 함께 유지
            'plcyKywdNm': item['plcyKywdNm'],
          };
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
  
  // 센터 검색
  static Future<List<Map<String, dynamic>>> searchCenters(String query) async {
    try {
      print('🔍 센터 검색 시도: $query');
      print('📡 요청 URL: $baseUrl/policy/search/centers?query=$query');
      
      final response = await http.get(
        Uri.parse('$baseUrl/policy/search/centers?query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> centers = data.map((item) {
          return {
            'id': item['id'],
            'name': item['cntrNm'] ?? '센터명 없음',
            'address': item['cntrAddr'] ?? '주소 없음',
            'detailAddress': item['cntrDaddr'] ?? '',
            'phone': item['cntrTelno'] ?? '전화번호 없음',
            'url': item['cntrUrlAddr'] ?? '',
          };
        }).toList();
        
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
  
  // 추천 정책 가져오기
  static Future<List<Map<String, dynamic>>> getRecommendedPolicies() async {
    try {
      print('🔍 추천 정책 요청');
      print('📡 요청 URL: $baseUrl/policy/recommended');
      
      final response = await http.get(
        Uri.parse('$baseUrl/policy/recommended'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> policies = data.map((item) {
          return {
            'id': item['id'],
            'title': item['plcyTitle'] ?? '제목 없음',
            'description': item['plcyExplnCn'] ?? '설명 없음',
            'category': item['plcyKywdNm'] ?? '카테고리 없음',
            'deadline': item['aplyYmd'] ?? '기한 없음',
            'location': item['zipCd'] ?? '지역 없음',
            'amount': _formatAmount(item['earnMinAmt'], item['earnMaxAmt']),
            'minAge': item['sprtTrgtMinAge'],
            'maxAge': item['sprtTrgtMaxAge'],
            'applyMethod': item['plcyAplyMthdCn'],
            'applyUrl': item['aplyUrlAddr'],
            'refUrl1': item['refUrlAddr1'],
            'refUrl2': item['refUrlAddr2'],
          };
        }).toList();
        
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
  
  // 금액 포맷팅
  static String _formatAmount(String? minAmount, String? maxAmount) {
    if (minAmount == null || minAmount.isEmpty) {
      if (maxAmount == null || maxAmount.isEmpty) {
        return '지원금액 정보 없음';
      }
      return '최대 $maxAmount';
    }
    
    if (maxAmount == null || maxAmount.isEmpty) {
      return '최소 $minAmount';
    }
    
    if (minAmount == maxAmount) {
      return minAmount;
    }
    
    return '$minAmount ~ $maxAmount';
  }
}
