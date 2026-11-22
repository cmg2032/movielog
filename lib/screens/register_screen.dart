import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/create_member_request.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

/// 비밀번호 형식 검사 (서버로 보내는 값 그대로 검사하므로 trim 안 함)
/// 통과하면 null, 아니면 입력창에 보여줄 문구
String? validatePasswordFormat(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return '비밀번호를 입력해주세요.';
  if (!_SignUpScreenState._passwordRegExp.hasMatch(password)) {
    return '대문자/소문자/숫자/특수문자를 포함해 8자 이상 입력해주세요.';
  }
  return null;
}

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

  /// 서버(create-member.dto.ts)와 같은 비밀번호 규칙:
  /// 대문자·소문자·숫자·특수문자를 각각 1개 이상 포함한 8~64자
  static final _passwordRegExp = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,64}$',
  );

  /// 입력창·버튼 높이 (같게 맞춤)
  static const _fieldHeight = 56.0;

  /// 가입하기 활성 조건: 모든 입력이 유효 + 닉네임·이메일 중복 확인 통과 + 가입 요청 중 아님
  bool _canSignUp(SignUpViewModel viewModel) {
    final nickname = nicknameController.text.trim();
    return nickname.length >= 2 &&
        nickname.length <= 12 &&
        _emailRegExp.hasMatch(emailController.text.trim()) &&
        _passwordRegExp.hasMatch(passwordController.text) &&
        agreedToTerms &&
        viewModel.canSubmit; // 닉네임·이메일 '사용 가능' + 제출 중 아님
  }

  /// 서버에 회원가입 요청 → 바로 로그인해서 토큰을 세션에 저장 후 홈으로
  Future<void> onSubmitPressed(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final viewModel = context.read<SignUpViewModel>();
    // 중복 확인을 통과한 값과 같음 (값을 고치면 확인 상태가 풀려 버튼이 꺼짐)
    await viewModel.submit(
      CreateMemberRequest(
        email: emailController.text,
        password: passwordController.text,
        nickname: nicknameController.text,
      ),
    );
    if (!context.mounted) return;

    if (viewModel.submitStatus == SubmitStatus.success &&
        viewModel.createdMemberId != null) {
      final login = viewModel.loginResult;
      if (login != null) {
        final saved = await context.read<AuthViewModel>().signIn(
          accessToken: login.accessToken,
          nickname: login.nickname,
        );
        if (!context.mounted) return;
        if (saved) {
          context.go('/home');
        } else {
          // 가입은 됐지만 토큰을 기기에 저장하지 못함 → 로그인 화면에서 다시 시도
          context.go('/login');
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('회원가입은 완료됐지만 로그인 정보를 저장하지 못했어요. 다시 로그인해 주세요.'),
              ),
            );
        }
      } else {
        // 가입은 됐지만 자동 로그인 실패 → 로그인 화면에서 직접 로그인
        context.go('/login');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('회원가입이 완료됐어요. 로그인해 주세요.')),
          );
      }
      return;
    }

    // 실패: 비밀번호 문제는 입력창 아래, 나머지는 SnackBar로 표시
    if (viewModel.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(viewModel.snackbarMessage!)));
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
    // 가입 요청 중에는 뒤로가기(시스템·AppBar)로 화면을 떠나지 못하게 막음
    // 폼은 child로 넘겨서 submitStatus가 바뀔 때 다시 만들지 않음
    return Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) {
        final isSubmitting = viewModel.submitStatus == SubmitStatus.submitting;
        return PopScope(
          canPop: !isSubmitting,
          child: Scaffold(
            appBar: CommonAppBar(
              title: '회원가입',
              centerTitle: true,
              // context.pop()은 PopScope를 거치지 않으므로 여기서 직접 막음
              onBack: () {
                if (isSubmitting) return;
                context.canPop() ? context.pop() : context.go('/login');
              },
            ),
            body: child,
          ),
        );
      },
      child: SafeArea(
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
                                    if (nickname.length > 12) {
                                      return '닉네임은 12자 이하로 입력해 주세요.';
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
                                    errorText: viewModel.passwordErrorText,
                                  ),
                                  validator: (value) =>
                                      validatePasswordFormat(value),
                                  onChanged: (_) {
                                    setState(() {});
                                    viewModel.onPasswordChanged();
                                  },
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
                                  isLoading:
                                      viewModel.submitStatus ==
                                      SubmitStatus.submitting,
                                  onPressed: _canSignUp(viewModel)
                                      ? () => onSubmitPressed(context)
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
