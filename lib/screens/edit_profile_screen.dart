import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/form_field_style.dart';
import '../widgets/movielog_button.dart';

/// 프로필 수정 (/my/profile/edit): 이메일은 읽기 전용, 닉네임만 수정
/// - 성공: AuthViewModel.member 교체 → SnackBar → 마이페이지로 복귀
/// - 입력/중복 오류: 화면에 남아 필드 아래 오류 표시 (입력값 유지)
/// - 401: 세션 정리 → Router가 /login으로 이동
/// - 네트워크 오류: SnackBar 안내, 로그아웃하지 않고 재시도 가능
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final member = context.read<AuthViewModel>().member;
    _controller = TextEditingController(text: member?.nickname ?? '')
      ..addListener(_onTextChanged);
  }

  /// 입력이 바뀔 때마다 '변경 내용 있음' 여부를 다시 계산 (PopScope.canPop 갱신)
  void _onTextChanged() => setState(() {});

  /// 현재 닉네임과 다른 값을 입력했는지 (앞뒤 공백은 저장 때도 빠지므로 무시)
  bool get _hasChanges {
    final current = context.read<AuthViewModel>().member?.nickname ?? '';
    return _controller.text.trim() != current;
  }

  /// 마이페이지로 이동 (주소로 바로 들어와 돌아갈 화면이 없으면 /my로)
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my');
    }
  }

  /// 변경 내용이 있는데 뒤로가기: 확인 Dialog → [나가기]면 마이페이지, [계속 수정]이면 머무름
  Future<void> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => const _DiscardChangesDialog(),
    );
    if (leave == true && mounted) _leave();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<EditProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final success = await viewModel.save(_controller.text);
    if (!mounted) return;

    if (success) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      router.pop(); // 마이페이지로 돌아가면 새 닉네임이 이미 반영되어 있습니다.
    } else if (viewModel.message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(viewModel.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (a) => a.member?.email,
    );

    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
        final saving = viewModel.status == EditProfileStatus.saving;
        return PopScope(
          // 저장 중에는 뒤로가기 막음, 변경 내용이 있으면 확인 Dialog를 거침
          canPop: !saving && !_hasChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || saving) return;
            _confirmDiscard();
          },
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text(
                '프로필 수정',
                style: TextStyle(color: AppColors.violet),
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('이메일 (변경할 수 없습니다)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: email,
                      enabled: false, // email은 읽기 전용입니다.
                      style: const TextStyle(color: AppColors.gray),
                      decoration: movieLogInputDecoration(readOnly: true),
                    ),
                    const SizedBox(height: 24),
                    const FieldLabel('닉네임'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      enabled: !saving,
                      maxLength: 12,
                      textInputAction: TextInputAction.done,
                      onSubmitted: saving ? null : (_) => _submit(),
                      // 오류 문구(왼쪽)와 같은 줄 오른쪽에 "4 / 12"
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => Text(
                            '$currentLength / $maxLength',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray,
                            ),
                          ),
                      decoration: movieLogInputDecoration(
                        errorText: viewModel.nicknameError,
                      ),
                    ),
                    const Spacer(),
                    MovieLogButton(
                      label: '저장',
                      width: double.infinity,
                      isLoading: saving,
                      onPressed: saving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "변경 내용을 버릴까요?" 확인 Dialog: [계속 수정] → false, [나가기] → true
class _DiscardChangesDialog extends StatelessWidget {
  const _DiscardChangesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '변경 내용을 버릴까요?',
              style: TextStyle(fontSize: 20, color: AppColors.black),
            ),
            const SizedBox(height: 16),
            const Text(
              '저장하지 않은 내용은 사라집니다.',
              style: TextStyle(fontSize: 14, color: AppColors.gray),
            ),
            const SizedBox(height: 56),
            Row(
              children: [
                Expanded(
                  child: MovieLogButton(
                    label: '계속 수정',
                    backgroundColor: AppColors.lightViolet,
                    foregroundColor: AppColors.violet,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: MovieLogButton(
                    label: '나가기',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
