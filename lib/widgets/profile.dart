import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightViolet,
          ),
          child: ClipOval(
            child: Image.asset(
              profileImage,
              width: 160,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '무비러버',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.gray),
        ),
      ],
    );
  }
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
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: () {},
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
