import 'package:flutter/material.dart';
import 'calendar.dart';
import 'chatbot_screen.dart';
import 'common_bottom_navigation.dart';
import 'data_manager.dart';
import 'detail.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  int _selectedIndex = 1; // 즐겨찾기 탭이 선택됨
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final DataManager _dataManager = DataManager();

  // 초기 데이터 (빈 리스트로 설정)
  final List<BookmarkItem> _initialBookmarks = [];

  // 즐겨찾기 목록 가져오기 (DataManager + 초기 데이터)
  List<BookmarkItem> get _bookmarks {
    final dataManagerBookmarks = _dataManager.bookmarks;
    final allBookmarks = [..._initialBookmarks, ...dataManagerBookmarks];
    // 중복 제거 (ID 기준)
    final uniqueBookmarks = <BookmarkItem>[];
    final seenIds = <String>{};
    
    for (final bookmark in allBookmarks) {
      if (!seenIds.contains(bookmark.id)) {
        seenIds.add(bookmark.id);
        uniqueBookmarks.add(bookmark);
      }
    }
    
    // 핀된 항목을 맨 위로 정렬
    uniqueBookmarks.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0; // 둘 다 핀되었거나 둘 다 핀되지 않은 경우 원래 순서 유지
    });
    
    return uniqueBookmarks;
  }

  // 핀 토글 함수 (모든 bookmark 아이템에 대해 작동)
  void _togglePin(BookmarkItem item) {
    setState(() {
      final updatedItem = BookmarkItem(
        title: item.title,
        description: item.description,
        time: item.time,
        id: item.id,
        isPinned: !item.isPinned,
        detailData: item.detailData,
      );
      
      // DataManager에서 해당 아이템 업데이트
      _dataManager.removeBookmark(item.id);
      _dataManager.addBookmark(updatedItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: CommonBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          NavigationHelper.navigateToScreen(context, index);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      '즐겨찾기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1B1C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // 검색바
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF707B81), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        autocorrect: false,
                        enableSuggestions: true,
                        enableIMEPersonalizedLearning: true,
                        textCapitalization: TextCapitalization.none,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1B1C),
                        ),
                        decoration: const InputDecoration(
                          hintText: '검색어를 입력하세요',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color(0xFF707B81),
                            fontSize: 16,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onSubmitted: (value) {
                          // 검색 실행 (엔터키 누를 때)
                          setState(() {
                            _searchQuery = value;
                          });
                          // 키보드 숨기기
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            
            // 북마크 리스트
            Expanded(
              child: _buildBookmarkList(),
            ),
            // 하단 네비게이션은 CommonBottomNavigation으로 대체됨
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkList() {
    // 검색 필터링
    List<BookmarkItem> filteredBookmarks = _bookmarks.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // 핀된 아이템을 상단으로 정렬
    filteredBookmarks.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });

    // 검색 중일 때는 검색 결과 스타일로 표시
    if (_searchQuery.isNotEmpty) {
      if (filteredBookmarks.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '검색 결과가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '다른 키워드로 검색해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredBookmarks.length,
        itemBuilder: (context, index) {
          final item = filteredBookmarks[index];
          return Dismissible(
            key: Key('search_${item.id}'),
            direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로 스와이프
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
            confirmDismiss: (direction) async {
              // 삭제 확인 다이얼로그
              return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('즐겨찾기 삭제'),
                    content: Text('${item.title}을(를) 즐겨찾기에서 삭제하시겠습니까?'),
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
            },
            onDismissed: (direction) {
              // 즐겨찾기에서 삭제
              _dataManager.removeBookmark(item.id);
              setState(() {});
              
              // 삭제 완료 메시지
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title}이(가) 즐겨찾기에서 삭제되었습니다'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: '실행취소',
                    onPressed: () {
                      // 실행취소 기능
                      _dataManager.addBookmark(item);
                      setState(() {});
                    },
                  ),
                ),
              );
            },
            child: _buildSearchResultItem(item),
          );
        },
      );
    }

    // 즐겨찾기가 비어있을 때
    if (filteredBookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '즐겨찾기가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '관심 있는 정책을 즐겨찾기에 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // 일반 목록 표시
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredBookmarks.length,
      itemBuilder: (context, index) {
        final item = filteredBookmarks[index];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로 스와이프
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 24,
            ),
          ),
          confirmDismiss: (direction) async {
            // 삭제 확인 다이얼로그
            return await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('즐겨찾기 삭제'),
                  content: Text('${item.title}을(를) 즐겨찾기에서 삭제하시겠습니까?'),
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
          },
          onDismissed: (direction) {
            // 즐겨찾기에서 삭제
            _dataManager.removeBookmark(item.id);
            setState(() {});
            
            // 삭제 완료 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title}이(가) 즐겨찾기에서 삭제되었습니다'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: '실행취소',
                  onPressed: () {
                    // 실행취소 기능 (선택사항)
                    _dataManager.addBookmark(item);
                    setState(() {});
                  },
                ),
              ),
            );
          },
          child: _buildBookmarkItem(item),
        );
      },
    );
  }

  Widget _buildSearchResultItem(BookmarkItem item) {
    return GestureDetector(
      onTap: () {
        // BookmarkItem을 Map 형태로 변환하여 PolicyDetailPage로 이동
        final policyData = {
          'title': item.title,
          'description': item.description,
          'amount': item.detailData.leftAmount,
          'location': '전국', // 기본값
          'deadline': item.detailData.rightAmount,
          'status': '신청가능', // 기본값
        };

        // 검색창 초기화
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PolicyDetailPage(policy: policyData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9EE1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Color(0xFF5B9EE1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                // 핀 버튼 추가
                GestureDetector(
                  onTap: () => _togglePin(item),
                  child: Icon(
                    item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: item.isPinned ? Colors.amber : const Color(0xFF707B81),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF707B81),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF707B81),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkItem(BookmarkItem item) {
    return GestureDetector(
      onTap: () {
        // BookmarkItem을 Map 형태로 변환하여 PolicyDetailPage로 이동
        final policyData = {
          'title': item.title,
          'description': item.description,
          'amount': item.detailData.leftAmount,
          'location': '전국', // 기본값
          'deadline': item.detailData.rightAmount,
          'status': '신청가능', // 기본값
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PolicyDetailPage(policy: policyData),
          ),
        );
      },
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
              onTap: () => _togglePin(item),
              child: Icon(
                item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: item.isPinned ? Colors.amber : const Color(0xFF707B81),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF707B81),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item.time,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF707B81),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // 기존 네비게이션 바 메서드들은 CommonBottomNavigation으로 대체됨
}

class BookmarkItem {
  final String title;
  final String description;
  final String time;
  final String id;
  bool isPinned;
  final BookmarkDetailData detailData;

  BookmarkItem({
    required this.title,
    required this.description,
    required this.time,
    required this.id,
    required this.isPinned,
    required this.detailData,
  });
}

class BookmarkDetailData {
  final String title;
  final String bannerTitle;
  final String bannerSubtitle;
  final String description;
  final String leftAmount;
  final String rightAmount;
  final Color leftColor;
  final Color rightColor;

  BookmarkDetailData({
    required this.title,
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.description,
    required this.leftAmount,
    required this.rightAmount,
    required this.leftColor,
    required this.rightColor,
  });
} 