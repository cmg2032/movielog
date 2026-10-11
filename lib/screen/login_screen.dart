import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widget/common_app_bar.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  void _login(BuildContext context) {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '로그인', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              const Text(
                '다시 만나서 반가워요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppColors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                '이메일과 비밀번호를 입력해주세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 64),
              const Text('이메일', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration('이메일 주소를 입력해주세요.'),
              ),
              const SizedBox(height: 24),
              const Text('비밀번호', style: AppTextStyles.titleMedium),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: _inputDecoration('비밀번호를 입력해주세요.'),
                onSubmitted: (_) => _login(context),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _login(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '로그인',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('아직 계정이 없나요?', style: AppTextStyles.bodyMedium),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(
                      '회원가입',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.violet,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
