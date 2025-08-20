import 'package:flutter/material.dart';
import '../models/policy.dart';
import '../services/policy_service.dart';
import '../services/bookmark_service.dart';
import 'detail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // --- State Variables ---
  List<Policy> _searchResults = [];
  Set<String> _bookmarkedPolicies = {}; // 북마크된 정책 ID들을 저장
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isSearching = false;

  // 날짜 파싱 유틸 (첫 번째 코드에서 가져옴)
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

  String _deadlineLabelOf(Policy policy) {
    final deadline = policy.deadline.trim();
    if (deadline.isEmpty) return '상시 접수';
    if (deadline == '상시') return '상시 접수';
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
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- Data Handling ---

  /// 북마크 상태를 토글하는 함수
  Future<void> _toggleBookmark(Policy policy) async {
    final itemId = policy.id;
    final isCurrentlyBookmarked = _bookmarkedPolicies.contains(itemId);

    // 낙관적 업데이트: UI를 먼저 변경
    setState(() {
      if (isCurrentlyBookmarked) {
        _bookmarkedPolicies.remove(itemId);
      } else {
        _bookmarkedPolicies.add(itemId);
      }
    });

    bool success;
    if (isCurrentlyBookmarked) {
      // 북마크 제거
      success = await BookmarkService.removeBookmark(itemId);
    } else {
      // 북마크 저장
      success = await BookmarkService.saveBookmark(
        itemId: itemId,
        itemType: 'POLICY',
        title: policy.title,
        description: policy.description,
      );
    }

    if (!success) {
      // API 호출 실패 시 UI 롤백
      setState(() {
        if (isCurrentlyBookmarked) {
          _bookmarkedPolicies.add(itemId);
        } else {
          _bookmarkedPolicies.remove(itemId);
        }
      });

      // 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyBookmarked ? '북마크 제거에 실패했습니다.' : '북마크 저장에 실패했습니다.'),
          ),
        );
      }
    } else {
      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyBookmarked ? '북마크가 제거되었습니다.' : '북마크에 저장되었습니다.'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _loadRecommendedPolicies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final policies = await PolicyService.getRecommendedPolicies();
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

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final policies = await PolicyService.searchPolicies(query);
      
      if (query.trim() != _searchController.text.trim()) {
        setState(() {
          _isSearching = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _searchResults = policies;
        _hasSearched = true;
        _isSearching = false;
        _isLoading = false;
      });
    } catch (e) {
      print('검색 실패: $e');
      setState(() {
        _isSearching = false;
        _isLoading = false;
      });
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
                if (value.isNotEmpty) {
                  _performSearch(value);
                } else {
                  setState(() {
                    _hasSearched = false;
                    _searchResults = [];
                  });
                }
              },
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

          // 검색 결과
          Expanded(
            child: _hasSearched && !_isSearching
                ? _buildSearchResults()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '검색어를 입력해주세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
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
              return _buildPolicyCard(policy);
            },
          ),
        ),
      ],
    );
  }

  // 정책 카드 위젯 - 북마크 기능 및 신청하기 버튼 제거
  Widget _buildPolicyCard(Policy policy) {
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
                    policy.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleBookmark(policy),
                  child: Icon(
                    _bookmarkedPolicies.contains(policy.id) 
                        ? Icons.favorite 
                        : Icons.favorite_border,
                    color: _bookmarkedPolicies.contains(policy.id) 
                        ? Colors.red 
                        : Colors.grey,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (policy.description.isNotEmpty)
              Text(
                policy.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(deadlineLabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            // 신청하기 버튼 제거하고 상세보기 버튼만 유지
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PolicyDetailPage(policy: policy.toMap()),
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
          ],
        ),
      ),
    );
  }
}