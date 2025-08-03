import 'package:flutter/material.dart';
import 'dart:async';
import 'password.dart';

class RestorePage extends StatefulWidget {
  const RestorePage({Key? key}) : super(key: key);

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isEmailSent = false;
  bool _isVerificationSent = false;
  bool _isTimerActive = false;
  int _remainingTime = 300; // 5분 (300초)
  Timer? _timer;
  
  @override
  void dispose() {
    _emailController.dispose();
    _verificationController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    setState(() {
      _isTimerActive = true;
      _remainingTime = 300;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _isTimerActive = false;
          timer.cancel();
        }
      });
    });
  }
  
  void _sendVerificationCode() {
    if (!_formKey.currentState!.validate()) return;
    
    // 이메일 형식 검증 (간단한 정규식)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      _showErrorDialog('이메일(ID)가 올바르지 않습니다');
      return;
    }
    
    setState(() {
      _isEmailSent = true;
    });
    
    _startTimer();
  }
  
  void _verifyCode() {
    if (_verificationController.text.isEmpty) {
      _showErrorDialog('인증번호를 입력해주세요');
      return;
    }
    
    // 무조건 맞다는 로직 (실제로는 서버에서 검증해야 함)
    // 여기서는 간단히 6자리 숫자인지만 확인
    if (_verificationController.text.length != 6 || !RegExp(r'^\d{6}$').hasMatch(_verificationController.text)) {
      _showErrorDialog('인증번호를 다시 입력해주세요');
      _verificationController.clear();
      return;
    }
    
    setState(() {
      _isVerificationSent = true;
    });
    
    _timer?.cancel();
    
    // 비밀번호 재설정 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PasswordResetPage()),
    );
  }
  
  void _resendCode() {
    _startTimer();
    _verificationController.clear();
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_outline,
                color: Colors.blue,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
  
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호를 잊은 경우'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '비밀번호를 잊으셨습니까?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '비밀번호를 재설정하기 위해 ID또는 이메일주소를 입력하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // 이메일 입력 필드
              TextFormField(
                controller: _emailController,
                enabled: !_isEmailSent,
                decoration: InputDecoration(
                  hintText: 'www.uhut@gmail.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 인증번호 보내기 버튼
              if (!_isEmailSent)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '인증번호 보내기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              
              // 인증번호 입력 섹션
              if (_isEmailSent) ...[
                const SizedBox(height: 32),
                const Text(
                  '인증번호 입력',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _verificationController,
                        enabled: _isTimerActive,
                        decoration: InputDecoration(
                          hintText: '인증번호 6자리',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: _isTimerActive ? Colors.grey[50] : Colors.grey[200],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isTimerActive ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatTime(_remainingTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 인증번호 확인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isTimerActive ? _verifyCode : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTimerActive ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '인증번호 확인하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                // 시간 만료 시 재전송 버튼
                if (!_isTimerActive) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _resendCode,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '인증번호 다시 보내기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
} 