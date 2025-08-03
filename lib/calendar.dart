import 'package:flutter/material.dart';
import 'bookmark.dart';
import 'chatbot_screen.dart';
import 'common_bottom_navigation.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedIndex = 3; // 캘린더 탭이 선택됨
  DateTime _currentDate = DateTime.now(); // 현재 날짜로 설정
  final List<Event> _events = [
    Event(
      id: 1,
      title: '민생지원금 신청',
      time: '09:30',
      description: '정부 소비쿠폰 15만원 신청',
      eventType: '생활·복지 지원',
    ),
    Event(
      id: 2,
      title: '경기도 청년 지원금',
      time: '14:00',
      description: '경기도 청년 일자리 지원금 신청',
      eventType: '취업 지원',
    ),
    Event(
      id: 3,
      title: '문화 공연 관람',
      time: '19:30',
      description: '청년 문화 공연 관람 지원',
      eventType: '생활·복지 지원',
    ),
    Event(
      id: 4,
      title: '창업 교육 프로그램',
      time: '10:00',
      description: '청년 창업가 양성 교육 프로그램',
      eventType: '창업 지원',
    ),
    Event(
      id: 5,
      title: '주거 지원금 신청',
      time: '15:30',
      description: '청년 주거 지원금 신청 안내',
      eventType: '주거 지원',
    ),
    Event(
      id: 6,
      title: '교육비 지원 신청',
      time: '11:00',
      description: '고등교육 무상 지원 신청',
      eventType: '교육·훈련비 지원',
    ),
    Event(
      id: 7,
      title: '금융 상담 서비스',
      time: '16:00',
      description: '청년 금융 상담 및 대출 안내',
      eventType: '금융 지원',
    ),
    Event(
      id: 8,
      title: '취업 준비 워크샵',
      time: '13:00',
      description: '이력서 작성 및 면접 준비 워크샵',
      eventType: '취업 지원',
    ),
    Event(
      id: 9,
      title: '복지 서비스 안내',
      time: '17:30',
      description: '청년 복지 서비스 종합 안내',
      eventType: '생활·복지 지원',
    ),
    Event(
      id: 10,
      title: '창업 아이디어 경진대회',
      time: '14:30',
      description: '청년 창업 아이디어 경진대회 참가',
      eventType: '창업 지원',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: CommonBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          NavigationHelper.navigateToScreen(context, index);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '캘린더',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1B1C),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF1A1B1C)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // 캘린더
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 월 네비게이션
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _currentDate = DateTime(
                              _currentDate.year,
                              _currentDate.month - 1,
                              1,
                            );
                          });
                        },
                      ),
                      Text(
                        '${_currentDate.year}년 ${_currentDate.month}월',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1B1C),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _currentDate = DateTime(
                              _currentDate.year,
                              _currentDate.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 요일 헤더
                  Row(
                    children: ['일', '월', '화', '수', '목', '금', '토']
                        .map((day) => Expanded(
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: day == '일'
                                      ? const Color(0xFFFF5545)
                                      : const Color(0xFF707B81),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  // 날짜 그리드
                  ..._buildCalendarDays(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 이벤트 리스트
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘의 일정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1B1C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(_events[index], index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 하단 네비게이션은 CommonBottomNavigation으로 대체됨
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCalendarDays() {
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = 일요일

    List<Widget> calendarDays = [];
    int dayCount = 1;

    for (int week = 0; week < 6; week++) {
      List<Widget> weekDays = [];
      for (int day = 0; day < 7; day++) {
        if (week == 0 && day < firstWeekday) {
          weekDays.add(const Expanded(child: SizedBox()));
        } else if (dayCount > daysInMonth) {
          weekDays.add(const Expanded(child: SizedBox()));
        } else {
          final today = DateTime.now();
          final isToday = dayCount == today.day && _currentDate.month == today.month && _currentDate.year == today.year;
          final hasEvent = _events.isNotEmpty && dayCount == today.day; // 오늘 날짜에만 이벤트 표시
          final dayEvents = _events.where((event) => true).toList(); // 현재는 모든 이벤트를 표시
          final uniqueEventTypes = dayEvents.map((e) => e.eventType).toSet().toList(); // 중복 제거된 이벤트 유형들
          weekDays.add(
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentDate = DateTime(_currentDate.year, _currentDate.month, dayCount);
                  });
                },
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFF5B9EE1).withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayCount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? const Color(0xFF5B9EE1)
                              : day % 7 == 0
                                  ? const Color(0xFFFF5545)
                                  : const Color(0xFF1A1B1C),
                        ),
                      ),
                      if (hasEvent)
                        Positioned(
                          bottom: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: uniqueEventTypes.take(3).map((eventType) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: getEventTypeColor(eventType),
                                shape: BoxShape.circle,
                              ),
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          dayCount++;
        }
      }
      calendarDays.add(Row(children: weekDays));
    }
    return calendarDays;
  }

  Widget _buildEventCard(Event event, int index) {
    return Dismissible(
      key: Key('event_${event.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFFF5545),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _events.removeAt(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: getEventTypeColor(event.eventType),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1B1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF707B81),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              event.time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5B9EE1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 기존 네비게이션 바 메서드들은 CommonBottomNavigation으로 대체됨
}

// 이벤트 유형별 색상 매핑 함수
Color getEventTypeColor(String eventType) {
  switch (eventType) {
    case '창업 지원':
      return const Color(0xFF4CAF50); // 초록색
    case '주거 지원':
      return const Color(0xFF2196F3); // 파란색
    case '교육·훈련비 지원':
      return const Color(0xFFFF9800); // 주황색
    case '금융 지원':
      return const Color(0xFF8BC34A); // 연두색
    case '생활·복지 지원':
      return const Color(0xFF9C27B0); // 보라색
    case '취업 지원':
      return const Color(0xFFF44336); // 빨간색
    default:
      return const Color(0xFF5B9EE1); // 기본 파란색
  }
}

class Event {
  final int id;
  final String title;
  final String time;
  final String description;
  final String eventType; // 이벤트 유형 추가

  Event({
    required this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.eventType,
  });
} 