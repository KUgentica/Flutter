import 'package:calender_bookmark/pages/more_page.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'bookmark.dart';
import 'calendar.dart';
import 'chatbot_screen.dart';

class CommonBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CommonBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 4.0,
      color: const Color(0xFFE2EEFF),
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, "홈", 0),
                _buildNavItem(Icons.star, "즐겨찾기", 1),
                const SizedBox(width: 60),
                _buildNavItem(Icons.calendar_today, "캘린더", 3),
                _buildNavItem(Icons.more_horiz, "더보기", 4),
                
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: selectedIndex == 2 ? -12 : -7,
              child: GestureDetector(
                onTap: () => onItemTapped(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedIndex == 2
                          ? const Color(0xFF6498E2)
                          : const Color(0xFFB0C9EE),
                      width: 5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/chat_bubble.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: selectedIndex == 2
                            ? Colors.black
                            : const Color(0xFF888888),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "chat-bot",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                            color: selectedIndex == 2
                            ? Colors.black
                            : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, isSelected ? -5 : 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : const Color(0xFF61646B),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : const Color(0xFF61646B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationHelper {
  static void navigateToScreen(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BookmarkPage()),
        );
        break;
      
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatBotScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CalendarScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MorePage()),
        );
        break;
    }
  }
} 