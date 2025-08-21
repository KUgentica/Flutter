import 'dart:convert'; // utf8 decoding을 위해 필요
import 'package:http/http.dart' as http;
import '../models/center.dart'; // 방금 만든 Center 모델 import

class CenterApiService {
  // 안드로이드 에뮬레이터에서 로컬호스트(PC) 서버에 접속하기 위한 주소
  static const String _baseUrl = "http://13.125.176.46:8080";

  /**
   * 서버에서 모든 청년 센터 목록을 가져옵니다.
   * 성공 시 List<Center>를 반환하고, 실패 시 예외를 발생시킵니다.
   */
  static Future<List<Center>> getCenters() async {
    final url = Uri.parse('$_baseUrl/policy/center');
    
    try {
      print("[API] 요청 시작: GET $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("Status 200");
        final String jsonBody = utf8.decode(response.bodyBytes);
        final List<Center> centers = centerFromJson(jsonBody);
        return centers;
      } else {
        print("응답 실패: Status ${response.statusCode}");
        throw Exception('청년 센터 데이터를 불러오는데 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('서버 통신 중 오류가 발생했습니다: $e');
    }
  }
}