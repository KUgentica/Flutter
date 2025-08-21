import 'package:flutter/material.dart';
// Center 모델 및 서비스 import
import '../models/center.dart' as center_model;
import '../services/center_api_service.dart';

// 기존 Policy 관련 import
import '../models/policy.dart';
import '../models/bookmarkItem.dart';
import '../services/policy_service.dart';
import '../services/bookmark_service.dart';
import 'detail.dart';

class PolicyListPage extends StatefulWidget {
  final String category;

  const PolicyListPage({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<PolicyListPage> createState() => _PolicyListPageState();
}

class _PolicyListPageState extends State<PolicyListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  List<dynamic> _items = [];
  Set<String> _bookmarkedItemIds = {};

  bool get isCenter => widget.category == '청년 센터';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final itemsFuture = isCenter
          ? CenterApiService.getCenters()
          : PolicyService.searchPolicies(widget.category);

      final bookmarksFuture = BookmarkService.getBookmarks();
      final results = await Future.wait([itemsFuture, bookmarksFuture]);

      final items = results[0] as List<dynamic>;
      final bookmarks = results[1] as List<BookmarkItem>;

      if (!mounted) return;

      setState(() {
        _items = items;
        _bookmarkedItemIds = bookmarks.map((b) => b.item.id as String).toSet();
        _isLoading = false;
      });
    } catch (e) {
      print('💥 Failed to load initial data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    }

  void _showBookmarkDialog(dynamic item) async {
    if (item.id == null || item.id.isEmpty) {
      print('🚨 에러: item ID가 비어있습니다.');
      return;
    }

    final isCurrentlyBookmarked = _bookmarkedItemIds.contains(item.id);
    
    if (isCurrentlyBookmarked) {
      // 이미 북마크된 경우 "이미 등록되어 있습니다" 다이얼로그 표시
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
      // 북마크되지 않은 경우 확인 다이얼로그 표시
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
        _toggleFavorite(item);
      }
    }
  }

  void _toggleFavorite(dynamic item) async {
  // --- 🐞 디버깅 시작 ---
  print('--- ⭐️ 즐겨찾기 토글 시작 ⭐️ ---');
  if (item.id == null || item.id.isEmpty) {
    print('🚨 에러: item ID가 비어있습니다.');
    return;
  }
  
  final itemId = item.id;
  print('1. 토글 대상 ID: $itemId');
  print('2. 현재 즐겨찾기 목록: $_bookmarkedItemIds');
  
  // isCurrentlyBookmarked가 항상 false로 나오는지 확인하는 것이 핵심입니다.
  final isCurrentlyBookmarked = _bookmarkedItemIds.contains(itemId);
  print('3. 현재 즐겨찾기 여부 (isCurrentlyBookmarked): $isCurrentlyBookmarked');

  // UI 낙관적 업데이트 (Optimistic Update)
  setState(() {
    if (isCurrentlyBookmarked) {
      print('4. UI 업데이트: 즐겨찾기에서 "제거"합니다.');
      _bookmarkedItemIds.remove(itemId);
    } else {
      print('4. UI 업데이트: 즐겨찾기에 "추가"합니다.');
      _bookmarkedItemIds.add(itemId);
    }
  });

  bool success;
  if (isCurrentlyBookmarked) {
    // --- 즐겨찾기 해제 로직 ---
    print('5. API 호출: [제거] 로직을 실행합니다.');
    success = await BookmarkService.removeBookmark(itemId);
  } else {
    // --- 즐겨찾기 추가 로직 ---
    print('5. API 호출: [추가] 로직을 실행합니다.');
    String itemType;
    String title;
    String description;

    if (item is center_model.Center) {
      itemType = 'CENTER';
      title = item.cntrNm;
      description = '${item.cntrAddr} ${item.cntrDaddr}'.trim();
      print('   - 아이템 타입: CENTER');
    } else if (item is Policy) {
      itemType = 'POLICY';
      title = item.title;
      description = item.description;
      print('   - 아이템 타입: POLICY');
      print('   - 마감일: ${item.deadline}');
      print('   - 마감일 길이: ${item.deadline.length}');
    } else {
      print('🚨 에러: 알 수 없는 아이템 타입입니다.');
      // UI 롤백이 필요하다면 여기에 추가할 수 있습니다.
      return;
    }
    
    print('   - 전송될 데이터: id=$itemId, type=$itemType, title=$title, desc=$description');
    final deadline = item is Policy ? item.deadline : null;
    print('   - 마감일 정보: $deadline');
    
    success = await BookmarkService.saveBookmark(
      itemId: itemId,
      itemType: itemType,
      title: title,
      description: description,
      deadline: deadline, // Policy인 경우 마감일 정보 추가
    );
  }
  
  print('6. API 호출 결과 (success): $success');

  // API 호출 실패 시 UI 롤백
  if (!success && mounted) {
    print('❗️ API 호출 실패! UI를 이전 상태로 롤백합니다.');
    setState(() {
      if (isCurrentlyBookmarked) {
        // 제거에 실패했으므로 다시 추가
        _bookmarkedItemIds.add(itemId);
      } else {
        // 추가에 실패했으므로 다시 제거
        _bookmarkedItemIds.remove(itemId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
    );
  }
  print('--- ✅ 즐겨찾기 토글 종료 ✅ ---');
}

  List<dynamic> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _items;
    }
    final query = _searchQuery.toLowerCase();
    return _items.where((item) {
      if (item is center_model.Center) {
        final title = item.cntrNm.toLowerCase();
        final description = item.cntrAddr.toLowerCase();
        return title.contains(query) || description.contains(query);
      } else if (item is Policy) {
        final title = item.title.toLowerCase();
        final description = item.description.toLowerCase();
        return title.contains(query) || description.contains(query);
      }
      return false;
    }).toList();
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없습니다.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isBookmarked = item.id != null && _bookmarkedItemIds.contains(item.id);
                            return _buildItemCard(item, isBookmarked);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item, bool isBookmarked) {
    String title = (item is Policy) ? item.title : (item as center_model.Center).cntrNm;

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
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showBookmarkDialog(item),
                  child: Icon(
                    Icons.bookmark_border,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (item is center_model.Center) ...[
              _buildInfoRow(Icons.location_on, '${item.cntrAddr} ${item.cntrDaddr}'.trim()),
              if (item.cntrTelno.isNotEmpty) _buildInfoRow(Icons.phone, item.cntrTelno),
              if (item.cntrUrlAddr.isNotEmpty) _buildInfoRow(Icons.link, item.cntrUrlAddr),
              if (item.cntrSn.isNotEmpty) _buildInfoRow(Icons.badge_outlined, '고유번호: ${item.cntrSn}'),
            ] else if (item is Policy) ...[
              if (item.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(item.description, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ),
              if (item.amount.isNotEmpty) _buildInfoRow(Icons.attach_money, item.amount),
              if (item.deadline.isNotEmpty && !item.deadline.contains('상시'))
                _buildInfoRow(Icons.schedule, '마감: ${item.deadline}'),
              if (item.deadline.contains('상시')) _buildInfoRow(Icons.schedule, '상시 접수'),
              const SizedBox(height: 12),
              
              // --- ⭐️ 수정된 부분 ---
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PolicyDetailPage(policy: item.toMap()),
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
                  // '신청하기' ElevatedButton과 SizedBox가 제거되었습니다.
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}