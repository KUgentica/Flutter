import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'list.dart';
import 'detail.dart';
import 'services/policy_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isLoading = false;

  // 날짜 파싱 유틸 (카테고리 리스트와 동일한 포맷 표시에 사용)
  DateTime? _parseYMD(String v) {
    final s = v.trim();
    if (s.length != 8) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(4, 6));
    final d = int.tryParse(s.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

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

  String _deadlineLabelOf(Map<String, dynamic> p) {
    final aplyYmd = (p['aplyYmd'] ?? '').toString().trim();
    final deadline = (p['deadline'] ?? '').toString().trim();
    if (aplyYmd.isNotEmpty) {
      return '신청 기간: $aplyYmd';
    }
    if (deadline.isEmpty) return '상시 접수';
    if (deadline == '상시') return '상시 접수';
    // 단일 마감일 텍스트가 들어온 경우
    final d = _parseFlexibleDate(deadline);
    if (d == null) return '마감: $deadline';
    final now = DateTime.now();
    if (now.isAfter(d.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)))) {
      return '마감: $deadline';
    }
    return '마감일: $deadline';
  }

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.requestFocus();
    _loadRecommendedPolicies(); // 실제 추천 정책 로드
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 검색 기록 로드
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      print('검색 기록 로드 실패: $e');
    }
  }

  // 검색 기록 저장
  Future<void> _saveSearchHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('search_history') ?? [];
      
      // 중복 제거
      history.remove(query);
      
      // 맨 앞에 추가 (최신순)
      history.insert(0, query);
      
      // 최대 10개까지만 저장
      if (history.length > 10) {
        history = history.take(10).toList();
      }
      
      await prefs.setStringList('search_history', history);
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      print('검색 기록 저장 실패: $e');
    }
  }

  // 실제 추천 정책 로드
  Future<void> _loadRecommendedPolicies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final policies = await PolicyService.getRecommendedPolicies();
      // 사용자가 타이핑을 시작했으면 추천 적용하지 않음 (레이스 컨디션 방지)
      if (_searchController.text.trim().isEmpty) {
        setState(() {
          _searchResults = policies;
          _hasSearched = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('추천 정책 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 실제 검색 수행
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadRecommendedPolicies();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      // 정책과 센터 모두 검색
      final policyResults = await PolicyService.searchPolicies(query);
      final centerResults = await PolicyService.searchCenters(query);
      
      // 현재 입력한 값과 결과가 맞는지 확인 (레이스 컨디션 방지)
      if (query.trim() != _searchController.text.trim()) {
        // 사용자가 이미 다른 검색을 입력함 → 이 결과는 버림
        setState(() {
          _isSearching = false;
          _isLoading = false;
        });
        return;
      }

      // 센터 결과를 정책 형식으로 변환
      final convertedCenterResults = centerResults.map((center) {
        return {
          'id': center['id'],
          'title': center['name'],
          'description': '${center['address']} ${center['detailAddress']}',
          'category': '청년센터',
          'deadline': '상시',
          'location': center['address'],
          'amount': '무료',
          'status': '이용가능',
          'phone': center['phone'],
          'url': center['url'],
          'isCenter': true, // 센터임을 표시
        };
      }).toList();

      // 결과 합치기
      final allResults = [...policyResults, ...convertedCenterResults];
      
      setState(() {
        _searchResults = allResults;
        _hasSearched = true;
        _isSearching = false;
        _isLoading = false;
      });
      
      // 검색 기록 저장 (빈 검색어가 아닐 때만)
      if (query.trim().isNotEmpty) {
        _saveSearchHistory(query);
      }
    } catch (e) {
      print('검색 실패: $e');
      setState(() {
        _isSearching = false;
        _isLoading = false;
      });
    }
  }

  // 검색 기록 삭제
  Future<void> _deleteSearchHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('search_history') ?? [];
      history.remove(query);
      await prefs.setStringList('search_history', history);
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      print('검색 기록 삭제 실패: $e');
    }
  }

  // 검색 기록 전체 삭제
  Future<void> _clearAllSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      setState(() {
        _searchHistory = [];
      });
    } catch (e) {
      print('검색 기록 전체 삭제 실패: $e');
    }
  }

  // 검색 결과로 이동
  void _navigateToSearchResults(String query) {
    _performSearch(query);
    // 검색 결과가 있으면 리스트 화면으로 이동
    if (_searchResults.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PolicyListPage(
            category: '검색 결과: $query',
            categoryData: {'title': '검색 결과', 'icon': Icons.search, 'color': Colors.blue},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정책 검색'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색창
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '정책명, 카테고리로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _hasSearched = false;
                            _searchResults = [];
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  _loadRecommendedPolicies(); // 빈 검색어일 때 추천 정책 표시
                } else {
                  _performSearch(value); // 실시간 검색
                }
              },
              // 엔터(Submit) 무시: 별도 동작 없음
              onSubmitted: (_) {},
            ),
          ),

          // 검색 중 표시
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('검색 중...'),
                ],
              ),
            ),

          // 검색 결과 또는 검색 기록
          Expanded(
            child: _hasSearched && !_isSearching
                ? _buildSearchResults()
                : _buildSearchHistory(),
          ),
        ],
      ),
    );
  }

  // 검색 기록 위젯
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '검색 기록이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '최근 검색어',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(query),
                trailing: IconButton(
                  onPressed: () => _deleteSearchHistory(query),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
                onTap: () {
                  _searchController.text = query;
                  _navigateToSearchResults(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 검색 결과 위젯
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '검색 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '다른 키워드로 검색해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _searchController.text.isEmpty 
                ? '추천 정책 (${_searchResults.length}개)'
                : '검색 결과 (${_searchResults.length}개)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final policy = _searchResults[index];
              final bool isCenter = policy['isCenter'] == true;

              // 카테고리 화면과 동일한 카드 UI
              final deadlineLabel = _deadlineLabelOf(policy);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              policy['title'] ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(isCenter ? Icons.location_city : Icons.favorite_border, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((policy['description'] ?? '').toString().isNotEmpty)
                        Text((policy['description'] ?? '').toString(), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(deadlineLabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                if (isCenter) return; // 센터는 상세 없음
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PolicyDetailPage(policy: policy),
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
                                if (isCenter) return; // 센터는 신청 버튼 없음
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PolicyDetailPage(policy: policy),
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 