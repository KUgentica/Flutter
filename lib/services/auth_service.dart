import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://13.125.176.46:8080';

  // 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String nickname,
    required String password,
  }) async {
    try {
      
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

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': '회원가입이 완료되었습니다!',
        };
      } else if (response.statusCode == 409) {
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
            print('응답 파싱 실패: $e');
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      } else {
        return {
          'success': false,
          'message': '회원가입에 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      print('네트워크 오류: $e');
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

      if (response.statusCode == 200) {
        final accessToken = response.headers['access'];

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
        
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          if (refreshToken != null) {
            await prefs.setString('refreshToken', refreshToken);
          }
          await prefs.setString('user_email', email);
        }
        
        return {
          'success': true,
          'message': '로그인이 완료되었습니다!',
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'email': email,  // 사용자 이메일 추가
        };
      } else {
        print('로그인 실패: ${response.statusCode}');
        return {
          'success': false,
          'message': '로그인에 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      print('네트워크 오류: $e');
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
  
  // 로그아웃 (토큰/사용자 정보 삭제 + 서버 쿠키 무효화 시도)
  static Future<void> logout() async {
    try {
      // 서버에 엔드포인트가 없더라도 앱 동작에 영향 없도록 무시
      await http.post(Uri.parse('$baseUrl/logout')).catchError((_) {});
    } catch (_) {}

    try {
      await clearChatMessages();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('user_email');
    if (email != null) {
      await prefs.remove('onboarding_completed_$email');
    }
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
  
  // 사용자 프로필 정보 업데이트
  static Future<Map<String, dynamic>> updateUserProfile({
    required String email,
    required String region,
    required int age,
    required String gender,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile/update?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'region': region,
          'age': age,
          'gender': gender,
        }),
      );
      
      if (response.statusCode == 200) {

        return {
          'success': true,
          'message': '프로필이 업데이트되었습니다!',
        };
      } else {
        print('프로필 업데이트 실패: ${response.statusCode}');
        print('실패 원인: ${response.body}');
        return {
          'success': false,
          'message': '프로필 업데이트에 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      print('오류 타입: ${e.runtimeType}');
      print('오류 메시지: $e');
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: $e',
      };
    }
  }

  // 사용자 프로필 정보 가져오기
  static Future<Map<String, dynamic>> getUserProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile/get?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        print('프로필 정보 조회 실패: ${response.statusCode}');
        return {
          'success': false,
          'message': '프로필 정보 조회에 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      print('네트워크 오류: $e');
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: $e',
      };
    }
  }

  // 사용자 프로필 완성 여부 확인
  static Future<bool> isProfileComplete(String email) async {
    try {
      final profileResult = await getUserProfile(email);
      
      if (profileResult['success']) {
        final data = profileResult['data'];
        final hasRegion = data['region'] != null && data['region'].toString().isNotEmpty;
        final hasAge = data['age'] != null && data['age'] > 0;
        final hasGender = data['gender'] != null && data['gender'].toString().isNotEmpty;
        
        final isComplete = hasRegion && hasAge && hasGender;

        return isComplete;
      } else {
        print('프로필 정보 조회 실패');
        return false;
      }
    } catch (e) {
      print('프로필 완성 여부 확인 중 오류: $e');
      return false;
    }
  }

  // Onboarding 완료 여부 확인 (사용자별)
  static Future<bool> isOnboardingCompleted(String email) async {
    try {
      
      final prefs = await SharedPreferences.getInstance();
      // 사용자별 onboarding 완료 키 사용
      final onboardingKey = 'onboarding_completed_$email';
      final isCompleted = prefs.getBool(onboardingKey) ?? false;

      return isCompleted;
    } catch (e) {
      print('Onboarding 완료 여부 확인 중 오류: $e');
      return false;
    }
  }

  // 사용자가 onboarding을 완료했는지 확인 (DB 데이터 기반)
  static Future<bool> shouldShowOnboarding(String email) async {
    try {

      final onboardingCompleted = await isOnboardingCompleted(email);

      if (onboardingCompleted) {
        return false;
      }
      
      final profileResult = await getUserProfile(email);
      
      if (profileResult['success']) {
        final data = profileResult['data'];
        
        final hasValidRegion = data['region'] != null &&
                              data['region'].toString().isNotEmpty;
        
        final hasValidAge = data['age'] != null && data['age'] > 0;
        
        final hasValidGender = data['gender'] != null && 
                              data['gender'].toString().isNotEmpty;
        
        final hasValidProfile = hasValidRegion && hasValidAge && hasValidGender;

        
        if (hasValidProfile) {
          return false;
        } else {
          return true;
        }
      } else {
        return true;
      }
      
    } catch (e) {
      return true;
    }
  }

  // 이메일 중복 체크
  static Future<bool> checkEmailDuplicate(String email) async {
    try {

      final response = await http.post(
        Uri.parse('$baseUrl/user/check-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      
      if (response.statusCode == 200) {
        // 응답 바디에서 중복 여부 확인
        try {
          final data = jsonDecode(response.body);
          final isDuplicate = data['duplicate'] ?? false;
          return isDuplicate;
        } catch (e) {
          return false; // 파싱 실패 시 중복이 아닌 것으로 처리
        }
      } else if (response.statusCode == 403) {
        return false; // 권한 문제 시 중복이 아닌 것으로 처리
      } else {
        return false; // 에러 시 중복이 아닌 것으로 처리
      }
    } catch (e) {
      return false; // 네트워크 오류 시 중복이 아닌 것으로 처리
    }
  }

  // MongoDB에서 채팅 메시지 조회
  static Future<List<Map<String, String>>> getMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');
      
      if (userEmail == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/get?userEmail=$userEmail'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> chats = data['data'];
          final messages = chats.map<Map<String, String>>((chat) {
            return {
              'role': chat['role'] ?? '',
              'text': chat['text'] ?? '',
            };
          }).toList();
          
          return messages;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 채팅 메시지를 MongoDB에 저장
  static Future<void> addMessage(String role, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email'); // SharedPreferences에서 가져온 키
      if (userEmail == null) {
        final keys = prefs.getKeys();
        for (final key in keys) {
          final value = prefs.get(key);
          print('   - $key: $value');
        }
        return;
      }

      final requestBody = {
        'userEmail': userEmail, // Spring Boot에서 기대하는 키
        'folder': '일반', // 기본 폴더
        'role': role,
        'text': text,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chat/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('MongoDB 저장');

        } else {
          print('MongoDB 저장 실패: ${data['error']}');
        }
      } else {
        print('HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
    }
  }

  // 사용자 채팅 기록 전체 삭제 (가능한 엔드포인트들을 순차 시도)
  static Future<bool> clearChatMessages({String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = email ?? prefs.getString('user_email');
      if (userEmail == null || userEmail.isEmpty) {
        return false;
      }

      try {
        final resp = await http.delete(
          Uri.parse('$baseUrl/chat/clear?userEmail=$userEmail'),
          headers: {'Content-Type': 'application/json'},
        );
        if (resp.statusCode == 200) return true;
      } catch (e) {
        print('DELETE /chat/clear 실패: $e');
      }

      // 2) POST 방식 (대안 가정)
      try {
        final resp = await http.post(
          Uri.parse('$baseUrl/chat/clear'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userEmail': userEmail}),
        );
        print('🧹 POST /chat/clear 응답: ${resp.statusCode} ${resp.body}');
        if (resp.statusCode == 200) return true;
      } catch (e) {
        print(' POST /chat/clear 실패: $e');
      }

      // 3) 다른 네이밍 대안도 시도 (옵션)
      try {
        final resp = await http.delete(
          Uri.parse('$baseUrl/chat/deleteAll?userEmail=$userEmail'),
          headers: {'Content-Type': 'application/json'},
        );
        print('DELETE /chat/deleteAll 응답: ${resp.statusCode} ${resp.body}');
        if (resp.statusCode == 200) return true;
      } catch (e) {
        print('DELETE /chat/deleteAll 실패: $e');
      }
      return false;
    } catch (e) {
      return false;
    }
  }


}
