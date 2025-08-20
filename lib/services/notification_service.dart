import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
// ★ flutter_secure_storage 대신 shared_preferences를 임포트합니다.
import 'package:shared_preferences/shared_preferences.dart';

// 앱이 종료된 상태(Terminated)에서 알림을 처리하기 위한 최상위 함수
// 반드시 클래스 바깥에 위치해야 합니다.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("백그라운드에서 메시지 수신: ${message.notification?.title}");
  // 여기서 데이터베이스 업데이트 등 백그라운드 작업을 수행할 수 있습니다.
}

class FirebaseApi {
  // Firebase Messaging 인스턴스 생성
  final _firebaseMessaging = FirebaseMessaging.instance;

  // 알림 초기화 메소드 (이제 FCM 토큰을 반환합니다)
  Future<String?> initNotifications() async {
    // 1. 알림 권한 요청 (주로 iOS에서 필요)
    await _firebaseMessaging.requestPermission();

    // 2. FCM 토큰 가져오기 (특정 기기에 알림을 보낼 때 사용되는 고유 주소)
    final fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");

    // 3. 백그라운드 메시지 핸들러 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. 앱이 실행 중일 때(Foreground) 알림을 수신하는 리스너
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드에서 메시지 수신!');
      if (message.notification != null) {
        print('알림 제목: ${message.notification!.title}');
        print('알림 본문: ${message.notification!.body}');
      }
      // 여기서 받은 메시지를 이용해 화면에 직접 UI를 표시할 수 있습니다.
    });

    // 5. 가져온 토큰을 반환합니다.
    return fcmToken;
  }

  // ★ 서버로 FCM 토큰을 전송하는 static 메소드 수정
  static Future<void> sendTokenToServer(String token) async {
    // 서버의 기본 URL을 설정하세요.
    const String baseUrl = 'http://10.0.2.2:8080'; // AuthService와 동일한 baseUrl 사용
    final url = Uri.parse('$baseUrl/notification/fcmToken/save');

    try {
      // ★ SharedPreferences를 사용하여 저장된 Access Token을 가져옵니다.
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        print('Access Token이 없어 FCM 토큰을 전송할 수 없습니다.');
        return;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // 인증 헤더에 Access Token 추가
        },
        body: jsonEncode({'fcmToken': token}), // 서버 DTO에 맞는 형식으로 전송
      );

      if (response.statusCode == 200) {
        print('FCM 토큰이 서버에 성공적으로 저장되었습니다.');
      } else {
        print('FCM 토큰 서버 저장 실패: ${response.statusCode}');
        print('응답: ${response.body}');
      }
    } catch (e) {
      print('FCM 토큰 전송 중 오류 발생: $e');
    }
  }
}
