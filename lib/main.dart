import 'package:flutter/material.dart';
import 'calendar.dart';
import 'bookmark.dart';
import 'chatbot_screen.dart';
import 'login.dart';
import 'signup.dart';
import 'restore.dart';
import 'list.dart';
import 'detail.dart';
import 'search.dart';
import 'home.dart';
import 'onboarding_screen.dart';
import 'pages/more_page.dart';
import 'pages/account_info_page.dart';
import 'pages/qna_page.dart';
import 'pages/notice_page.dart';
import 'pages/settings_page.dart';
import 'pages/terms_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '청년알리미E',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B9EE1),
          primary: const Color(0xFF5B9EE1),
          secondary: const Color(0xFFFF5545),
        ),
        useMaterial3: true,
        fontFamily: 'Work Sans',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/restore': (context) => const RestorePage(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MyHomePage(),
        '/more': (context) => const MorePage(),
        '/account': (context) => const AccountInfoPage(),
        '/qna': (context) => const QnaPage(),
        '/notice': (context) => const NoticePage(),
        '/settings': (context) => const SettingsPage(),
        '/terms': (context) => const TermsPage(),
      },
      home: const MyHomePage(),
    );
  }
}
