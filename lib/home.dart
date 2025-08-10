import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'signup.dart';
import 'restore.dart';
import 'list.dart';
import 'detail.dart';
import 'search.dart';
import 'common_bottom_navigation.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late ScrollController _scrollController;
  Timer? _timer;
  double _scrollPosition = 0;
  
  // 카테고리 애니메이션 컨트롤러들
  late List<AnimationController> _categoryControllers;
  late List<Animation<double>> _categoryAnimations;
  
  final List<Map<String, dynamic>> categories = [
    {
      'title': '창업 지원',
      'icon': Icons.eco,
      'color': Colors.green,
    },
    {
      'title': '주거 지원',
      'icon': Icons.group,
      'color': Colors.blue,
    },
    {
      'title': '교육·훈련비 지원',
      'icon': Icons.school,
      'color': Colors.orange,
    },
    {
      'title': '금융 지원',
      'icon': Icons.account_balance_wallet,
      'color': Colors.yellow,
    },
    {
      'title': '생활·복지 지원',
      'icon': Icons.person,
      'color': Colors.purple,
    },
    {
      'title': '취업 지원',
      'icon': Icons.work,
      'color': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> latestPolicies = [
    {
      'title': '민생회복 소비쿠폰 안내',
      'subtitle': '25, 15',
      'location': '전국 각 지역',
      'description': '코로나19로 인한 경제적 어려움을 겪는 국민을 위한 소비쿠폰 지원 정책입니다.',
      'amount': '25만원 + 15만원',
      'deadline': '2024.12.31',
      'status': '신청가능',
    },
    {
      'title': '청년도약 계좌',
      'subtitle': '5천만원 목도마!',
      'location': '전국 각 지역',
      'description': '청년들의 자산 형성을 위한 특별 계좌로, 최대 5천만원까지 지원받을 수 있습니다.',
      'amount': '최대 5천만원',
      'deadline': '2024.12.31',
      'status': '신청가능',
    },
    {
      'title': '청년 취업 지원 프로그램',
      'subtitle': '07.',
      'location': '전국 각 지역',
      'description': '청년들의 취업을 위한 종합적인 지원 프로그램입니다.',
      'amount': '취업성공수당 지급',
      'deadline': '2024.11.30',
      'status': '신청가능',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeCategoryAnimations();
    _startAutoScroll();
  }
  
  void _initializeCategoryAnimations() {
    _categoryControllers = [];
    _categoryAnimations = [];
    
    for (int i = 0; i < categories.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 2000 + (i * 300)),
        vsync: this,
      );
      
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      
      _categoryControllers.add(controller);
      _categoryAnimations.add(animation);
      
      // 각 카테고리마다 다른 타이밍으로 반복 애니메이션
      controller.repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    
    // 카테고리 애니메이션 컨트롤러들 해제
    for (final controller in _categoryControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients && _scrollController.position.hasViewportDimension) {
        _scrollPosition += 1.0;
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (_scrollPosition >= maxScroll) {
          _scrollPosition = 0;
        }

        _scrollController.animateTo(
          _scrollPosition,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
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
            // 상단 여백 추가
            SizedBox(height: screenHeight * 0.05),
            
            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 검색창과 알림
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Search',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // 메인 문구
                    Text(
                      '원하는 청년 정책, 한눈에 확인!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // 카테고리 섹션
                    Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.2, // 고정된 비율로 변경
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _categoryAnimations[index],
                          builder: (context, child) {
                            // 사인 함수를 사용해서 위아래로 움직이는 애니메이션
                            final value = _categoryAnimations[index].value;
                            final offset = sin(value * 2 * pi) * 3.0; // 3픽셀 위아래 움직임
                            
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PolicyListPage(
                                        category: categories[index]['title'],
                                        categoryData: categories[index],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F8F8), // 거의 회색 배경
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        categories[index]['icon'],
                                        color: categories[index]['color'],
                                        size: screenWidth * 0.06,
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          categories[index]['title'],
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.03,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // 최신 정책 섹션
                    Text(
                      '최신 정책',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    
                    SizedBox(
                      height: screenHeight * 0.25,
                      child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                        itemCount: latestPolicies.length * 3, // 무한 스크롤을 위해 3배로 늘림
                        itemBuilder: (context, index) {
                          final actualIndex = index % latestPolicies.length;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PolicyDetailPage(
                                    policy: latestPolicies[actualIndex],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: screenWidth * 0.75,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.policy,
                                          size: screenWidth * 0.08,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: EdgeInsets.all(screenWidth * 0.03),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            latestPolicies[actualIndex]['title'],
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: screenHeight * 0.003),
                                          Text(
                                            latestPolicies[actualIndex]['subtitle'],
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.03,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: screenWidth * 0.03,
                                                color: Colors.grey[500],
                                              ),
                                              SizedBox(width: screenWidth * 0.008),
                                              Expanded(
                                                child: Text(
                                                  latestPolicies[actualIndex]['location'],
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.025,
                                                    color: Colors.grey[500],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),


                SizedBox(height: screenHeight * 0.01),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
}