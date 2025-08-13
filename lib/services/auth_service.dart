import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080';
  
  // 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String nickname,
    required String password,
  }) async {
    try {
      print('🔐 회원가입 시도: $email, $nickname');
      print('📡 요청 URL: $baseUrl/user/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/user/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'nickname': nickname,
          'password': password,
        }),
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 바디: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ 회원가입 성공!');
        return {
          'success': true,
          'message': '회원가입이 완료되었습니다!',
        };
      } else if (response.statusCode == 409) {
        // 중복 이메일 에러 (Conflict)
        print('❌ 중복 이메일: ${response.statusCode}');
        String errorMessage = '이미 사용 중인 이메일입니다.';
        
        // 서버에서 보낸 에러 메시지가 있으면 사용
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            if (data is String) {
              errorMessage = data;
            }
          } catch (e) {
            print('⚠️ 응답 파싱 실패: $e');
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        print('❌ 회원가입 실패: ${response.statusCode}');
        return {
          'success': false,
          'message': '회원가입에 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: $e',
      };
    }
  }
  
  // 로그인
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 로그인 시도: $email');
      print('📡 요청 URL: $baseUrl/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,  // API 명세와 맞춤
          'password': password,
        }),
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 헤더: ${response.headers}');
      
      if (response.statusCode == 200) {
        // Access Token 추출 (헤더에서)
        final accessToken = response.headers['access'];
        print('🔑 Access Token: $accessToken');
        
        // Refresh Token 추출 (Set-Cookie에서)
        final setCookieHeader = response.headers['set-cookie'];
        String? refreshToken;
        if (setCookieHeader != null) {
          final cookieParts = setCookieHeader.split(';');
          for (final part in cookieParts) {
            if (part.trim().startsWith('refresh=')) {
              refreshToken = part.trim().substring(8); // 'refresh=' 제거
              break;
            }
          }
        }
        print('🔄 Refresh Token: $refreshToken');
        
        // 토큰들을 SharedPreferences에 저장
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          if (refreshToken != null) {
            await prefs.setString('refreshToken', refreshToken);
          }
          print('💾 토큰 저장 완료');
        }
        
        return {
          'success': true,
          'message': '로그인이 완료되었습니다!',
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        };
      } else {
        print('❌ 로그인 실패: ${response.statusCode}');
        return {
          'success': false,
          'message': '로그인에 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: $e',
      };
    }
  }
  
  // Access Token 가져오기
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }
  
  // 로그아웃 (토큰 삭제)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    print('🚪 로그아웃 완료');
  }
  
  // 인증된 요청을 위한 헤더 생성
  static Future<Map<String, String>> getAuthHeaders() async {
    final accessToken = await getAccessToken();
    if (accessToken != null) {
      return {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }
  
  // 인증된 사용자 정보 가져오기 (예시)
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),  // 예시 엔드포인트
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 401) {
        // 토큰 만료 또는 유효하지 않음
        await logout();  // 토큰 삭제
        return {
          'success': false,
          'message': '인증이 만료되었습니다. 다시 로그인해주세요.',
          'expired': true,
        };
      } else {
        return {
          'success': false,
          'message': '사용자 정보를 가져오는데 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: $e',
      };
    }
  }

  // 이메일 중복 체크
  static Future<bool> checkEmailDuplicate(String email) async {
    try {
      print('🔍 이메일 중복 체크: $email');
      print('📡 요청 URL: $baseUrl/user/check-email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/user/check-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );
      
      print('📥 중복 체크 응답 상태 코드: ${response.statusCode}');
      print('📥 중복 체크 응답 바디: ${response.body}');
      
      if (response.statusCode == 200) {
        // 응답 바디에서 중복 여부 확인
        try {
          final data = jsonDecode(response.body);
          final isDuplicate = data['duplicate'] ?? false;
          print('🔍 이메일 중복 여부: $isDuplicate');
          return isDuplicate;
        } catch (e) {
          print('⚠️ 응답 파싱 실패: $e');
          return false; // 파싱 실패 시 중복이 아닌 것으로 처리
        }
      } else if (response.statusCode == 403) {
        // 권한 없음 (Forbidden) - 보안 설정 문제
        print('🚫 권한 없음 (403): ${response.statusCode}');
        print('⚠️ /user/check-email 엔드포인트에 접근 권한이 없습니다.');
        print('⚠️ Spring Security 설정을 확인해주세요.');
        return false; // 권한 문제 시 중복이 아닌 것으로 처리
      } else {
        print('❌ 중복 체크 실패: ${response.statusCode}');
        return false; // 에러 시 중복이 아닌 것으로 처리
      }
    } catch (e) {
      print('💥 네트워크 오류: $e');
      return false; // 네트워크 오류 시 중복이 아닌 것으로 처리
    }
  }
}
