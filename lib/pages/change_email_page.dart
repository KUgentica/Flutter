// lib/pages/change_email_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/rounded_input.dart';
import '../widgets/confirmation_dialog.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final TextEditingController _emailController = TextEditingController();

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showDialog(
        context: context,
        builder: (_) => const ConfirmationDialog(
          title: '유효하지 않은 이메일',
          message: '올바른 이메일 주소를 입력해주세요.',
        ),
      );
      return;
    }

    // 이메일 확인 로직 또는 서버 요청 가능
    showDialog(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: '이메일 변경',
        message: '이메일을 "$email"로 변경하시겠습니까?',
        onConfirm: () {
          Navigator.pop(context); // 다이얼로그 닫기
          Navigator.pop(context); // 이전 화면으로 이동
          // 실제 이메일 변경 처리 필요
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이메일 변경', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('새 이메일 주소', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            RoundedInput(
              controller: _emailController,
              hintText: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('변경하기', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4, onTap: null),
    );
  }
}
