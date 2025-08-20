import 'package:flutter/material.dart';
import '../models/calendarEvent.dart'; // ★ 새로 만든 모델 임포트
import '../services/bookmark_service.dart'; // ★ 서버 통신을 위한 서비스 임포트
import '../common_bottom_navigation.dart'; // 위젯 경로에 맞게 수정하세요.

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedIndex = 3; // 캘린더 탭
  DateTime _currentDate = DateTime.now();
  
  // ★ 서버에서 가져온 이벤트 목록을 관리합니다.
  List<CalendarEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventsForCurrentMonth();
  }

  // ★ 현재 선택된 월의 이벤트를 서버에서 로드하는 함수
  Future<void> _loadEventsForCurrentMonth() async {
    setState(() => _isLoading = true);
    try {
      final events = await BookmarkService.getCalendarEvents(
        _currentDate.year,
        _currentDate.month,
      );
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('💥 캘린더 이벤트 로드 실패: $e');
    }
  }

  // ★ 선택된 날짜의 이벤트 목록을 필터링하여 가져옵니다.
  List<CalendarEvent> get _selectedDateEvents {
    return _events.where((event) {
      return event.date.year == _currentDate.year &&
          event.date.month == _currentDate.month &&
          event.date.day == _currentDate.day;
    }).toList();
  }

  // 월 이동 시 이벤트를 다시 로드합니다.
  void _changeMonth(int monthOffset) {
    setState(() {
      _currentDate = DateTime(
        _currentDate.year,
        _currentDate.month + monthOffset,
        1,
      );
    });
    _loadEventsForCurrentMonth();
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text('캘린더', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      color: Colors.black.withOpacity(0.05),
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
                          onPressed: () => _changeMonth(-1),
                        ),
                        Text(
                          '${_currentDate.year}년 ${_currentDate.month}월',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _changeMonth(1),
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
                                    fontWeight: FontWeight.w500,
                                    color: day == '일' ? Colors.red : Colors.grey[600],
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentDate.month}월 ${_currentDate.day}일 일정',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _selectedDateEvents.isEmpty
                            ? const Center(child: Text('해당 날짜에 일정이 없습니다.'))
                            : Column(
                                children: _selectedDateEvents
                                    .map((event) => _buildEventCard(event))
                                    .toList(),
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendarDays() {
    final daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> calendarDays = [];
    int currentDay = 1;

    for (int week = 0; week < 6; week++) {
      List<Widget> weekDays = [];
      for (int day = 0; day < 7; day++) {
        if ((week == 0 && day < firstWeekday) || currentDay > daysInMonth) {
          weekDays.add(const Expanded(child: SizedBox()));
        } else {
          final date = DateTime(_currentDate.year, _currentDate.month, currentDay);
          final isSelected = date.day == _currentDate.day;
          final hasEvent = _events.any((event) =>
              event.date.year == date.year &&
              event.date.month == date.month &&
              event.date.day == date.day);

          weekDays.add(
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentDate = date),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$currentDay',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : Colors.black87,
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          currentDay++;
        }
      }
      calendarDays.add(Row(children: weekDays));
      if (currentDay > daysInMonth) break;
    }
    return calendarDays;
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            child: Text(
              event.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color getEventTypeColor(String eventType) {
    // ... (이전과 동일한 색상 매핑 함수)
    return Colors.blue;
  }
}
