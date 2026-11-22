import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/storage/saved_email_storage.dart';
import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/form_field_style.dart';
import '../widgets/movielog_button.dart';

/// 로그인 화면
/// - 버튼은 AuthViewModel.login()만 호출합니다. 성공하면 signedIn → Router가 /home으로 보냄
/// - 실패하면 signedOut + message → Form 아래 오류 문구 (AUTH401_1은 만료 안내 아님)
/// - 토큰 만료로 쫓겨난 경우(sessionExpired)만 SnackBar로 한 번 안내
/// - [이메일 저장] 체크 시 로그인 성공 후 이메일만 저장 (비밀번호·토큰은 저장하지 않음)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController(); // 비밀번호는 로그·저장소에 남기지 않음
  late final AuthViewModel _auth;
  late final SavedEmailStorage _emailStorage;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _emailStorage = context.read<SavedEmailStorage>();
    _loadSavedEmail();
    // 화면이 열려 있는 중에 만료되는 경우
    _auth.addListener(_showSessionExpired);
    // 이미 만료된 상태로 화면이 처음 열리는 경우
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionExpired());
  }

  void _showSessionExpired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired(); // 같은 SnackBar가 반복되지 않게 끔
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')));
  }

  /// 저장된 이메일이 있으면 채우고 체크 (읽기 실패는 무시: 직접 입력하면 됨)
  Future<void> _loadSavedEmail() async {
    String? saved;
    try {
      saved = await _emailStorage.readEmail();
    } catch (_) {
      return;
    }
    if (!mounted || saved == null || saved.isEmpty) return;
    if (_email.text.isEmpty) _email.text = saved; // 이미 입력을 시작했으면 덮지 않음
    setState(() => _rememberEmail = true);
  }

  /// 로그인 성공 뒤: 체크했으면 이메일 저장, 해제했으면 지움 (실패해도 로그인에는 영향 없음)
  Future<void> _updateSavedEmail(String email) async {
    try {
      if (_rememberEmail) {
        await _emailStorage.saveEmail(email);
      } else {
        await _emailStorage.clearEmail();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _auth.removeListener(_showSessionExpired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    await _auth.login(email, _password.text);
    // 성공하면 redirect로 이 화면이 사라질 수 있으므로 mounted와 관계없이 저장소만 갱신
    if (_auth.status == AuthStatus.signedIn) await _updateSavedEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = auth.status == AuthStatus.authenticating;
    final enabled = !loading && !auth.storageCleanupInProgress;
    return PopScope(
      canPop: !loading, // 로그인 중 이탈 방지
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text('로그인', style: TextStyle(color: AppColors.violet)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 64),
                  Center(
                    child: SvgPicture.asset(
                      'assets/logos/movielog_logo.svg',
                      width: 64,
                      height: 64,
                      semanticsLabel: 'MovieLog 로고',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MovieLog에 로그인',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, color: AppColors.black),
                  ),
                  const SizedBox(height: 36),
                  const FieldLabel('이메일'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _email,
                    enabled: enabled,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: movieLogInputDecoration(),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? '이메일을 입력해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const FieldLabel('비밀번호'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _password,
                    enabled: enabled,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: enabled ? (_) => _submit() : null,
                    decoration: movieLogInputDecoration(),
                    validator: (value) =>
                        (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  // Challenge: 이메일 저장
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberEmail,
                          activeColor: AppColors.violet,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: enabled
                              ? (value) =>
                                    setState(() => _rememberEmail = value!)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: enabled
                            ? () => setState(
                                () => _rememberEmail = !_rememberEmail,
                              )
                            : null,
                        child: const Text(
                          '이메일 저장',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 로그인 실패 문구: 입력 오류 / 연결 실패 / 요청 실패 / 저장 실패를 각각 다르게 표시
                  if (auth.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        auth.message!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 56),
                  MovieLogButton(
                    label: '로그인',
                    width: double.infinity,
                    isLoading: loading, // 통신 중에는 비활성 + 인디케이터
                    onPressed: enabled ? _submit : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '계정이 없나요?',
                        style: TextStyle(fontSize: 13, color: AppColors.gray),
                      ),
                      TextButton(
                        onPressed: enabled
                            ? () => context.push('/register')
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.violet,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
