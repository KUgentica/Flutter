import 'dart:convert'; // utf8 decoding을 위해 필요
import 'package:http/http.dart' as http;
import '../models/center.dart'; // 방금 만든 Center 모델 import

class CenterApiService {
  // 안드로이드 에뮬레이터에서 로컬호스트(PC) 서버에 접속하기 위한 주소
  static const String _baseUrl = "http://10.0.2.2:8080";

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
        // 성공적으로 데이터를 받아온 경우
        print("[API] 응답 성공: Status 200");

        // 한글 깨짐 방지를 위해 bodyBytes를 utf8로 디코딩
        final String jsonBody = utf8.decode(response.bodyBytes);
        final List<Center> centers = centerFromJson(jsonBody);
        
        print("[API] 센터 ${centers.length}개 파싱 완료.");
        return centers;
        
      } else {
        // 서버에서 200이 아닌 상태 코드를 반환한 경우
        print("[API] 응답 실패: Status ${response.statusCode}");
        throw Exception('청년 센터 데이터를 불러오는데 실패했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      // 네트워크 오류 등 요청 중 예외가 발생한 경우
      print("[API] 요청 오류: $e");
      throw Exception('서버 통신 중 오류가 발생했습니다: $e');
    }
  }
}