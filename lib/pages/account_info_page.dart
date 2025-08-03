// lib/pages/account_info_page.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/info_row.dart';
import '../widgets/nav_row.dart';
import '../widgets/age_picker_dialog.dart';
import '../widgets/gender_dialog.dart';
import '../widgets/country_code_picker.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  String userId = 'kuagentica';
  String name = '박윤혁';
  String phoneCode = '+82';
  String phoneNumber = '010-2618-0090';
  int age = 24;
  String gender = '남';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
          const Text('아이디', style: TextStyle(fontSize: 16, color: Colors.black)),
          TextFormField(
            initialValue: userId,
            onChanged: (v) => setState(() => userId = v),
          ),
          const Divider(),
          NavRow(title: '비밀번호 변경', onTap: () => Navigator.pushNamed(context, '/change-password')),
          const Divider(),
          NavRow(title: '이메일 변경', onTap: () => Navigator.pushNamed(context, '/change-email')),
          const Divider(),
          const Text('이름', style: TextStyle(fontSize: 16, color: Colors.black)),
          TextFormField(
            initialValue: name,
            onChanged: (v) => setState(() => name = v),
          ),
          const Divider(),
          const Text('전화번호', style: TextStyle(fontSize: 16, color: Colors.black)),
          Row(
            children: [
              TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => CountryCodePicker(
                    selectedCode: phoneCode,
                    onSelected: (code) => setState(() => phoneCode = code),
                  ),
                ),
                child: Text(phoneCode, style: const TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: phoneNumber,
                  onChanged: (v) => setState(() => phoneNumber = v),
                ),
              ),
            ],
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
            onPressed: () {
              // 저장 로직 또는 확인 메시지 등 구현 가능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('저장되었습니다.')),
              );
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
      bottomNavigationBar: BottomNav(
        currentIndex: 4,
        onTap: (_) {},
      ),
    );
  }
}
