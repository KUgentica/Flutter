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
  
  List<Policy> _searchResults = [];
  Set<String> _bookmarkedPolicies = {}; // 북마크된 정책 ID들을 저장
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isSearching = false;

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

  Future<void> _showBookmarkDialog(Policy policy) async {
    final isCurrentlyBookmarked = _bookmarkedPolicies.contains(policy.id);
    
    if (isCurrentlyBookmarked) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('알림'),
            content: const Text('이미 즐겨찾기에 등록되어 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    } else {
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('즐겨찾기 추가'),
            content: const Text('즐겨찾기 및 캘린더에 추가하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('예'),
              ),
            ],
          );
        },
      );

      if (shouldAdd == true) {
        _toggleBookmark(policy);
      }
    }
  }

  Future<void> _toggleBookmark(Policy policy) async {
    final itemId = policy.id;
    final isCurrentlyBookmarked = _bookmarkedPolicies.contains(itemId);

    setState(() {
      if (isCurrentlyBookmarked) {
        _bookmarkedPolicies.remove(itemId);
      } else {
        _bookmarkedPolicies.add(itemId);
      }
    });

    bool success;
    if (isCurrentlyBookmarked) {
      success = await BookmarkService.removeBookmark(itemId);
    } else {
      success = await BookmarkService.saveBookmark(
        itemId: itemId,
        itemType: 'POLICY',
        title: policy.title,
        description: policy.description,
        deadline: policy.deadline,
      );
    }

    if (!success) {
      setState(() {
        if (isCurrentlyBookmarked) {
          _bookmarkedPolicies.add(itemId);
        } else {
          _bookmarkedPolicies.remove(itemId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyBookmarked ? '북마크 제거에 실패했습니다.' : '북마크 저장에 실패했습니다.'),
          ),
        );
      }
    } else {
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

          Expanded(
            child: _hasSearched && !_isSearching
                ? _buildSearchResults()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

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
                  onTap: () => _showBookmarkDialog(policy),
                  child: Icon(
                    Icons.bookmark_border,
                    color: Colors.grey,
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