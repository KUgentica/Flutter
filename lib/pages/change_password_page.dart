// lib/pages/change_password_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/rounded_input.dart';
import '../widgets/confirmation_dialog.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  void _submit() {
    final pw = _pwController.text.trim();
    final confirmPw = _confirmController.text.trim();

    if (pw.length < 6) {
      showDialog(
        context: context,
        builder: (_) => const ConfirmationDialog(
          title: '오류',
          message: '비밀번호는 최소 6자 이상이어야 합니다.',
        ),
      );
      return;
    }

    if (pw != confirmPw) {
      showDialog(
        context: context,
        builder: (_) => const ConfirmationDialog(
          title: '오류',
          message: '비밀번호가 일치하지 않습니다.',
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: '비밀번호 변경',
        message: '비밀번호를 변경하시겠습니까?',
        onConfirm: () {
          Navigator.pop(context); // 다이얼로그 닫기
          Navigator.pop(context); // 이전 화면으로 이동
          // 실제 변경 처리 필요
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
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
            const Text('새 비밀번호', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            RoundedInput(
              controller: _pwController,
              hintText: '6자 이상 입력',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            const Text('비밀번호 확인', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            RoundedInput(
              controller: _confirmController,
              hintText: '비밀번호 재입력',
              obscureText: true,
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
    );
  }
}
