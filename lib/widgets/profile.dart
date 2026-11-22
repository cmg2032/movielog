import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // v7 GET me 응답(이메일·닉네임·가입일) 표시 (ProfileScreen이 member가 있을 때만 그림)
    // 프로필 수정 후 AuthViewModel.member가 바뀌면 바로 새 값으로 보임
    final member = context.watch<AuthViewModel>().member;
    if (member == null) return const SizedBox.shrink();
    return Column(
      children: [
        // 사진은 기존 디자인 예시 (GET me 응답에 없음)
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.violet,
          ),
          child: ClipOval(
            child: Image.asset(
              profileImage,
              width: 124,
              height: 124,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          member.nickname,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          formatJoinedDate(member.createdAt),
          style: const TextStyle(fontSize: 13, color: AppColors.gray),
        ),
        const SizedBox(height: 4),
        Text(
          member.email,
          style: const TextStyle(fontSize: 14, color: AppColors.gray),
        ),
      ],
    );
  }
}

/// 가입일 → "2026.10.10 가입" (기기 시간대 기준 날짜)
String formatJoinedDate(DateTime createdAt) {
  final local = createdAt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}.${two(local.month)}.${two(local.day)} 가입';
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: profileStats.map((stat) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StatItem(label: stat.label, value: stat.value),
          ),
        );
      }).toList(),
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '선호하는 장르',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: favoriteGenres.map((genre) {
            return Chip(label: Text(genre));
          }).toList(),
        ),
      ],
    );
  }
}

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 내 정보를 불러온 뒤에만 켬 (이메일·현재 닉네임이 있어야 수정 화면을 채울 수 있음)
    final hasMember = context.select<AuthViewModel, bool>(
      (a) => a.member != null,
    );
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: hasMember ? () => context.push('/my/profile/edit') : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.violet,
          backgroundColor: AppColors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: AppColors.violet, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '프로필 수정',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        border: Border.all(color: AppColors.lightViolet),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
