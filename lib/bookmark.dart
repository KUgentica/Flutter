import 'package:flutter/material.dart';
import 'calendar.dart';
import 'chatbot_screen.dart';
import 'common_bottom_navigation.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  int _selectedIndex = 1; // 즐겨찾기 탭이 선택됨
  bool _showDetail = false;
  BookmarkItem? _selectedItem; // 선택된 아이템
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<BookmarkItem> _bookmarks = [
    BookmarkItem(
      title: '민생지원금',
      description: '정부 소비쿠폰 15만원 어쩌고..',
      time: '09:30',
      id: '1',
      isPinned: false,
      detailData: BookmarkDetailData(
        title: '민생지원금',
        bannerTitle: '회복과 성장의 마중물',
        bannerSubtitle: '민생회복 소비쿠폰 안내',
        description: '코로나19 등으로 인해 어려움을 겪는 청년들을 위해 정부와 지자체에서 다양한 민생지원금을 제공합니다. 항공권, 숙박비, 교통비 등을 포함한 여행 패키지 형태로 제공되며, 자격 조건을 충족할 경우 신청할 수 있습니다. ◆ 자세한 조건은 각 정책 페이지에서 확인해주세요.',
        leftAmount: '15만원',
        rightAmount: '25만원',
        leftColor: Colors.green,
        rightColor: Colors.amber,
      ),
    ),
    BookmarkItem(
      title: '경기도 지원금',
      description: '경기도민들을 위한 어쩌고..',
      time: '08:45',
      id: '2',
      isPinned: false,
      detailData: BookmarkDetailData(
        title: '경기도 지원금',
        bannerTitle: '경기도 청년 지원',
        bannerSubtitle: '경기도 청년 일자리 지원금',
        description: '경기도에 거주하는 청년들을 위한 다양한 지원 프로그램입니다. 창업 지원금, 스킬업 교육비, 취업 연계 서비스 등을 제공하며, 경기도 내 거주자라면 누구나 신청 가능합니다. ◆ 지원 조건과 신청 방법은 경기도청 홈페이지에서 확인하세요.',
        leftAmount: '30만원',
        rightAmount: '20만원',
        leftColor: Colors.blue,
        rightColor: Colors.orange,
      ),
    ),
    BookmarkItem(
      title: '산불 지원금',
      description: '산불 재난시 어쩌고..',
      time: '어제',
      id: '3',
      isPinned: false,
      detailData: BookmarkDetailData(
        title: '산불 지원금',
        bannerTitle: '산불 피해 복구 지원',
        bannerSubtitle: '산불 피해 지역 주민 지원',
        description: '산불로 인한 피해를 입은 지역 주민들을 위한 긴급 지원금입니다. 주거 복구비, 생활 안정자금, 농작물 피해 보상 등을 지원하며, 피해 지역 주민이라면 신청 가능합니다. ◆ 피해 증명서와 신분증을 준비하여 신청하세요.',
        leftAmount: '50만원',
        rightAmount: '30만원',
        leftColor: Colors.red,
        rightColor: Colors.purple,
      ),
    ),
    BookmarkItem(
      title: '한부모 가정 지원금',
      description: '한부모 가정에 어쩌고..',
      time: '2일전',
      id: '4',
      isPinned: false,
      detailData: BookmarkDetailData(
        title: '한부모 가정 지원금',
        bannerTitle: '한부모 가정 지원',
        bannerSubtitle: '한부모 가정 생활 안정 지원',
        description: '한부모 가정의 안정적인 생활을 지원하는 프로그램입니다. 자녀 양육비, 교육비, 주거비 등을 지원하며, 한부모 가정이라면 신청 가능합니다. ◆ 소득 기준과 자녀 연령에 따라 지원 금액이 달라집니다.',
        leftAmount: '40만원',
        rightAmount: '25만원',
        leftColor: Colors.pink,
        rightColor: Colors.teal,
      ),
    ),
    BookmarkItem(
      title: '문화 공연 지원금',
      description: '전국의 20대 청년들에게 어쩌고..',
      time: '일주일전',
      id: '5',
      isPinned: false,
      detailData: BookmarkDetailData(
        title: '문화 공연 지원금',
        bannerTitle: '청년 문화 생활 지원',
        bannerSubtitle: '청년 문화 공연 관람 지원',
        description: '청년들의 문화 생활을 지원하는 프로그램입니다. 공연 관람비, 전시회 입장료, 문화 활동비 등을 지원하며, 20대 청년이라면 누구나 신청 가능합니다. ◆ 월 1회까지 신청 가능하며, 선착순으로 지원됩니다.',
        leftAmount: '10만원',
        rightAmount: '5만원',
        leftColor: Colors.indigo,
        rightColor: Colors.cyan,
      ),
    ),
  ];

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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1B1C)),
                    onPressed: () {},
                  ),
                  const Expanded(
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
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF1A1B1C)),
                    onPressed: () {},
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
              child: _showDetail
                  ? _buildDetailView()
                  : _buildBookmarkList(),
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
          return _buildSearchResultItem(filteredBookmarks[index]);
        },
      );
    }

    // 일반 목록 표시
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredBookmarks.length,
      itemBuilder: (context, index) {
        return _buildBookmarkItem(filteredBookmarks[index]);
      },
    );
  }

  Widget _buildSearchResultItem(BookmarkItem item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetail = true;
          _selectedItem = item;
          _searchQuery = ''; // 검색창 초기화
          _searchController.clear();
        });
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
        setState(() {
          _showDetail = true;
          _selectedItem = item;
        });
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
              onTap: () {
                setState(() {
                  // 핀 상태 토글
                  final index = _bookmarks.indexWhere((bookmark) => bookmark.id == item.id);
                  if (index != -1) {
                    _bookmarks[index] = BookmarkItem(
                      title: item.title,
                      description: item.description,
                      time: item.time,
                      id: item.id,
                      isPinned: !item.isPinned,
                      detailData: item.detailData,
                    );
                  }
                });
              },
              child: Icon(
                item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: item.isPinned ? const Color(0xFF5B9EE1) : const Color(0xFF707B81),
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

  Widget _buildDetailView() {
    if (_selectedItem == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _showDetail = false;
                _selectedItem = null;
              });
            },
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1A1B1C),
              size: 24,
            ),
          ),
          const SizedBox(height: 20),
          // 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B9EE1), Color(0xFF4A8BC8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedItem!.detailData.bannerTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedItem!.detailData.bannerSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 금액 정보
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedItem!.detailData.leftColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedItem!.detailData.leftAmount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _selectedItem!.detailData.leftColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '최소 지원금',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF707B81),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedItem!.detailData.rightColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedItem!.detailData.rightAmount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _selectedItem!.detailData.rightColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '최대 지원금',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF707B81),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 설명
          Text(
            _selectedItem!.detailData.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1B1C),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          // 바로 이동하기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B9EE1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '바로 이동하기(URL)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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