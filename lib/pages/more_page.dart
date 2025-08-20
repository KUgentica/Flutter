import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../common_bottom_navigation.dart';
import 'account_info_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  int _selectedIndex = 4; // 예를 들어 '더보기' 페이지 인덱스가 4라면 이렇게 설정

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '더보기',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        titleSpacing: 16,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Container(
              height: 120,
              child: _MenuBox(
                icon: Icons.person_outline,
                label: '계정 정보',
                background: const Color.fromRGBO(234, 234, 234, 0.5),
                iconColor: const Color(0xFF0088FF),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountInfoPage()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Opacity(
            opacity: 0.65,
            child: GestureDetector(
              onTap: () async {
                // 실제 로그아웃: 토큰 삭제 후 로그인 화면으로 이동
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text(
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
        ],
      ),
      bottomNavigationBar: CommonBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          NavigationHelper.navigateToScreen(context, index);
        },
      ),
    );
  }
}

class _MenuBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _MenuBox({
    required this.icon,
    required this.label,
    required this.background,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.65,
              child: Icon(icon, size: 35, color: iconColor ?? Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ],
        ),
      ),
    );
    return onTap == null
        ? box
        : InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: onTap,
            child: box,
          );
  }
}
