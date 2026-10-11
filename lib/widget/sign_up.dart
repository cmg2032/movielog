import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 36),
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.black),
        ),
        SizedBox(height: 8),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

class TermsAgreement extends StatelessWidget {
  const TermsAgreement({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: AppColors.violet,
          onChanged: (checked) {
            onChanged(checked ?? false);
          },
        ),
        const Text('필수 약관에 동의합니다', style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          disabledBackgroundColor: AppColors.lightViolet,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('가입하기', style: AppTextStyles.titleMedium),
      ),
    );
  }
}
