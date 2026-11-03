import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();

  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool agreedToTerms = false;
  bool obscurePassword = true;

  static final _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  /// 입력창·버튼 높이 (같게 맞춤)
  static const _fieldHeight = 56.0;

  /// 가입하기 활성 조건: 모든 입력이 유효 + 닉네임·이메일 중복 확인 통과
  bool _canSignUp(SignUpViewModel viewModel) {
    return nicknameController.text.trim().length >= 2 &&
        viewModel.isNicknameAvailable &&
        _emailRegExp.hasMatch(emailController.text.trim()) &&
        viewModel.isEmailAvailable &&
        passwordController.text.trim().length >= 8 &&
        agreedToTerms;
  }

  /// 실제 회원가입 제출은 이번 주차 범위 아님 → 유효하면 홈으로
  void _onSubmit() {
    final isValid = formKey.currentState?.validate() ?? false;
    if (isValid) {
      context.go('/home');
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
    String? errorText,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border(AppColors.lightGray),
      enabledBorder: border(AppColors.lightGray),
      focusedBorder: border(AppColors.violet, 2),
      errorBorder: border(Colors.red),
      focusedErrorBorder: border(Colors.red, 2),
    );
  }

  /// 중복 확인 결과가 '사용 가능'일 때만 입력창 안에 체크 표시
  Widget? _checkIcon(CheckStatus status) {
    return status == CheckStatus.available
        ? const Icon(Icons.check_circle, color: AppColors.violet)
        : null;
  }

  /// 입력창 아래 안내 문구 (확인 중 / 사용 가능)
  /// 중복·실패는 입력창의 errorText(빨간 글씨)로 표시
  Widget? _checkMessage(CheckStatus status, String label) {
    return switch (status) {
      CheckStatus.checking => Text(
        '$label 사용 가능 여부를 확인 중입니다.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
        ),
      ),
      CheckStatus.available => Text(
        '사용 가능한 $label입니다.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade700,
        ),
      ),
      _ => null,
    };
  }

  /// [입력창] 8px [중복 확인 버튼] + 아래 안내 문구
  Widget _checkField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required CheckStatus status,
    required String? errorText,
    required bool canCheck,
    required ValueChanged<String> onChanged,
    required VoidCallback onCheck,
    required FormFieldValidator<String> validator,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    final message = _checkMessage(status, label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _inputDecoration(
                  hintText: hintText,
                  errorText: errorText,
                  suffixIcon: _checkIcon(status), // 체크는 입력창 안에만
                ),
                validator: validator,
                onChanged: onChanged,
                onFieldSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            MovieLogButton(
              label: '중복 확인',
              height: _fieldHeight,
              isLoading: status == CheckStatus.checking, // 인디케이터만 + 비활성
              onPressed: canCheck ? onCheck : null,
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.only(left: 4), child: message),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/start'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 560 : double.infinity,
                      minHeight: (constraints.maxHeight - 32).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Consumer<SignUpViewModel>(
                      builder: (context, viewModel, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SignUpHeader(),
                                const SizedBox(height: 40),

                                // 닉네임
                                const Text(
                                  '닉네임',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                _checkField(
                                  label: '닉네임',
                                  controller: nicknameController,
                                  hintText: '닉네임을 입력해주세요',
                                  status: viewModel.nicknameCheckStatus,
                                  errorText: viewModel.nicknameErrorText,
                                  canCheck: viewModel.canCheckNickname,
                                  onChanged: viewModel.onNicknameChanged,
                                  onCheck: () => viewModel.checkNickname(
                                    nicknameController.text,
                                  ),
                                  onSubmitted: (_) =>
                                      emailFocusNode.requestFocus(),
                                  validator: (value) {
                                    final nickname = value?.trim() ?? '';
                                    if (nickname.isEmpty) {
                                      return '닉네임을 입력해 주세요.';
                                    }
                                    if (nickname.length < 2) {
                                      return '닉네임은 두 글자 이상 입력해 주세요.';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // 이메일
                                const Text(
                                  '이메일',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                _checkField(
                                  label: '이메일',
                                  controller: emailController,
                                  focusNode: emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  hintText: 'movie@umc.com',
                                  status: viewModel.emailCheckStatus,
                                  errorText: viewModel.emailErrorText,
                                  canCheck: viewModel.canCheckEmail,
                                  onChanged: viewModel.onEmailChanged,
                                  onCheck: () => viewModel.checkEmail(
                                    emailController.text,
                                  ),
                                  onSubmitted: (_) =>
                                      passwordFocusNode.requestFocus(),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty) {
                                      return '이메일을 입력해주세요.';
                                    }
                                    if (!_emailRegExp.hasMatch(email)) {
                                      return '올바른 이메일 주소를 입력해주세요.';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // 비밀번호 (중복 확인 없음, 전체 너비)
                                const Text(
                                  '비밀번호',
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: passwordController,
                                  focusNode: passwordFocusNode,
                                  obscureText: obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: _inputDecoration(
                                    hintText: '비밀번호를 입력해주세요.',
                                  ),
                                  validator: (value) {
                                    final password = value?.trim() ?? '';
                                    if (password.isEmpty) {
                                      return '비밀번호를 입력해주세요.';
                                    }
                                    if (password.length < 8) {
                                      return '비밀번호는 8글자 이상 입력해주세요.';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setState(() {}),
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              ],
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 40),
                                TermsAgreement(
                                  value: agreedToTerms,
                                  onChanged: (value) {
                                    setState(() => agreedToTerms = value);
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Form 하단 버튼: 전체 너비
                                MovieLogButton(
                                  label: '가입하기',
                                  width: double.infinity,
                                  height: _fieldHeight,
                                  onPressed: _canSignUp(viewModel)
                                      ? _onSubmit
                                      : null,
                                ),

                                const SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '이미 계정이 있나요?',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/login'),
                                      child: Text(
                                        '로그인',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(color: AppColors.violet),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 24),
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 6),
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
          onChanged: (checked) => onChanged(checked ?? false),
        ),
        const Text(
          '필수 약관에 동의합니다',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
