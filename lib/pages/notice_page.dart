// lib/pages/notice_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = [
      {'title': '업데이트 안내', 'date': '2025.08.01'},
      {'title': '시스템 점검 공지', 'date': '2025.07.24'},
      {'title': '여름 이벤트 오픈', 'date': '2025.07.15'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final notice = notices[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(notice['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            subtitle: Text(notice['date']!, style: const TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          );
        },
        separatorBuilder: (_, __) => const Divider(),
        itemCount: notices.length,
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }
}
