import 'package:flutter/material.dart';
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
  
  // 즐겨찾기 목록
  List<BookmarkItem> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🚀 BookmarkScreen.initState() 호출됨');
    _loadBookmarks();
  }
  
  // 즐겨찾기 목록 로드
  Future<void> _loadBookmarks() async {
    print('🔄 _loadBookmarks() 메서드 시작!');
    try {
      print('🔄 즐겨찾기 로드 시작...');
      setState(() {
        _isLoading = true;
      });
      
      print('📡 _dataManager.bookmarks 호출 전...');
      final bookmarks = await _dataManager.bookmarks;
      print('✅ DataManager.bookmarks 응답: ${bookmarks.length}개');
      
      // DB에서 받아온 각 즐겨찾기의 isPinned 상태 확인
      for (int i = 0; i < bookmarks.length; i++) {
        final bookmark = bookmarks[i];
        print('🔍 DB에서 받은 즐겨찾기 $i: title=${bookmark.title}, isPinned=${bookmark.isPinned}, isPinned 타입=${bookmark.isPinned.runtimeType}');
        print('🔍 전체 BookmarkItem 데이터: id=${bookmark.id}, policyId=${bookmark.policyId}, userId=${bookmark.userId}');
      }
      
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
      print('🎯 즐겨찾기 로드 완료: _bookmarks.length = ${_bookmarks.length}');
      
      // 로드된 즐겨찾기의 isPinned 상태 재확인
      final pinnedCount = _bookmarks.where((b) => b.isPinned).length;
      print('📌 로드 완료 후 핀된 즐겨찾기: $pinnedCount개');
      
      // setState 후 _bookmarks 상태 재확인
      for (int i = 0; i < _bookmarks.length; i++) {
        print('🔍 setState 후 _bookmarks $i: title=${_bookmarks[i].title}, isPinned=${_bookmarks[i].isPinned}');
      }
      
    } catch (e) {
      print('💥 즐겨찾기 로드 실패: $e');
      print('💥 오류 스택 트레이스: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 즐겨찾기 목록 가져오기 (필터링 및 정렬)
  List<BookmarkItem> get _filteredBookmarks {
    print('🔍 _filteredBookmarks 호출됨: _bookmarks.length = ${_bookmarks.length}');
    
    if (_bookmarks.isEmpty) {
      print('⚠️ _bookmarks가 비어있음');
      return [];
    }
    
    // 각 아이템의 isPinned 상태 출력
    for (int i = 0; i < _bookmarks.length; i++) {
      print('🔍 아이템 $i: ${_bookmarks[i].title}, isPinned: ${_bookmarks[i].isPinned}');
    }
    
    final filteredBookmarks = _bookmarks.where((bookmark) {
      if (_searchQuery.isEmpty) return true;
      return bookmark.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             bookmark.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    print('🔍 검색 필터링 후: ${filteredBookmarks.length}개');
    
    // 핀된 항목을 맨 위로 정렬
    filteredBookmarks.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0; // 둘 다 핀되었거나 둘 다 핀되지 않은 경우 원래 순서 유지
    });
    
    print('🔍 정렬 후: 핀된 항목 ${filteredBookmarks.where((b) => b.isPinned).length}개');
    
    // 정렬 후 각 아이템의 순서와 isPinned 상태 출력
    for (int i = 0; i < filteredBookmarks.length; i++) {
      print('🔍 정렬 후 아이템 $i: ${filteredBookmarks[i].title}, isPinned: ${filteredBookmarks[i].isPinned}');
    }
    
    return filteredBookmarks;
  }

  // 핀 토글 함수 (모든 bookmark 아이템에 대해 작동)
  void _togglePin(BookmarkItem item) async {
    print('📌 핀 토글 시작: ${item.title}, 현재 isPinned: ${item.isPinned}');
    print('🔍 사용할 ID: item.id=${item.id}, item.policyId=${item.policyId}');
    
    // 1. UI 즉시 반영 (사용자 경험)
    setState(() {
      item.isPinned = !item.isPinned;
    });
    print('✅ UI 즉시 업데이트 완료: isPinned = ${item.isPinned}');
    
    try {
      // 2. DB에 상태 저장
      print('📡 DataManager.toggleBookmarkPin 호출 중... policyId: ${item.policyId}');
      await _dataManager.toggleBookmarkPin(item.policyId, item.isPinned);
      print('✅ DataManager.toggleBookmarkPin 완료');
      
      // 3. DB에서 최신 상태 읽어와서 동기화
      print('🔄 DB 상태 동기화 중...');
      await _loadBookmarks();
      print('✅ DB 상태 동기화 완료');
      
    } catch (e) {
      print('💥 핀 상태 변경 실패: $e');
      // 실패 시 UI 상태 되돌리기
      setState(() {
        item.isPinned = !item.isPinned;
      });
      print('🔄 UI 상태 되돌림: isPinned = ${item.isPinned}');
    }
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
    // 로딩 중일 때
    if (_isLoading) {
      print('⏳ 즐겨찾기 로딩 중...');
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    print('🔍 _buildBookmarkList 호출됨: _bookmarks.length = ${_bookmarks.length}');
    
    // 검색 필터링 (이미 _filteredBookmarks에서 정렬됨)
    List<BookmarkItem> filteredBookmarks = _filteredBookmarks;
    
    print('🔍 필터링된 즐겨찾기: ${filteredBookmarks.length}개');

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
            onDismissed: (direction) async {
              // 즐겨찾기에서 삭제
              await _dataManager.removeBookmark(item.id);
              await _loadBookmarks(); // 목록 새로고침
              
              // 삭제 완료 메시지
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title}이(가) 즐겨찾기에서 삭제되었습니다'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: '실행취소',
                    onPressed: () async {
                      // 실행취소 기능
                      await _dataManager.addBookmark(item);
                      await _loadBookmarks(); // 목록 새로고침
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
          onDismissed: (direction) async {
            // 즐겨찾기에서 삭제
            await _dataManager.removeBookmark(item.id);
            await _loadBookmarks(); // 목록 새로고침
            
            // 삭제 완료 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title}이(가) 즐겨찾기에서 삭제되었습니다'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: '실행취소',
                  onPressed: () async {
                    // 실행취소 기능 (선택사항)
                    await _dataManager.addBookmark(item);
                    await _loadBookmarks(); // 목록 새로고침
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
          'amount': item.detailData.leftAmount.isNotEmpty ? item.detailData.leftAmount : '금액 정보 없음',
          'location': '전국', // 기본값
          'deadline': item.detailData.rightAmount.isNotEmpty ? item.detailData.rightAmount : '기간 정보 없음',
          'status': '신청가능', // 기본값
          'category': item.detailData.bannerTitle.isNotEmpty ? item.detailData.bannerTitle : '카테고리 정보 없음',
          'keywords': '키워드 정보 없음', // 기본값
          'applicationMethod': item.description.isNotEmpty ? item.description : '신청 방법 정보 없음',
          'applicationPeriod': item.detailData.rightAmount.isNotEmpty ? item.detailData.rightAmount : '신청 기간 정보 없음',
          'region': '지역 정보 없음', // 기본값
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
    print('🔍 _buildBookmarkItem 렌더링: ${item.title}, isPinned: ${item.isPinned}, id: ${item.id}, policyId: ${item.policyId}');
    
    // 핀 아이콘 상태 확인
    final pinIcon = item.isPinned ? Icons.push_pin : Icons.push_pin_outlined;
    final pinColor = item.isPinned ? Colors.amber : const Color(0xFF707B81);
    print('📌 핀 아이콘 상태: icon=$pinIcon, color=$pinColor, isPinned=${item.isPinned}');
    
    return GestureDetector(
      onTap: () {
        // BookmarkItem을 Map 형태로 변환하여 PolicyDetailPage로 이동
        final policyData = {
          'title': item.title,
          'description': item.description,
          'amount': item.detailData.leftAmount.isNotEmpty ? item.detailData.leftAmount : '금액 정보 없음',
          'location': '전국', // 기본값
          'deadline': item.detailData.rightAmount.isNotEmpty ? item.detailData.rightAmount : '기간 정보 없음',
          'status': '신청가능', // 기본값
          'category': item.detailData.bannerTitle.isNotEmpty ? item.detailData.bannerTitle : '카테고리 정보 없음',
          'keywords': '키워드 정보 없음', // 기본값
          'applicationMethod': item.description.isNotEmpty ? item.description : '신청 방법 정보 없음',
          'applicationPeriod': item.detailData.rightAmount.isNotEmpty ? item.detailData.rightAmount : '신청 기간 정보 없음',
          'region': '지역 정보 없음', // 기본값
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
                pinIcon,
                color: pinColor,
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
  final String userId; // 사용자 ID 추가
  final String policyId; // 정책 ID 추가
  bool isPinned;
  final BookmarkDetailData detailData;

  BookmarkItem({
    required this.title,
    required this.description,
    required this.time,
    required this.id,
    required this.userId, // 사용자 ID 필수
    required this.policyId, // 정책 ID 필수
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