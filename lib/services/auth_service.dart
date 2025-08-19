import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android 에뮬레이터용
  // static const String baseUrl = 'http://172.20.10.8:8080'; // 실제 기기용 (컴퓨터 IP)
  
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
          // 사용자 이메일도 저장 (키를 'user_email'로 통일)
          await prefs.setString('user_email', email);
          print('💾 토큰 및 사용자 이메일 저장 완료');
          print('🔑 저장된 키: user_email = $email');
        }
        
        return {
          'success': true,
          'message': '로그인이 완료되었습니다!',
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'email': email,  // 사용자 이메일 추가
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
  
  // 로그아웃 (토큰/사용자 정보 삭제 + 서버 쿠키 무효화 시도)
  static Future<void> logout() async {
    try {
      // 서버에 refresh 쿠키 무효화를 요청 (있으면)
      // 서버에 엔드포인트가 없더라도 앱 동작에 영향 없도록 무시
      await http.post(Uri.parse('$baseUrl/logout')).catchError((_) {});
    } catch (_) {}

    // 로그아웃 전에 사용자 채팅 기록 초기화 시도
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
    print('🚪 로그아웃 완료: 토큰/사용자 정보 삭제');
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
      print('🚀 === 프로필 업데이트 시작 ===');
      print('📧 사용자 이메일: $email');
      print('🌍 선택된 지역: $region');
      print('🎂 선택된 나이: $age');
      print('👫 선택된 성별: $gender');
      print('📡 요청 URL: $baseUrl/user/profile/update');
      print('📦 전송할 데이터: {"region": "$region", "age": $age, "gender": "$gender"}');
      
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
      
      print('📥 === 서버 응답 ===');
      print('📊 응답 상태 코드: ${response.statusCode}');
      print('📋 응답 헤더: ${response.headers}');
      print('📄 응답 바디: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ 프로필 업데이트 성공!');
        print('🎉 사용자 정보가 MongoDB에 저장되었습니다.');
        return {
          'success': true,
          'message': '프로필이 업데이트되었습니다!',
        };
      } else {
        print('❌ 프로필 업데이트 실패: ${response.statusCode}');
        print('💥 실패 원인: ${response.body}');
        return {
          'success': false,
          'message': '프로필 업데이트에 실패했습니다. (${response.statusCode})',
        };
      }
    } catch (e) {
      print('💥 === 네트워크 오류 ===');
      print('❌ 오류 타입: ${e.runtimeType}');
      print('❌ 오류 메시지: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      return {
        'success': false,
        'message': '네트워크 오류가 발생했습니다: $e',
      };
    }
  }

  // 사용자 프로필 정보 가져오기
  static Future<Map<String, dynamic>> getUserProfile(String email) async {
    try {
      print('👤 프로필 정보 조회 시도');
      print('📧 이메일: $email');
      print('📡 요청 URL: $baseUrl/user/profile/get');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile/get?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 바디: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ 프로필 정보 조회 성공!');
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        print('❌ 프로필 정보 조회 실패: ${response.statusCode}');
        return {
          'success': false,
          'message': '프로필 정보 조회에 실패했습니다. (${response.statusCode})',
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

  // 사용자 프로필 완성 여부 확인
  static Future<bool> isProfileComplete(String email) async {
    try {
      print('🔍 프로필 완성 여부 확인 시도');
      print('📧 이메일: $email');
      
      final profileResult = await getUserProfile(email);
      
      if (profileResult['success']) {
        final data = profileResult['data'];
        final hasRegion = data['region'] != null && data['region'].toString().isNotEmpty;
        final hasAge = data['age'] != null && data['age'] > 0;
        final hasGender = data['gender'] != null && data['gender'].toString().isNotEmpty;
        
        final isComplete = hasRegion && hasAge && hasGender;
        
        print('📊 프로필 완성 상태:');
        print('  🌍 지역: $hasRegion (${data['region']})');
        print('  🎂 나이: $hasAge (${data['age']})');
        print('  👫 성별: $hasGender (${data['gender']})');
        print('  ✅ 완성 여부: $isComplete');
        
        return isComplete;
      } else {
        print('❌ 프로필 정보 조회 실패');
        return false;
      }
    } catch (e) {
      print('💥 프로필 완성 여부 확인 중 오류: $e');
      return false;
    }
  }

  // Onboarding 완료 여부 확인 (사용자별)
  static Future<bool> isOnboardingCompleted(String email) async {
    try {
      print('🔍 Onboarding 완료 여부 확인 시도');
      print('📧 사용자 이메일: $email');
      
      final prefs = await SharedPreferences.getInstance();
      // 사용자별 onboarding 완료 키 사용
      final onboardingKey = 'onboarding_completed_$email';
      final isCompleted = prefs.getBool(onboardingKey) ?? false;
      
      print('📋 Onboarding 완료 키: $onboardingKey');
      print('📊 Onboarding 완료 상태: $isCompleted');
      
      return isCompleted;
    } catch (e) {
      print('💥 Onboarding 완료 여부 확인 중 오류: $e');
      return false;
    }
  }

  // 사용자가 onboarding을 완료했는지 확인 (DB 데이터 기반)
  static Future<bool> shouldShowOnboarding(String email) async {
    try {
      print('🔍 Onboarding 표시 여부 확인 시도');
      
      // 1. Onboarding 완료 플래그 확인 (우선순위 높음)
      final onboardingCompleted = await isOnboardingCompleted(email);
      print('📋 Onboarding 완료 플래그: $onboardingCompleted');
      
      if (onboardingCompleted) {
        print('✅ Onboarding이 이미 완료되었습니다. 건너뜁니다.');
        return false;
      }
      
      // 2. DB에서 실제 프로필 데이터 확인
      print('🔍 DB에서 실제 프로필 데이터 확인 중...');
      final profileResult = await getUserProfile(email);
      
      if (profileResult['success']) {
        final data = profileResult['data'];
        
        // 실제 DB에 저장된 데이터인지 확인 (데이터 존재 여부만 확인)
        final hasValidRegion = data['region'] != null && 
                              data['region'].toString().isNotEmpty;
        
        final hasValidAge = data['age'] != null && data['age'] > 0;
        
        final hasValidGender = data['gender'] != null && 
                              data['gender'].toString().isNotEmpty;
        
        final hasValidProfile = hasValidRegion && hasValidAge && hasValidGender;
        
        print('📊 DB 프로필 데이터 분석:');
        print('  🌍 지역: $hasValidRegion (${data['region']})');
        print('  🎂 나이: $hasValidAge (${data['age']})');
        print('  👫 성별: $hasValidGender (${data['gender']})');
        print('  ✅ 유효한 프로필: $hasValidProfile');
        
        if (hasValidProfile) {
          print('✅ DB에 유효한 프로필 데이터가 있습니다. Onboarding을 건너뜁니다.');
          return false;
        } else {
          print('⚠️ DB에 유효한 프로필 데이터가 없습니다. Onboarding을 표시합니다.');
          return true;
        }
      } else {
        print('❌ DB 프로필 조회 실패. Onboarding을 표시합니다.');
        return true;
      }
      
    } catch (e) {
      print('💥 Onboarding 표시 여부 확인 중 오류: $e');
      // 오류 발생 시 안전하게 onboarding 표시
      return true;
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

  // MongoDB에서 채팅 메시지 조회
  static Future<List<Map<String, String>>> getMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');
      
      if (userEmail == null) {
        print('❌ 사용자 이메일이 없습니다.');
        return [];
      }

      print('📥 MongoDB에서 채팅 메시지 조회 시도');
      print('📧 사용자: $userEmail');

      final response = await http.get(
        Uri.parse('$baseUrl/chat/get?userEmail=$userEmail'),
      );

      print('📥 응답 상태 코드: ${response.statusCode}');

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
          
          print('✅ MongoDB에서 ${messages.length}개 메시지 조회 완료');
          return messages;
        } else {
          print('❌ 메시지 조회 실패: ${data['error']}');
          return [];
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        print('📄 응답: ${response.body}');
        return [];
      }
    } catch (e) {
      print('💥 메시지 조회 중 오류: $e');
      return [];
    }
  }

  // 채팅 메시지를 MongoDB에 저장
  static Future<void> addMessage(String role, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email'); // SharedPreferences에서 가져온 키
      
      print('🔍 SharedPreferences에서 이메일 조회 시도');
      print('🔑 키: user_email');
      print('📧 조회된 이메일: $userEmail');
      
      if (userEmail == null) {
        print('❌ 사용자 이메일이 없습니다.');
        print('🔍 SharedPreferences 전체 키 확인:');
        final keys = prefs.getKeys();
        for (final key in keys) {
          final value = prefs.get(key);
          print('   - $key: $value');
        }
        return;
      }

      print('💬 MongoDB에 메시지 저장 시도');
      print('📧 사용자: $userEmail');
      print('👤 역할: $role');
      print('📝 내용: $text');
      print('🌐 API URL: $baseUrl/chat/save');

      final requestBody = {
        'userEmail': userEmail, // Spring Boot에서 기대하는 키
        'folder': '일반', // 기본 폴더
        'role': role,
        'text': text,
      };
      
      print('📤 요청 본문: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/chat/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📄 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ MongoDB 저장 성공!');
          print('🆔 Chat ID: ${data['chatId']}');
          print('⏰ 시간: ${data['timestamp']}');
        } else {
          print('❌ MongoDB 저장 실패: ${data['error']}');
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
        print('📄 응답: ${response.body}');
      }
    } catch (e) {
      print('💥 MongoDB 저장 중 오류: $e');
      print('💥 오류 타입: ${e.runtimeType}');
      print('💥 스택 트레이스:');
      print(e);
    }
  }

  // 사용자 채팅 기록 전체 삭제 (가능한 엔드포인트들을 순차 시도)
  static Future<bool> clearChatMessages({String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = email ?? prefs.getString('user_email');
      if (userEmail == null || userEmail.isEmpty) {
        print('❌ clearChatMessages: 사용자 이메일이 없습니다.');
        return false;
      }

      print('🧹 채팅 기록 초기화 시도: $userEmail');

      // 1) DELETE 방식 (권장 가정)
      try {
        final resp = await http.delete(
          Uri.parse('$baseUrl/chat/clear?userEmail=$userEmail'),
          headers: {'Content-Type': 'application/json'},
        );
        print('🧹 DELETE /chat/clear 응답: ${resp.statusCode} ${resp.body}');
        if (resp.statusCode == 200) return true;
      } catch (e) {
        print('⚠️ DELETE /chat/clear 실패: $e');
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
        print('⚠️ POST /chat/clear 실패: $e');
      }

      // 3) 다른 네이밍 대안도 시도 (옵션)
      try {
        final resp = await http.delete(
          Uri.parse('$baseUrl/chat/deleteAll?userEmail=$userEmail'),
          headers: {'Content-Type': 'application/json'},
        );
        print('🧹 DELETE /chat/deleteAll 응답: ${resp.statusCode} ${resp.body}');
        if (resp.statusCode == 200) return true;
      } catch (e) {
        print('⚠️ DELETE /chat/deleteAll 실패: $e');
      }

      print('❌ 채팅 기록 초기화 엔드포인트를 찾지 못했습니다. (무시)');
      return false;
    } catch (e) {
      print('💥 clearChatMessages 오류: $e');
      return false;
    }
  }


}
