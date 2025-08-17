import 'package:flutter/material.dart';
import 'detail.dart';
import 'bookmark.dart';
import 'calendar.dart';
import 'data_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  List<Map<String, dynamic>> _policies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPolicies();
  }

  Future<void> fetchPolicies() async {
    String keyword;
    switch (widget.category) {
      case '창업 지원':
        keyword = '창업';
        break;
      case '주거 지원':
        keyword = '주거';
        break;
      case '교육·훈련비 지원':
        keyword = '교육';
        break;
      case '금융 지원':
        keyword = '금융';
        break;
      case '생활·복지 지원':
        keyword = '생활';
        break;
      case '취업 지원':
        keyword = '취업';
        break;
      default:
        keyword = widget.category;
    }
    final url = 'http://10.0.2.2:8080/policy/category?keyword=$keyword';
    try {
      final response = await http.get(Uri.parse(url));
      print('=== [LOG] API 요청: $url');
      print('=== [LOG] 응답 상태 코드: ${response.statusCode}');
      print('=== [LOG] 응답 본문: ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          _policies = List<Map<String, dynamic>>.from(json.decode(utf8.decode(response.bodyBytes)));
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('=== [LOG] API 요청 에러: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredPolicies {
    if (_searchQuery.isEmpty) {
      return _policies;
    }
    return _policies.where((policy) {
      return (policy['plcyTitle'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (policy['plcyExplnCn'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredPolicies.isEmpty
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
                                          policy['plcyTitle'] ?? '제목 없음',
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
                                          color: policy['plcyStatus'] == '신청가능'
                                              ? Colors.green[100]
                                              : Colors.orange[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          policy['plcyStatus'] ?? '상태 없음',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: policy['plcyStatus'] == '신청가능'
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
                                    policy['plcyExplnCn'] ?? '설명 없음',
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
                                        policy['plcyLctr'] ?? '위치 없음',
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
                                        policy['plcyAmt'] ?? '금액 없음',
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
                                        '마감: ${policy['plcyDd'] ?? '날짜 없음'}',
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