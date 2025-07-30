import 'package:flutter/material.dart';
import 'calendar.dart';
import 'bookmark.dart';
import 'chatbot_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const BookmarkScreen(),
    );
  }
}
