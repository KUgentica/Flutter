// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/nav_row.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool push = true;
  bool promo = true;
  bool locationConsent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SwitchListTile(
            title: const Text('푸시 알림'),
            value: push,
            onChanged: (v) => setState(() => push = v),
          ),
          SwitchListTile(
            title: const Text('프로모션'),
            value: promo,
            onChanged: (v) => setState(() => promo = v),
          ),
          SwitchListTile(
            title: const Text('위치 정보 서비스 이용약관 동의'),
            value: locationConsent,
            onChanged: (v) => setState(() => locationConsent = v),
          ),
          NavRow(
            title: '암호 설정',
            trailing: const Text('OFF', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
          const Divider(thickness: 1),
          NavRow(
            title: '개인정보 처리 방침',
            onTap: () {},
          ),
          const NavRow(
            title: '버전 정보',
            trailing: Text('25.8.1', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 24),
          Center(
            child: Opacity(
              opacity: 0.65,
              child: Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.43,
                  decoration: TextDecoration.underline,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
