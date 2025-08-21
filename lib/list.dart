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
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    }

  void _showBookmarkDialog(dynamic item) async {
    if (item.id == null || item.id.isEmpty) {
      return;
    }

    final isCurrentlyBookmarked = _bookmarkedItemIds.contains(item.id);
    
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
        _toggleFavorite(item);
      }
    }
  }

  void _toggleFavorite(dynamic item) async {
  if (item.id == null || item.id.isEmpty) {
    return;
  }
  
  final itemId = item.id;
  final isCurrentlyBookmarked = _bookmarkedItemIds.contains(itemId);
  setState(() {
    if (isCurrentlyBookmarked) {
      _bookmarkedItemIds.remove(itemId);
    } else {
      _bookmarkedItemIds.add(itemId);
    }
  });

  bool success;
  if (isCurrentlyBookmarked) {
    success = await BookmarkService.removeBookmark(itemId);
  } else {
    String itemType;
    String title;
    String description;

    if (item is center_model.Center) {
      itemType = 'CENTER';
      title = item.cntrNm;
      description = '${item.cntrAddr} ${item.cntrDaddr}'.trim();
    } else if (item is Policy) {
      itemType = 'POLICY';
      title = item.title;
      description = item.description;

    } else {
      return;
    }
    final deadline = item is Policy ? item.deadline : null;

    success = await BookmarkService.saveBookmark(
      itemId: itemId,
      itemType: itemType,
      title: title,
      description: description,
      deadline: deadline,
    );
  }
  
  if (!success && mounted) {
    setState(() {
      if (isCurrentlyBookmarked) {
        _bookmarkedItemIds.add(itemId);
      } else {
        _bookmarkedItemIds.remove(itemId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
    );
  }
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