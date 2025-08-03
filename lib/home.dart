import 'package:flutter/material.dart';
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

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  
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
            // 상단 헤더
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '홈화면 v',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.code),
                  ),
                ],
              ),
            ),
            
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
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(text: '확인'),
                          const TextSpan(
                            text: '!',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
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
                        childAspectRatio: screenWidth / (screenHeight * 0.25),
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
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
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue[100]!),
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
                      child: PageView.builder(
                        itemCount: latestPolicies.length,
                        controller: PageController(
                          viewportFraction: 0.75, // 화면의 75%만 차지하도록 설정
                        ),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PolicyDetailPage(
                                    policy: latestPolicies[index],
                                  ),
                                ),
                              );
                            },
                            child: Container(
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
                                            latestPolicies[index]['title'],
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: screenHeight * 0.003),
                                          Text(
                                            latestPolicies[index]['subtitle'],
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
                                                  latestPolicies[index]['location'],
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
