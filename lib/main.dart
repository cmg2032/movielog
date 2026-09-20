import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_theme.dart';

void main() {
  for (final Movie movie in movies) {
    debugPrint('${movie.id}. ${movie.title}');
  }
  debugPrint('닉네임: ${displayName(nickname)}');

  runApp(const MovieLogApp());
}

const List<Movie> movies = [
  Movie(id: 1, title: '오디세이'),
  Movie(id: 2, title: '어벤져스'),
  Movie(id: 3, title: '스파이더맨'),
];

const String? nickname = '티모';


class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      home: const ProfileScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 72,
                height:72,
                semanticsLabel: 'MovieLog 로고',
              ),
              const SizedBox(height: 16),
              const Text(
                'MovieLog',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '영화의 순간을 기록하세요',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '보고싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const CommonAppBar(
        title: '내 프로필',
        centerTitle: false,
      ),
      body: const ProfileBody(),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const ProfileHeader(),
          const SizedBox(height: 24),
          const EditProfileButton(),
          const SizedBox(height: 24),
          const ProfileStats(),
          const SizedBox(height: 36),
          const Align(
            alignment: Alignment.centerLeft,
            child: FavoriteGenres(),
          ),
          const SizedBox(height: 24),
         
        ],
      ),
    );
  }
}
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/profile/profile_movielog.jpg',
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '무비러버',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '좋아하는 영화를 기록하고 있어요',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.gray,
          ),
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
      children: const [
        SizedBox(
          width: 110,
          child: StatItem(label: '본 영화', value: '342'),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: StatItem(label: '평점', value: '4.2'),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: StatItem(label: '즐겨찾기', value: '58'),
        ),
      ],
    );
  }
}
class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
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
          children: const [
            Chip(
              label: Text('드라마'),
            ),
            Chip(
              label: Text('SF'),
            ),
            Chip(
              label: Text('애니메이션'),
            ),
          ],
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
          side: BorderSide(
            color: AppColors.violet, 
            width: 1
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          )
        ),
        child: const Text('프로필 수정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        border: Border.all(color: AppColors.lightViolet),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, 
          style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(value, 
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.violet,
            fontWeight: FontWeight.w700,
          )),
        ],
      ),
    );
  }
}
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: titleStyle ??
            AppTextStyles.titleLarge.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
            ),
      ),
      centerTitle: centerTitle,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

String displayName(String? nickname) {
  final String? trimmedNickname = nickname?.trim();

  if (trimmedNickname == null || trimmedNickname.isEmpty) {
    return '이름 없음';
  }

  return trimmedNickname;
}

class Movie {
  const Movie({
    required this.id,
    required this.title,
  });

  final int id;
  final String title;
}