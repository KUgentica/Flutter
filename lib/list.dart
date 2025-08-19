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

  bool get isCenter => widget.category == '청년 센터';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (isCenter) {
      await fetchCenters();
    } else {
      await fetchPolicies();
    }
  }

  Future<void> fetchPolicies() async {
    String keyword;
    switch (widget.category) {
      case '청년 센터':
        keyword = '센터';
        break;
      case '보조금':
        keyword = '보조금';
        break;
      case '주거지원':
        keyword = '주거';
        break;
      case '해외진출':
        keyword = '해외';
        break;
      case '교육지원':
        keyword = '교육';
        break;
      case '맞춤형상담서비스':
        keyword = '상담';
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
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          setState(() {
            _policies = List<Map<String, dynamic>>.from(decoded as List<dynamic>);
            _isLoading = false;
          });
        } else {
          print('=== [LOG][ERR] 정책 응답이 List가 아닙니다: ${decoded.runtimeType}');
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('=== [LOG] API 요청 에러: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 청년 센터 전용 API
  Future<void> fetchCenters() async {
    final url = 'http://10.0.2.2:8080/policy/center';
    try {
      final response = await http.get(Uri.parse(url));
      print('=== [LOG] CENTER 요청: $url');
      print('=== [LOG] CENTER 응답 코드: ${response.statusCode}');
      print('=== [LOG] CENTER 본문: ${response.body}');
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          setState(() {
            _policies = List<Map<String, dynamic>>.from(decoded as List<dynamic>);
            _isLoading = false;
          });
        } else {
          print('=== [LOG][ERR] 센터 응답이 List가 아닙니다: ${decoded.runtimeType}');
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('=== [LOG] CENTER 요청 에러: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 문자열 → DateTime (YYYYMMDD)
  DateTime? _parseYMD(String v) {
    final s = v.trim();
    if (s.length != 8) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(4, 6));
    final d = int.tryParse(s.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// 문자열 → DateTime (YYYY-MM-DD / YYYY.MM.DD 등)
  DateTime? _parseFlexibleDate(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final normalized = s.replaceAll('.', '-').replaceAll(RegExp(r'[^0-9\-]'), '');
    try {
      final iso = normalized.length >= 10 ? normalized.substring(0, 10) : normalized;
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  /// "YYYYMMDD ~ YYYYMMDD" 또는 단일 날짜 문자열에서 마감일(오른쪽 날짜)을 추출
  DateTime? _endDateFromDeadline(String s) {
    final str = s.trim();
    if (str.contains('~')) {
      final endRaw = str.split('~').last.trim();
      if (RegExp(r'^\d{8}$').hasMatch(endRaw)) return _parseYMD(endRaw);
      return _parseFlexibleDate(endRaw);
    } else {
      if (RegExp(r'^\d{8}$').hasMatch(str)) return _parseYMD(str);
      return _parseFlexibleDate(str);
    }
  }

  /// 센터/정책을 공통 형태로 정규화
  Map<String, dynamic> _normalizeItem(Map<String, dynamic> p) {
    if (isCenter) {
      final addr = (p['cntrAddr'] ?? '').toString();
      final daddr = (p['cntrDaddr'] ?? '').toString();
      final fullAddr = [addr, daddr].where((e) => e.isNotEmpty).join(' ');
      return {
        'id':        (p['id'] ?? p['cntrSn'] ?? '').toString(),
        'title':     (p['cntrNm'] ?? '(이름 없음)').toString(),
        'description': fullAddr.isEmpty ? '주소 정보 없음' : fullAddr,
        'location':  fullAddr,
        'phone':     (p['cntrTelno'] ?? '').toString(),
        'amount':    '',
        'deadline':  '',
        'status':    '',
        'type':      'center',
        '_raw': p,
      };
    } else {
      final aplyYmd  = (p['aplyYmd'] ?? '').toString();                   // "YYYYMMDD ~ YYYYMMDD"
      final plcyDd   = (p['plcyDd'] ?? p['deadline'] ?? '').toString();   // 단일일자
      final deadline = aplyYmd.isNotEmpty ? aplyYmd : (plcyDd.isNotEmpty ? plcyDd : '상시');

      return {
        'id':         (p['id'] ?? p['plcyId'] ?? p['plcyNo'] ?? p['policyId'] ?? '').toString(),
        'title':      (p['plcyTitle'] ?? p['title'] ?? '(제목 없음)').toString(),
        'description': (p['plcyExplnCn'] ?? p['description'] ?? '').toString(),
        'location':   (p['plcyLctr'] ?? p['location'] ?? '').toString(),
        'phone':      (p['phone'] ?? '').toString(),
        'amount':     (p['plcyAmt'] ?? p['amount'] ?? '').toString(),
        'deadline':   deadline,              // 범위 > 단일 > 상시
        'applyRange': aplyYmd,               // 원본 범위 보관
        'status':     (p['plcyStatus'] ?? p['status'] ?? '').toString(),
        'type':       'policy',
        '_raw': p,
      };
    }
  }

  List<Map<String, dynamic>> get filteredPolicies {
    if (_searchQuery.isEmpty) return _policies;
    final q = _searchQuery.toLowerCase();
    return _policies.where((policy) {
      if (isCenter) {
        final name  = (policy['cntrNm'] ?? '').toString().toLowerCase();
        final addr  = (policy['cntrAddr'] ?? '').toString().toLowerCase();
        final daddr = (policy['cntrDaddr'] ?? '').toString().toLowerCase();
        return name.contains(q) || addr.contains(q) || daddr.contains(q);
      } else {
        final title = (policy['plcyTitle'] ?? policy['title'] ?? '').toString().toLowerCase();
        final desc  = (policy['plcyExplnCn'] ?? policy['description'] ?? '').toString().toLowerCase();
        return title.contains(q) || desc.contains(q);
      }
    }).toList();
  }

  // 하트 버튼 클릭 시 처리 (센터는 캘린더 추가 생략)
  void _toggleFavorite(Map<String, dynamic> raw) {
    final n = _normalizeItem(raw);
    setState(() {
      final policyId = n['id'];
      if (_dataManager.isBookmarked(policyId)) {
        _dataManager.removeBookmark(policyId);
      } else {
        _addToBookmarks(n);
        if (n['type'] != 'center') {
          _addToCalendar(n);
        }
      }
    });
  }

  // 즐겨찾기에 추가 (정규화된 맵 기준)
  void _addToBookmarks(Map<String, dynamic> n) {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final bookmarkItem = BookmarkItem(
      title: n['title'],
      description: (n['description'] as String?)?.isNotEmpty == true ? n['description'] : n['location'],
      time: timeString,
      id: n['id'],
      isPinned: false,
      detailData: BookmarkDetailData(
        title: n['title'],
        bannerTitle: widget.category,
        bannerSubtitle: n['title'],
        description: n['description'],
        leftAmount: n['amount'],
        rightAmount: n['deadline'],
        leftColor: getEventTypeColor(widget.category),
        rightColor: Colors.grey,
      ),
    );

    _dataManager.addBookmark(bookmarkItem);
    print('즐겨찾기에 추가됨: ${n['title']}');
  }

  // 캘린더에 추가 (정규화된 맵 기준, 센터는 호출 안 함)
  void _addToCalendar(Map<String, dynamic> n) {
    final deadline = n['deadline']?.toString() ?? '상시';
    if (deadline == '상시' || deadline.trim().isEmpty) return;

    try {
      final deadlineDate = _endDateFromDeadline(deadline);
      if (deadlineDate == null) return;

      final today = DateTime.now();
      if (deadlineDate.isAfter(today)) {
        final event = Event(
          id: DateTime.now().millisecondsSinceEpoch,
          title: n['title'],
          time: '${deadlineDate.hour.toString().padLeft(2, '0')}:${deadlineDate.minute.toString().padLeft(2, '0')}',
          description: '${n['description'] ?? ''} (마감: $deadline)',
          eventType: widget.category,
          date: deadlineDate,
        );
        _dataManager.addEvent(event);
        print('캘린더에 추가됨: ${n['title']} (마감: $deadline)');
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
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: isCenter ? '센터 이름/주소 검색' : '정책 제목/설명 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPolicies.isEmpty
                    ? const Center(
                        child: Text('검색 결과가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredPolicies.length,
                          itemBuilder: (context, index) {
                            final raw = filteredPolicies[index];
                            final n = _normalizeItem(raw); // 공통 키로 사용

                            final titleText    = (n['title'] ?? '제목 없음').toString();
                            final descText     = (n['description'] ?? '').toString();
                            final locationText = (n['location'] ?? '').toString();
                            final amountText   = (n['amount'] ?? '').toString();
                            final deadlineText = (n['deadline'] ?? '').toString();
                            final statusText   = (n['status'] ?? '').toString();
                            final phoneText    = (n['phone'] ?? '').toString();
                            final applyRange   = (n['applyRange'] ?? '').toString();

                            // 기간/마감 라벨 구성: 범위가 있으면 범위 우선
                            final deadlineLabel = applyRange.isNotEmpty
                                ? '신청 기간: $applyRange'
                                : (deadlineText.isNotEmpty && deadlineText != '상시'
                                    ? '마감: $deadlineText'
                                    : (deadlineText == '상시' ? '상시 접수' : ''));

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
                                            titleText,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        // 하트 버튼
                                        GestureDetector(
                                          onTap: () => _toggleFavorite(raw),
                                          child: Icon(
                                            _dataManager.isBookmarked(n['id'])
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: _dataManager.isBookmarked(n['id']) ? Colors.red : Colors.grey,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // 정책 상태 배지 (센터는 없음)
                                        if (statusText.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusText == '신청가능' ? Colors.green[100] : Colors.orange[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: statusText == '신청가능' ? Colors.green[700] : Colors.orange[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),
                                    if (descText.isNotEmpty)
                                      Text(descText, style: TextStyle(fontSize: 14, color: Colors.grey[600])),

                                    const SizedBox(height: 12),

                                    if (locationText.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              locationText,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                            ),
                                          ),
                                        ],
                                      ),

                                    if (phoneText.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          children: [
                                            Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(phoneText, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                          ],
                                        ),
                                      ),

                                    if (amountText.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          children: [
                                            Icon(Icons.attach_money, size: 16, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(amountText, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                          ],
                                        ),
                                      ),

                                    if (deadlineLabel.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          children: [
                                            Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              deadlineLabel,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 12),

                                    // 정책일 때만 상세/신청 버튼 및 네비게이션
                                    if (n['type'] == 'policy')
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PolicyDetailPage(policy: n),
                                                  ),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: Colors.blue[300]!),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('상세보기', style: TextStyle(color: Colors.blue)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PolicyDetailPage(policy: n),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('신청하기', style: TextStyle(color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    // 센터(type == 'center')는 버튼 없음 → detail 이동하지 않음
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
    case '청년 센터':
      return const Color(0xFF4CAF50);
    case '주거 지원':
      return const Color(0xFF2196F3);
    case '교육·훈련비 지원':
      return const Color(0xFFFF9800);
    case '금융 지원':
      return const Color(0xFF8BC34A);
    case '생활·복지 지원':
      return const Color(0xFF9C27B0);
    case '취업 지원':
      return const Color(0xFFF44336);
    default:
      return const Color(0xFF5B9EE1);
  }
}
