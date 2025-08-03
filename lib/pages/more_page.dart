import 'package:flutter/material.dart';
import '../common_bottom_navigation.dart';

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
        titleSpacing: 16,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '더보기',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.black87,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MenuBox(
                  icon: Icons.person_outline,
                  label: '계정 정보',
                  background: const Color.fromRGBO(234, 234, 234, 0.5),
                  iconColor: const Color(0xFF0088FF),
                  onTap: () => Navigator.pushNamed(context, '/account'),
                ),
                _MenuBox(
                  icon: Icons.assignment_outlined,
                  label: '공지사항',
                  background: const Color.fromRGBO(234, 234, 234, 0.5),
                  onTap: () => Navigator.pushNamed(context, '/notice'),
                ),
                _MenuBox(
                  icon: Icons.edit_note_outlined,
                  label: '자주 묻는 질문',
                  background: const Color.fromRGBO(234, 234, 234, 0.5),
                  onTap: () => Navigator.pushNamed(context, '/qna'),
                ),
                _MenuBox(
                  icon: Icons.warning_amber_outlined,
                  label: '서비스 이용약관',
                  background: const Color.fromRGBO(234, 234, 234, 0.5),
                  iconColor: const Color.fromRGBO(249, 49, 4, 0.99),
                  onTap: () => Navigator.pushNamed(context, '/terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Opacity(
            opacity: 0.65,
            child: GestureDetector(
              onTap: () {
                // 로그아웃 기능 추가 가능
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
