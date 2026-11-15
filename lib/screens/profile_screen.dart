import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/profile.dart';

// ─────────────────────────────────────────────
// 마이페이지 (/my)
// ─────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const CommonAppBar(title: '내 프로필', centerTitle: false),
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
