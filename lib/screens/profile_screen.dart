import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/profile.dart';

// ─────────────────────────────────────────────
// 마이페이지 (/my)
// ─────────────────────────────────────────────

/// 내 정보(AuthViewModel.member) 상태에 따라 화면 전체를 바꿈
/// - 불러오는 중: 화면 가운데 인디케이터
/// - 실패(MemberLoadStatus.error): 안내 + [다시 시도] (로그아웃하지 않음)
/// - 성공: 프로필 본문 + 앱바 [로그아웃]
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.member == null) {
      final failed = auth.memberStatus == MemberLoadStatus.error;
      return Scaffold(
        appBar: const CommonAppBar(title: '내 프로필', centerTitle: true),
        body: Center(
          child: failed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '내 정보를 불러오지 못했어요.',
                      style: TextStyle(fontSize: 15, color: AppColors.gray),
                    ),
                    const SizedBox(height: 24),
                    MovieLogButton(
                      label: '다시 시도',
                      width: 218,
                      onPressed: () => auth.loadMember(force: true),
                    ),
                  ],
                )
              // MainScreen이 시작한 로딩 (시작 전 idle도 곧 loading이 되므로 같이 표시)
              : const CircularProgressIndicator(color: AppColors.violet),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: CommonAppBar(
        title: '내 프로필',
        centerTitle: false,
        actions: [
          // 로그아웃: 토큰과 member를 지우고, Router가 /login으로 보냄
          TextButton(
            onPressed: () {
              auth.logout();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('로그아웃했습니다.')));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.violet),
            child: const Text('로그아웃', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: const ProfileBody(),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          SizedBox(height: 16),
          ProfileHeader(),
          SizedBox(height: 24),
          EditProfileButton(),
          SizedBox(height: 32),
          ProfileStats(),
          SizedBox(height: 24),
          MyRatingsEntry(), // 「내가 등록한 평점」 진입 행
          SizedBox(height: 32),
          Align(alignment: Alignment.centerLeft, child: FavoriteGenres()),
        ],
      ),
    );
  }
}

/// 마이페이지 → 내가 등록한 평점 진입 행
class MyRatingsEntry extends StatelessWidget {
  const MyRatingsEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightViolet, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/my/ratings'),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '내가 등록한 평점',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 28, color: AppColors.violet),
            ],
          ),
        ),
      ),
    );
  }
}
