import 'package:flutter/material.dart';
import '../models/bookmarkItem.dart';
import '../models/policy.dart';
import '../models/center.dart' as center_model;
import '../services/bookmark_service.dart';
import 'detail.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({Key? key}) : super(key: key);

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  // 상태 관리 변수
  late Future<List<BookmarkItem>> _bookmarksFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  /// 북마크 데이터를 불러오고 상태를 갱신하는 함수
  void _loadBookmarks() {
    setState(() {
      _bookmarksFuture = BookmarkService.getBookmarks();
    });
  }

  /// 북마크 삭제 함수
  Future<void> _deleteBookmark(String itemId, String title) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('즐겨찾기 삭제'),
          content: Text('\'$title\' 항목을 즐겨찾기에서 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    bool success = await BookmarkService.removeBookmark(itemId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\'$title\'이(가) 즐겨찾기에서 삭제되었습니다.')),
      );
      _loadBookmarks(); // 성공 시 목록 새로고침
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  /// ⭐️ 핀 상태를 토글하는 함수 (수정됨)
  void _togglePin(BookmarkItem bookmark) async {
    // API에 보낼 고유 ID 추출
    String itemId = '';
    if (bookmark.item is Policy) {
      itemId = (bookmark.item as Policy).id;
    } else if (bookmark.item is center_model.Center) {
      itemId = (bookmark.item as center_model.Center).id;
    }

    if (itemId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류: 아이템 ID를 찾을 수 없습니다.')),
      );
      return;
    }

    // 1. 낙관적 업데이트: UI를 먼저 변경
    setState(() {
      bookmark.isPinned = !bookmark.isPinned;
    });

    // 2. API 호출
    bool success = await BookmarkService.togglePin(itemId);

    // 3. API 호출 결과 처리
    if (!success) {
      // 실패 시 UI 롤백
      setState(() {
        bookmark.isPinned = !bookmark.isPinned;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('핀 상태 변경에 실패했습니다.')),
        );
      }
    } else {
      // 성공 시 목록을 새로고침하여 정렬 순서 등을 완전히 동기화
      _loadBookmarks();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('즐겨찾기'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1B1C),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1A1B1C)),
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요',
                  hintStyle: const TextStyle(color: Color(0xFF707B81)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF707B81), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: _buildBookmarkList(),
            ),
          ],
        ),
      ),
    );
  }

  /// FutureBuilder를 사용하여 북마크 목록을 빌드하는 위젯
  Widget _buildBookmarkList() {
    return FutureBuilder<List<BookmarkItem>>(
      future: _bookmarksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('즐겨찾기한 항목이 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        final filteredAndSortedBookmarks = snapshot.data!
            .where((bookmark) {
              if (_searchQuery.isEmpty) return true;
              String title = '';
              String description = '';
              if (bookmark.itemType == 'POLICY' && bookmark.item is Policy) {
                final policy = bookmark.item as Policy;
                title = policy.title;
                description = policy.description;
              } else if (bookmark.itemType == 'CENTER' && bookmark.item is center_model.Center) {
                final center = bookmark.item as center_model.Center;
                title = center.cntrNm;
                description = center.cntrAddr;
              }
              return title.toLowerCase().contains(_searchQuery) || description.toLowerCase().contains(_searchQuery);
            })
            .toList()
          ..sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return 0;
          });

        if (filteredAndSortedBookmarks.isEmpty && _searchQuery.isNotEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('검색 결과가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredAndSortedBookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = filteredAndSortedBookmarks[index];
            return _buildBookmarkCard(bookmark);
          },
        );
      },
    );
  }

  /// 북마크 아이템 하나를 표시하는 카드 위젯
  Widget _buildBookmarkCard(BookmarkItem bookmark) {
    String title = '제목 없음';
    String description = '내용 없음';
    String itemId = '';

    if (bookmark.itemType == 'POLICY' && bookmark.item is Policy) {
      final policy = bookmark.item as Policy;
      title = policy.title;
      description = policy.description;
      itemId = policy.id;
    } else if (bookmark.itemType == 'CENTER' && bookmark.item is center_model.Center) {
      final center = bookmark.item as center_model.Center;
      title = center.cntrNm;
      description = center.cntrAddr;
      itemId = center.id;
    }

    return Dismissible(
      key: Key(itemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        _deleteBookmark(itemId, title);
        return false;
      },
      child: GestureDetector(
        onTap: bookmark.itemType == 'POLICY'
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PolicyDetailPage(
                      policy: (bookmark.item as Policy).toMap(),
                    ),
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _togglePin(bookmark),
                child: Icon(
                  bookmark.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: bookmark.isPinned ? Colors.amber[800] : const Color(0xFF707B81),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1B1C),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF707B81)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (bookmark.itemType == 'POLICY')
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF707B81),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}