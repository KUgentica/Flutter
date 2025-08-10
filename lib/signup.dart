import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String _nicknameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
    _emailController.removeListener(_onEmailChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onNicknameChanged() {
    setState(() {
      _validateNickname();
    });
  }

  void _onEmailChanged() {
    setState(() {
      _validateEmail();
    });
  }

  void _onPasswordChanged() {
    setState(() {
      _validatePassword();
      _validateConfirmPassword();
    });
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _validateConfirmPassword();
    });
  }

  void _validateNickname() {
    if (_nicknameController.text.isEmpty) {
      _nicknameError = '';
    } else if (_nicknameController.text.length < 2) {
      _nicknameError = '닉네임은 2자 이상이어야 합니다';
    } else {
      _nicknameError = '';
    }
  }

  void _validateEmail() {
    if (_emailController.text.isEmpty) {
      _emailError = '';
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text)) {
        _emailError = '올바른 이메일 형식이 아닙니다';
      } else {
        _emailError = '';
      }
    }
  }

  void _validatePassword() {
    if (_passwordController.text.isEmpty) {
      _passwordError = '';
    } else if (_passwordController.text.length < 8) {
      _passwordError = '비밀번호는 8자 이상이어야 합니다';
    } else {
      _passwordError = '';
    }
  }

  void _validateConfirmPassword() {
    if (_confirmPasswordController.text.isEmpty) {
      _confirmPasswordError = '';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      _confirmPasswordError = '비밀번호가 일치하지 않습니다';
    } else {
      _confirmPasswordError = '';
    }
  }

  bool get _isFormValid {
    return _nicknameController.text.isNotEmpty &&
           _emailController.text.isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty &&
           _nicknameError.isEmpty &&
           _emailError.isEmpty &&
           _passwordError.isEmpty &&
           _confirmPasswordError.isEmpty;
  }

  void _showSignupSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원가입 완료'),
          content: const Text('회원가입이 완료되었습니다!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _handleSignup() {
    if (_isFormValid) {
      _showSignupSuccessDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  
                  // 제목과 부제목 (가운데 정렬)
                  const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '지금 바로 계정을 만드세요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // 입력 필드들
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: 'Leonardo Smith',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      errorText: _nicknameError.isNotEmpty ? _nicknameError : null,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 이메일 입력
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'www.uihut@gmail.com',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      errorText: _emailError.isNotEmpty ? _emailError : null,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 비밀번호 입력
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '**********',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      errorText: _passwordError.isNotEmpty ? _passwordError : null,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 비밀번호 안내 메시지
                  const Text(
                    '비밀번호는 반드시 8자리 이상이어야 합니다',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  
                  // 비밀번호 확인 입력
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: '**********',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      errorText: _confirmPasswordError.isNotEmpty ? _confirmPasswordError : null,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 회원가입 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _handleSignup : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid ? Colors.blue : Colors.grey[400],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '회원가입',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 로그인 페이지로 이동
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '이미 계정이 있으신가요?',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          '로그인',
                          style: TextStyle(color: Colors.blue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 