import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'list.dart';

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

  // 카테고리별 샘플 정책 데이터 (실제로는 API에서 가져올 것)
  final Map<String, List<Map<String, dynamic>>> _allPolicies = {
    '창업': [
      {
        'title': '청년창업사관학교',
        'description': '청년들의 창업 아이디어를 실현할 수 있도록 지원하는 프로그램',
        'category': '창업 지원',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '최대 5천만원',
        'status': '신청가능',
      },
      {
        'title': '창업도약패키지',
        'description': '창업 초기 단계의 청년들을 위한 종합 지원 프로그램',
        'category': '창업 지원',
        'deadline': '2024.11.30',
        'location': '서울, 부산, 대구',
        'amount': '최대 3천만원',
        'status': '신청가능',
      },
    ],
    '주거': [
      {
        'title': '청년주택공급',
        'description': '청년들을 위한 전용 임대주택 공급',
        'category': '주거 지원',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '시세 대비 70%',
        'status': '신청가능',
      },
      {
        'title': '전세자금대출',
        'description': '청년 전세자금 대출 지원',
        'category': '주거 지원',
        'deadline': '상시',
        'location': '전국',
        'amount': '최대 1억원',
        'status': '신청가능',
      },
    ],
    '교육': [
      {
        'title': '국비지원 교육과정',
        'description': '취업에 도움이 되는 다양한 교육과정 지원',
        'category': '교육·훈련비 지원',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '교육비 100% 지원',
        'status': '신청가능',
      },
      {
        'title': '자격증 취득 지원',
        'description': '취업에 유리한 자격증 취득 비용 지원',
        'category': '교육·훈련비 지원',
        'deadline': '2024.11.30',
        'location': '전국',
        'amount': '최대 100만원',
        'status': '신청가능',
      },
    ],
    '금융': [
      {
        'title': '청년도약계좌',
        'description': '청년들의 자산 형성을 위한 특별 계좌',
        'category': '금융 지원',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '최대 5천만원',
        'status': '신청가능',
      },
      {
        'title': '청년대출',
        'description': '청년들을 위한 저금리 대출',
        'category': '금융 지원',
        'deadline': '상시',
        'location': '전국',
        'amount': '최대 3천만원',
        'status': '신청가능',
      },
    ],
    '생활': [
      {
        'title': '청년수당',
        'description': '청년들의 기본생활을 지원하는 수당',
        'category': '생활·복지 지원',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '월 30만원',
        'status': '신청가능',
      },
      {
        'title': '문화바우처',
        'description': '청년들의 문화생활을 지원하는 바우처',
        'category': '생활·복지 지원',
        'deadline': '2024.11.30',
        'location': '전국',
        'amount': '연 10만원',
        'status': '신청가능',
      },
    ],
    '취업': [
      {
        'title': '청년취업지원',
        'description': '청년들의 취업을 위한 종합 지원 프로그램',
        'category': '취업 지원',
        'deadline': '2024.12.31',
        'location': '전국',
        'amount': '취업성공수당 지급',
        'status': '신청가능',
      },
      {
        'title': '인턴십 지원',
        'description': '기업 인턴십 참여를 위한 지원',
        'category': '취업 지원',
        'deadline': '2024.11.30',
        'location': '전국',
        'amount': '월 100만원',
        'status': '신청가능',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.requestFocus();
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

  // 검색 실행
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    // 검색 기록 저장
    _saveSearchHistory(query);

    // 검색 로직 (카테고리 기반 검색)
    List<Map<String, dynamic>> results = [];
    
    for (String category in _allPolicies.keys) {
      if (category.contains(query) || query.contains(category)) {
        results.addAll(_allPolicies[category]!);
      }
    }

    // 제목이나 설명에서도 검색
    for (String category in _allPolicies.keys) {
      for (var policy in _allPolicies[category]!) {
        if (policy['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
            policy['description'].toString().toLowerCase().contains(query.toLowerCase())) {
          if (!results.contains(policy)) {
            results.add(policy);
          }
        }
      }
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
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
        actions: [
          if (_searchHistory.isNotEmpty)
            TextButton(
              onPressed: _clearAllSearchHistory,
              child: const Text(
                '전체 삭제',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
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
                  setState(() {
                    _hasSearched = false;
                    _searchResults = [];
                  });
                }
              },
              onSubmitted: (value) {
                _navigateToSearchResults(value);
              },
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
            '검색 결과 (${_searchResults.length}개)',
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
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    policy['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(policy['description']),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              policy['category'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            policy['amount'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PolicyListPage(
                          category: policy['category'],
                          categoryData: {
                            'title': policy['category'],
                            'icon': Icons.policy,
                            'color': Colors.blue,
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 