import 'package:flutter/material.dart';
import 'detail.dart';
import 'bookmark.dart';
import 'calendar.dart';
import 'data_manager.dart';

class PolicyListPage extends StatefulWidget {
  final String category;
  final Map<String, dynamic> categoryData;

  const PolicyListPage({
    Key? key,
    required this.category,
    required this.categoryData,
  }) : super(key: key);

  @override
  State<PolicyListPage> createState() => _PolicyListPageState();
}

class _PolicyListPageState extends State<PolicyListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final DataManager _dataManager = DataManager();

  // 카테고리별 샘플 정책 데이터
  final Map<String, List<Map<String, dynamic>>> _policyData = {
    '창업 지원': [
      {
        'id': 'startup_1',
        'title': '청년창업사관학교',
        'description': '청년들의 창업 아이디어를 실현할 수 있도록 지원하는 프로그램',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '최대 5천만원',
        'status': '신청가능',
      },
      {
        'id': 'startup_2',
        'title': '창업도약패키지',
        'description': '창업 초기 단계의 청년들을 위한 종합 지원 프로그램',
        'deadline': '2024.11.30',
        'location': '서울, 부산, 대구',
        'amount': '최대 3천만원',
        'status': '신청가능',
      },
      {
        'id': 'startup_3',
        'title': '스타트업 인큐베이팅',
        'description': '혁신적인 스타트업을 위한 사무공간 및 멘토링 지원',
        'deadline': '2024.10.31',
        'location': '전국',
        'amount': '사무공간 무료 제공',
        'status': '마감임박',
      },
    ],
    '주거 지원': [
      {
        'id': 'housing_1',
        'title': '청년주택공급',
        'description': '청년들을 위한 전용 임대주택 공급',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '시세 대비 70%',
        'status': '신청가능',
      },
      {
        'id': 'housing_2',
        'title': '전세자금대출',
        'description': '청년 전세자금 대출 지원',
        'deadline': '상시',
        'location': '전국',
        'amount': '최대 1억원',
        'status': '신청가능',
      },
    ],
    '교육·훈련비 지원': [
      {
        'id': 'education_1',
        'title': '국비지원 교육과정',
        'description': '취업에 도움이 되는 다양한 교육과정 지원',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '교육비 100% 지원',
        'status': '신청가능',
      },
      {
        'id': 'education_2',
        'title': '자격증 취득 지원',
        'description': '취업에 유리한 자격증 취득 비용 지원',
        'deadline': '2024.11.30',
        'location': '전국',
        'amount': '최대 100만원',
        'status': '신청가능',
      },
    ],
    '금융 지원': [
      {
        'id': 'finance_1',
        'title': '청년도약계좌',
        'description': '청년들의 자산 형성을 위한 특별 계좌',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '최대 5천만원',
        'status': '신청가능',
      },
      {
        'id': 'finance_2',
        'title': '청년대출',
        'description': '청년들을 위한 저금리 대출',
        'deadline': '상시',
        'location': '전국',
        'amount': '최대 3천만원',
        'status': '신청가능',
      },
    ],
    '생활·복지 지원': [
      {
        'id': 'welfare_1',
        'title': '청년수당',
        'description': '청년들의 기본생활을 지원하는 수당',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '월 30만원',
        'status': '신청가능',
      },
      {
        'id': 'welfare_2',
        'title': '문화바우처',
        'description': '청년들의 문화생활을 지원하는 바우처',
        'deadline': '2024.11.30',
        'location': '전국',
        'amount': '연 10만원',
        'status': '신청가능',
      },
    ],
    '취업 지원': [
      {
        'id': 'job_1',
        'title': '청년취업지원',
        'description': '청년들의 취업을 위한 종합 지원 프로그램',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '취업성공수당 지급',
        'status': '신청가능',
      },
      {
        'id': 'job_2',
        'title': '인턴십 지원',
        'description': '기업 인턴십 참여를 위한 지원',
        'deadline': '2024.11.30',
        'location': '전국',
        'amount': '월 100만원',
        'status': '신청가능',
      },
    ],
  };

  List<Map<String, dynamic>> get filteredPolicies {
    final policies = _policyData[widget.category] ?? [];
    if (_searchQuery.isEmpty) {
      return policies;
    }
    return policies.where((policy) {
      return policy['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             policy['description'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // 하트 버튼 클릭 시 처리
  void _toggleFavorite(Map<String, dynamic> policy) {
    setState(() {
      final policyId = policy['id'];
      if (_dataManager.isBookmarked(policyId)) {
        // 즐겨찾기에서 제거
        _dataManager.removeBookmark(policyId);
      } else {
        // 즐겨찾기에 추가
        _addToBookmarks(policy);
        
        // 마감일이 오늘보다 뒤면 캘린더에 추가
        _addToCalendar(policy);
      }
    });
  }

  // 즐겨찾기에 추가
  void _addToBookmarks(Map<String, dynamic> policy) {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final bookmarkItem = BookmarkItem(
      title: policy['title'],
      description: policy['description'],
      time: timeString,
      id: policy['id'],
      isPinned: false,
      detailData: BookmarkDetailData(
        title: policy['title'],
        bannerTitle: widget.category,
        bannerSubtitle: policy['title'],
        description: policy['description'],
        leftAmount: policy['amount'],
        rightAmount: policy['deadline'],
        leftColor: getEventTypeColor(widget.category),
        rightColor: Colors.grey,
      ),
    );
    
    // DataManager에 저장
    _dataManager.addBookmark(bookmarkItem);
    print('즐겨찾기에 추가됨: ${policy['title']}');
  }

  // 캘린더에 추가
  void _addToCalendar(Map<String, dynamic> policy) {
    final deadline = policy['deadline'];
    if (deadline == '상시') return; // 상시 신청은 캘린더에 추가하지 않음
    
    try {
      final deadlineDate = DateTime.parse(deadline.replaceAll('.', '-'));
      final today = DateTime.now();
      
      // 마감일이 오늘보다 뒤면 캘린더에 추가
      if (deadlineDate.isAfter(today)) {
        final event = Event(
          id: DateTime.now().millisecondsSinceEpoch,
          title: policy['title'],
          time: '${deadlineDate.hour.toString().padLeft(2, '0')}:${deadlineDate.minute.toString().padLeft(2, '0')}',
          description: '${policy['description']} (마감일: ${policy['deadline']})',
          eventType: widget.category,
          date: deadlineDate,
        );
        
        // DataManager에 저장
        _dataManager.addEvent(event);
        print('캘린더에 추가됨: ${policy['title']} (마감일: ${policy['deadline']})');
      }
    } catch (e) {
      print('날짜 파싱 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '정책 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // 정책 목록
          Expanded(
            child: filteredPolicies.isEmpty
                ? const Center(
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPolicies.length,
                    itemBuilder: (context, index) {
                      final policy = filteredPolicies[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      policy['title'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // 하트 버튼 추가
                                  GestureDetector(
                                    onTap: () => _toggleFavorite(policy),
                                    child: Icon(
                                      _dataManager.isBookmarked(policy['id'])
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _dataManager.isBookmarked(policy['id'])
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: policy['status'] == '신청가능'
                                          ? Colors.green[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      policy['status'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: policy['status'] == '신청가능'
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                policy['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    policy['location'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    policy['amount'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '마감: ${policy['deadline']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                                                             Row(
                                 children: [
                                   Expanded(
                                     child: OutlinedButton(
                                       onPressed: () {
                                         Navigator.push(
                                           context,
                                           MaterialPageRoute(
                                             builder: (context) => PolicyDetailPage(
                                               policy: policy,
                                             ),
                                           ),
                                         );
                                       },
                                       style: OutlinedButton.styleFrom(
                                         side: BorderSide(color: Colors.blue[300]!),
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(8),
                                         ),
                                       ),
                                       child: const Text(
                                         '상세보기',
                                         style: TextStyle(color: Colors.blue),
                                       ),
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   Expanded(
                                     child: ElevatedButton(
                                       onPressed: () {
                                         Navigator.push(
                                           context,
                                           MaterialPageRoute(
                                             builder: (context) => PolicyDetailPage(
                                               policy: policy,
                                             ),
                                           ),
                                         );
                                       },
                                       style: ElevatedButton.styleFrom(
                                         backgroundColor: Colors.blue,
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(8),
                                         ),
                                       ),
                                       child: const Text(
                                         '신청하기',
                                         style: TextStyle(color: Colors.white),
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
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