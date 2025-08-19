import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  String _selectedRegion = '';
  int _selectedAge = 20; // 기본값을 20세로 변경
  String _selectedGender = '';

  final List<String> _regions = [
    '서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시',
    '대전광역시', '울산광역시', '세종특별자치시', '경기도', '강원도',
    '충청북도', '충청남도', '전라북도', '전라남도', '경상북도', '경상남도', '제주특별자치도',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    print('🚀 === Onboarding 완료 시작 ===');
    print('🌍 선택된 지역: $_selectedRegion');
    print('🎂 선택된 나이: $_selectedAge');
    print('👫 선택된 성별: $_selectedGender');
    
    try {
      // 사용자 이메일 가져오기
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');
      if (userEmail == null) {
        print('❌ 사용자 이메일을 찾을 수 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 이메일을 찾을 수 없습니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print('📧 사용자 이메일: $userEmail');
      
      // 사용자별 onboarding 완료 플래그 설정
      final onboardingKey = 'onboarding_completed_$userEmail';
      await prefs.setBool(onboardingKey, true);
      print('✅ Onboarding 완료 플래그 설정: $onboardingKey = true');
      
      // MongoDB에 프로필 정보 저장
      print('📡 MongoDB에 프로필 정보 저장 시도...');
      final result = await AuthService.updateUserProfile(
        email: userEmail,
        region: _selectedRegion,
        age: _selectedAge,
        gender: _selectedGender,
      );
      
      print('📥 === MongoDB 저장 결과 ===');
      print('✅ 성공 여부: ${result['success']}');
      print('📝 메시지: ${result['message']}');
      
      if (result['success']) {
        print('🎉 Onboarding 완료! MongoDB에 프로필 정보가 저장되었습니다.');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        print('❌ MongoDB 저장 실패! 사용자에게 오류 메시지를 표시합니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('프로필 저장에 실패했습니다: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
    } catch (e) {
      print('💥 === Onboarding 완료 중 오류 발생 ===');
      print('❌ 오류 타입: ${e.runtimeType}');
      print('❌ 오류 메시지: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRegionPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.yellow[400],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.location_on,
              size: 80,
              color: Colors.orange[700],
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '지역을 선택해주세요',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '맞춤형 서비스를 제공합니다',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _regions.length,
            itemBuilder: (context, index) {
              final region = _regions[index];
              return RadioListTile<String>(
                title: Text(
                  region,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedRegion == region ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                value: region,
                groupValue: _selectedRegion,
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value!;
                  });
                },
                activeColor: Colors.blue,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.person,
              size: 80,
              color: Colors.blue[600],
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '나이를 선택해주세요',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '연령대별 맞춤 서비스를 제공합니다',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedAge = index + 20; // 20세부터 시작
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final age = index + 20; // 20세부터 시작
                return Center(
                  child: Text(
                    '$age세',
                    style: TextStyle(
                      fontSize: age == _selectedAge ? 24 : 18,
                      fontWeight: age == _selectedAge ? FontWeight.bold : FontWeight.normal,
                      color: age == _selectedAge ? Colors.blue : Colors.grey,
                    ),
                  ),
                );
              },
              childCount: 81, // 20세~100세 = 81개 (100-20+1)
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '선택된 나이: $_selectedAge세',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.favorite,
              size: 80,
              color: Colors.red[600],
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '성별을 선택해주세요',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '성별에 맞는 서비스를 제공합니다',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = '남성';
                });
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _selectedGender == '남성' ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedGender == '남성' ? Colors.blue : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.male,
                      size: 50,
                      color: _selectedGender == '남성' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '남성',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == '남성' ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = '여성';
                });
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _selectedGender == '여성' ? Colors.pink : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedGender == '여성' ? Colors.pink : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.female,
                      size: 50,
                      color: _selectedGender == '여성' ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '여성',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == '여성' ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _getNextButtonEnabled() {
    if (_currentPage == 0) {
      return _selectedRegion.isNotEmpty;
    } else if (_currentPage == 1) {
      return _selectedAge >= 20; // 최소 나이를 20세로 변경
    } else if (_currentPage == 2) {
      return _selectedGender.isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildRegionPage(),
                  _buildAgePage(),
                  _buildGenderPage(),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 페이지네이션 점들 (선택된 점이 길게 늘어남)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isSelected = index == _currentPage;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 32 : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isSelected ? Colors.blue : Colors.grey[300],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Colors.blue),
                            ),
                            child: const Text(
                              '이전',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _getNextButtonEnabled() 
                              ? () {
                                  if (_currentPage == 0) {
                                    _nextPage();
                                  } else if (_currentPage == 1) {
                                    _nextPage();
                                  } else if (_currentPage == 2) {
                                    _completeOnboarding();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getNextButtonEnabled() ? Colors.blue : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage == 2 ? '완료' : '다음',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 