// lib/pages/account_info_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/info_row.dart';
import '../widgets/nav_row.dart';
import '../widgets/age_picker_dialog.dart';
import '../widgets/gender_dialog.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  String selectedRegion = '서울특별시'; // 국내 지역
  int age = 24;
  String gender = '남성'; // 성별을 "남성", "여성"으로 변경
  String? userEmail; // 사용자 이메일 저장용

  // 국내 지역 목록 (onboarding과 동일)
  final List<String> _regions = [
    '서울특별시', '부산광역시', '대구광역시', '인천광역시', '광주광역시',
    '대전광역시', '울산광역시', '세종특별자치시', '경기도', '강원도',
    '충청북도', '충청남도', '전라북도', '전라남도', '경상북도', '경상남도', '제주특별자치도',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 데이터 로드 (DB에서만 가져오기)
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 사용자 이메일 로드
      final email = prefs.getString('user_email');
      if (email == null) {
        print('❌ 사용자 이메일을 찾을 수 없습니다.');
        return;
      }
      
      setState(() {
        userEmail = email;
      });
      print('📧 로드된 사용자 이메일: $userEmail');
      
      // DB에서 직접 프로필 데이터 가져오기
      print('🔍 DB에서 프로필 데이터 조회 중...');
      final profileResult = await AuthService.getUserProfile(email);
      
      if (profileResult['success']) {
        final data = profileResult['data'];
        
        setState(() {
          // DB에서 가져온 데이터로 설정
          if (data['region'] != null) selectedRegion = data['region'];
          if (data['age'] != null) age = data['age'];
          if (data['gender'] != null) gender = data['gender'];
        });
        
        print('✅ DB에서 프로필 데이터 로드 완료:');
        print('  🌍 지역: $selectedRegion');
        print('  🎂 나이: $age');
        print('  👫 성별: $gender');
        
      } else {
        print('❌ DB 프로필 조회 실패: ${profileResult['message']}');
        // DB 조회 실패 시 기본값 사용
        print('⚠️ 기본값 사용: 지역=$selectedRegion, 나이=$age, 성별=$gender');
      }
    } catch (e) {
      print('❌ 사용자 데이터 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '계정정보',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.black87,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          // 지역 선택 (국내 지역)
          const Text('지역', style: TextStyle(fontSize: 16, color: Colors.black)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedRegion, style: const TextStyle(fontSize: 16)),
                TextButton(
                  onPressed: () => _showRegionPicker(),
                  child: const Text('선택', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
          const Divider(),
          InfoRow(
            label: '나이',
            value: '$age',
            onTap: () => showDialog(
              context: context,
              builder: (_) => AgePickerDialog(
                initialAge: age,
                onSelected: (val) => setState(() => age = val),
              ),
            ),
          ),
          const Divider(),
          InfoRow(
            label: '성별',
            value: gender,
            onTap: () => showDialog(
              context: context,
              builder: (_) => GenderDialog(
                selectedGender: gender,
                onSelected: (val) => setState(() => gender = val),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (userEmail == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('사용자 이메일을 찾을 수 없습니다. 다시 로그인해주세요.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              print('🔄 === 계정 정보 저장 시작 ===');
              print('📧 사용자 이메일: $userEmail');
              print('🌍 선택된 지역: $selectedRegion');
              print('🎂 선택된 나이: $age');
              print('👫 선택된 성별: $gender');
              
              // 저장 로직 구현
              print('📡 AuthService.updateUserProfile 호출 시작...');
              final result = await AuthService.updateUserProfile(
                email: userEmail!,
                region: selectedRegion, // 국내 지역명 그대로 전송
                age: age,
                gender: gender,
              );
              
              print('📥 === AuthService 응답 결과 ===');
              print('✅ 성공 여부: ${result['success']}');
              print('📝 메시지: ${result['message']}');
              
              if (result['success']) {
                print('🎉 계정 정보 저장 성공!');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'])),
                );
              } else {
                print('❌ 계정 정보 저장 실패!');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 지역 선택 다이얼로그 표시
  void _showRegionPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지역 선택'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _regions.length,
            itemBuilder: (context, index) {
              final region = _regions[index];
              return RadioListTile<String>(
                title: Text(region),
                value: region,
                groupValue: selectedRegion,
                onChanged: (value) {
                  setState(() {
                    selectedRegion = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
