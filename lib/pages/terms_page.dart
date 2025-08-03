// lib/pages/terms_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final termsText = '''
[서비스 이용약관]

1. 목적
본 약관은 앱의 이용조건 및 절차, 이용자와 회사의 권리·의무 및 책임사항 등을 규정함을 목적으로 합니다.

2. 이용계약의 성립
이용자는 약관에 동의함으로써 서비스 이용계약이 성립됩니다.

3. 회원의 의무
회원은 서비스를 이용함에 있어 관련 법령 및 회사의 운영정책을 준수해야 합니다.

4. 개인정보 보호
회사는 이용자의 개인정보를 보호하기 위해 최선을 다합니다. 관련 사항은 개인정보 처리방침을 따릅니다.

5. 기타
본 약관에 명시되지 않은 사항은 관련 법령 및 회사의 방침에 따릅니다.
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('서비스 이용약관', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            termsText,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
