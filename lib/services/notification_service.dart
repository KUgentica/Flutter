import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("백그라운드에서 메시지 수신: ${message.notification?.title}");
  // 여기서 데이터베이스 업데이트 등 백그라운드 작업을 수행할 수 있습니다.
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> initNotifications() async {
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('알림 제목: ${message.notification!.title}');
        print('알림 본문: ${message.notification!.body}');
      }
    });
    return fcmToken;
  }

  static Future<void> sendTokenToServer(String token) async {
    const String baseUrl = "http://13.125.176.46:8080"; // AuthService와 동일한 baseUrl 사용
    final url = Uri.parse('$baseUrl/notification/fcmToken/save');

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
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
      } else {
        print('FCM 토큰 서버 저장 실패: ${response.statusCode}');
        print('응답: ${response.body}');
      }
    } catch (e) {
      print('FCM 토큰 전송 중 오류 발생: $e');
    }
  }
}
