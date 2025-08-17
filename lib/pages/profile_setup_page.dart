import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/age_picker_dialog.dart';
import '../widgets/gender_dialog.dart';
import '../widgets/country_code_picker.dart';

class ProfileSetupPage extends StatefulWidget {
  final String userEmail;
  
  const ProfileSetupPage({
    super.key,
    required this.userEmail,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  String selectedRegion = '+82'; // 기본값: 대한민국
  int selectedAge = 20;
  String selectedGender = '남';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '프로필 설정',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22, color: Colors.black),
        ),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '사용자 정보를 입력해주세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            
            // 지역 선택
            const Text('지역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
            const SizedBox(height: 8),
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
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => CountryCodePicker(
                        selectedCode: selectedRegion,
                        onSelected: (code) => setState(() => selectedRegion = code),
                      ),
                    ),
                    child: const Text('선택', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 나이 선택
            const Text('나이', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
            const SizedBox(height: 8),
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
                  Text('$selectedAge세', style: const TextStyle(fontSize: 16)),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AgePickerDialog(
                        initialAge: selectedAge,
                        onSelected: (age) => setState(() => selectedAge = age),
                      ),
                    ),
                    child: const Text('선택', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 성별 선택
            const Text('성별', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
            const SizedBox(height: 8),
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
                  Text(selectedGender, style: const TextStyle(fontSize: 16)),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => GenderDialog(
                        selectedGender: selectedGender,
                        onSelected: (gender) => setState(() => selectedGender = gender),
                      ),
                    ),
                    child: const Text('선택', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    print('🔄 === 프로필 저장 시작 ===');
    print('📧 사용자 이메일: ${widget.userEmail}');
    print('🌍 선택된 지역: $selectedRegion');
    print('🎂 선택된 나이: $selectedAge');
    print('👫 선택된 성별: $selectedGender');
    
    setState(() {
      isLoading = true;
    });

    try {
      print('📡 AuthService.updateUserProfile 호출 시작...');
      
      final result = await AuthService.updateUserProfile(
        email: widget.userEmail,
        region: selectedRegion,
        age: selectedAge,
        gender: selectedGender,
      );

      print('📥 === AuthService 응답 결과 ===');
      print('✅ 성공 여부: ${result['success']}');
      print('📝 메시지: ${result['message']}');
      print('🔍 전체 응답: $result');

      if (result['success']) {
        print('🎉 프로필 저장 성공! 메인 화면으로 이동합니다.');
        // 성공 시 메인 화면으로 이동
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          // 메인 화면으로 이동 (예: 홈 화면)
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        print('❌ 프로필 저장 실패! 사용자에게 오류 메시지를 표시합니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 === 예외 발생 ===');
      print('❌ 예외 타입: ${e.runtimeType}');
      print('❌ 예외 메시지: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      print('🏁 === 프로필 저장 완료 ===');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
