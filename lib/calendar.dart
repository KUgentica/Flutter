import 'package:flutter/material.dart';
import 'bookmark.dart';
import 'chatbot_screen.dart';
import 'common_bottom_navigation.dart';
import 'data_manager.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedIndex = 3; // 캘린더 탭이 선택됨
  DateTime _currentDate = DateTime.now(); // 현재 날짜로 설정
  final DataManager _dataManager = DataManager();
  
  // 초기 이벤트 데이터
  final List<Event> _initialEvents = [
    Event(
      id: 1,
      title: '민생지원금 신청',
      time: '09:30',
      description: '정부 소비쿠폰 15만원 신청',
      eventType: '생활·복지 지원',
      date: DateTime(2025, 8, 3),
    ),
    Event(
      id: 2,
      title: '경기도 청년 지원금',
      time: '14:00',
      description: '경기도 청년 일자리 지원금 신청',
      eventType: '취업 지원',
      date: DateTime(2025, 8, 3),
    ),
    Event(
      id: 3,
      title: '문화 공연 관람',
      time: '19:30',
      description: '청년 문화 공연 관람 지원',
      eventType: '생활·복지 지원',
      date: DateTime(2025, 8, 3),
    ),
    Event(
      id: 4,
      title: '창업 교육 프로그램',
      time: '10:00',
      description: '청년 창업가 양성 교육 프로그램',
      eventType: '창업 지원',
      date: DateTime(2025, 8, 4),
    ),
    Event(
      id: 5,
      title: '주거 지원금 신청',
      time: '15:30',
      description: '청년 주거 지원금 신청 안내',
      eventType: '주거 지원',
      date: DateTime(2025, 8, 5),
    ),
    Event(
      id: 6,
      title: '교육비 지원 신청',
      time: '11:00',
      description: '고등교육 무상 지원 신청',
      eventType: '교육·훈련비 지원',
      date: DateTime(2025, 8, 6),
    ),
    Event(
      id: 7,
      title: '금융 상담 서비스',
      time: '16:00',
      description: '청년 금융 상담 및 대출 안내',
      eventType: '금융 지원',
      date: DateTime(2025, 8, 7),
    ),
    Event(
      id: 8,
      title: '취업 준비 워크샵',
      time: '13:00',
      description: '이력서 작성 및 면접 준비 워크샵',
      eventType: '취업 지원',
      date: DateTime(2025, 8, 8),
    ),
    Event(
      id: 9,
      title: '복지 서비스 안내',
      time: '17:30',
      description: '청년 복지 서비스 종합 안내',
      eventType: '생활·복지 지원',
      date: DateTime(2025, 8, 9),
    ),
    Event(
      id: 10,
      title: '창업 아이디어 경진대회',
      time: '14:30',
      description: '청년 창업 아이디어 경진대회 참가',
      eventType: '창업 지원',
      date: DateTime(2025, 8, 10),
    ),
  ];

  // 선택된 날짜의 이벤트 목록 가져오기
  List<Event> get _selectedDateEvents {
    final deletedIds = _dataManager.deletedEventIds;
    final dataManagerEvents = _dataManager.events;
    final filteredInitialEvents = _initialEvents.where((e) => !deletedIds.contains(e.id));
    final allEvents = [...filteredInitialEvents, ...dataManagerEvents];
    final uniqueEvents = <Event>[];
    final seenIds = <int>{};

    for (final event in allEvents) {
      if (!seenIds.contains(event.id)) {
        seenIds.add(event.id);
        uniqueEvents.add(event);
      }
    }

    return uniqueEvents.where((event) {
      return event.date.year == _currentDate.year &&
             event.date.month == _currentDate.month &&
             event.date.day == _currentDate.day;
    }).toList();
  }

  // 모든 이벤트 목록 (캘린더 점 표시용)
  List<Event> get _events {
    final deletedIds = _dataManager.deletedEventIds;
    final dataManagerEvents = _dataManager.events;
    final filteredInitialEvents = _initialEvents.where((e) => !deletedIds.contains(e.id));
    final allEvents = [...filteredInitialEvents, ...dataManagerEvents];
    final uniqueEvents = <Event>[];
    final seenIds = <int>{};

    for (final event in allEvents) {
      if (!seenIds.contains(event.id)) {
        seenIds.add(event.id);
        uniqueEvents.add(event);
      }
    }

    return uniqueEvents;
  }

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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        '캘린더',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1B1C),
                        ),
                        textAlign: TextAlign.center,
                      ),
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentDate.month}월 ${_currentDate.day}일 일정',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1B1C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _selectedDateEvents.isEmpty
                        ? const Center(
                            child: Text(
                              '해당 날짜에 일정이 없습니다.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Column(
                            children: _selectedDateEvents
                                .asMap()
                                .entries
                                .map((entry) => _buildEventCard(entry.value, entry.key))
                                .toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendarDays() {
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = 일요일

    List<Widget> calendarDays = [];
    int currentDay = 1;

    for (int week = 0; week < 6; week++) {
      List<Widget> weekDays = [];
      for (int day = 0; day < 7; day++) {
        if (week == 0 && day < firstWeekday) {
          weekDays.add(const Expanded(child: SizedBox()));
        } else if (currentDay > daysInMonth) {
          weekDays.add(const Expanded(child: SizedBox()));
        } else {
          final today = DateTime.now();
          // Updated logic: 'today' styling only applies when selected date is today.
          final isSelected = currentDay == _currentDate.day;
          final isToday = currentDay == today.day
                          && _currentDate.day == today.day
                          && _currentDate.month == today.month
                          && _currentDate.year == today.year;
          final hasEvent = _events.where((event) =>
            event.date.year == _currentDate.year &&
            event.date.month == _currentDate.month &&
            event.date.day == currentDay
          ).isNotEmpty;
          final dayEvents = _events.where((event) =>
            event.date.year == _currentDate.year &&
            event.date.month == _currentDate.month &&
            event.date.day == currentDay
          ).toList();
          final uniqueEventTypes = dayEvents.map((e) => e.eventType).toSet().toList(); // 중복 제거된 이벤트 유형들

          // 현재 날짜가 유효한지 확인
          if (currentDay <= daysInMonth) {
            final tappedDay = currentDay;
            weekDays.add(
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
                      if (tappedDay <= daysInMonth) {
                        print('날짜 클릭됨: $tappedDay');
                        print('현재 날짜: ${_currentDate.year}-${_currentDate.month}-${_currentDate.day}');
                        print('새로운 날짜: ${_currentDate.year}-${_currentDate.month}-$tappedDay');
                        setState(() {
                          _currentDate = DateTime(_currentDate.year, _currentDate.month, tappedDay);
                        });
                        print('변경된 날짜: ${_currentDate.year}-${_currentDate.month}-${_currentDate.day}');
                      }
                    },
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5B9EE1).withValues(alpha: 0.3)
                            : isToday
                                ? const Color(0xFF5B9EE1).withValues(alpha: 0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$currentDay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF5B9EE1)
                                  : isToday
                                      ? const Color(0xFF5B9EE1)
                                      : day % 7 == 0
                                          ? const Color(0xFFFF5545)
                                          : const Color(0xFF1A1B1C),
                            ),
                          ),
                          if (hasEvent)
                            Row(
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            currentDay++;
          } else {
            weekDays.add(const Expanded(child: SizedBox()));
          }
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
        _dataManager.removeEvent(event.id);
        setState(() {}); // 강제로 다시 그림
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
  final DateTime date; // 이벤트 날짜 추가

  Event({
    required this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.eventType,
    required this.date,
  });
} 