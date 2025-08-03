// lib/pages/qna_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class QnaPage extends StatelessWidget {
  const QnaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final qnaList = [
      {
        'question': '채팅은 어떻게 시작하나요?',
        'answer': '상대방 프로필에서 "채팅하기" 버튼을 눌러 대화를 시작할 수 있습니다.',
      },
      {
        'question': '프로필 사진은 어떻게 변경하나요?',
        'answer': '계정 정보 화면에서 프로필 사진을 클릭하면 변경할 수 있습니다.',
      },
      {
        'question': '위치 인증은 어디서 하나요?',
        'answer': '미팅 채팅방 우측 상단 메뉴에서 "위치 인증"을 누르면 됩니다.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('자주 묻는 질문', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: qnaList.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = qnaList[index];
          return ExpansionTile(
            title: Text(
              item['question']!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  item['answer']!,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
