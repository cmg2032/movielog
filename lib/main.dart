import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
      home: const SignUpScreen(),
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
                height: 72,
                semanticsLabel: 'MovieLog 로고',
              ),
              const SizedBox(height: 16),
              const Text(
                'MovieLog',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '영화의 순간을 기록하세요',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
      appBar: const CommonAppBar(title: '내 프로필', centerTitle: false),
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
          const Align(alignment: Alignment.centerLeft, child: FavoriteGenres()),
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
          child: profileImage != null
              ? Image.asset(
                  profileImage!,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 160,
                  height: 160,
                  color: AppColors.lightGray,
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: AppColors.violet,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        const Text(
          '무비러버',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          '좋아하는 영화를 기록하고 있어요',
          style: TextStyle(fontSize: 16, color: AppColors.gray),
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '선호하는 장르',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/icons/search.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
          ],
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
        style:
            titleStyle ??
            AppTextStyles.titleLarge.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
            ),
      ),
      centerTitle: centerTitle,
      leading: onBack == null
          ? null
          : IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
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
  bool get canSignUp {
    final nickname = nicknameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    return nickname.length >= 2 &&
        RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email) &&
        password.length >= 8 &&
        agreedToTerms;
  }

  Widget? statusIcon(String text, bool isValid) {
    if (text.trim().isEmpty) return null;

    return Icon(
      isValid ? Icons.check_circle : Icons.error_outline,
      color: isValid ? AppColors.violet : Colors.red,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '회원가입', centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SignUpHeader(),

                            const SizedBox(height: 64),
                            const Text('닉네임', style: AppTextStyles.titleMedium),

                            const SizedBox(height: 10),

                            TextFormField(
                              controller: nicknameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: '닉네임을 입력해주세요',
                                suffixIcon: statusIcon(
                                  nicknameController.text,
                                  nicknameController.text.trim().length >= 2,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final nickname = value?.trim() ?? '';

                                if (nickname.isEmpty) {
                                  return '닉네임을 입력해주세요.';
                                }

                                if (nickname.length < 2) {
                                  return '닉네임은 두 글자 이상 입력해주세요.';
                                }

                                return null;
                              },
                              onChanged: (_) {
                                setState(() {});
                              },
                              onFieldSubmitted: (_) {
                                emailFocusNode.requestFocus();
                              },
                            ),

                            const SizedBox(height: 24),

                            const Text('이메일', style: AppTextStyles.titleMedium),

                            const SizedBox(height: 10),

                            TextFormField(
                              controller: emailController,
                              focusNode: emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: '이메일 주소를 입력해주세요.',
                                suffixIcon: statusIcon(
                                  emailController.text,
                                  RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                      .hasMatch(emailController.text.trim()),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return '이메일을 입력해주세요.';
                                }

                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                    .hasMatch(email)) {
                                  return '올바른 이메일 주소를 입력해주세요.';
                                }

                                return null;
                              },
                              onChanged: (_) {
                                setState(() {});
                              },
                              onFieldSubmitted: (_) {
                                passwordFocusNode.requestFocus();
                              },
                            ),

                            const SizedBox(height: 24),

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
                              decoration: InputDecoration(
                                hintText: '비밀번호를 입력해주세요.',
                                suffixIcon: statusIcon(
                                  passwordController.text,
                                  passwordController.text.trim().length >= 8,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
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
                              onChanged: (_) {
                                setState(() {});
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
                                setState(() {
                                  agreedToTerms = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            SignUpButton(
                              onPressed: canSignUp
                                  ? () {
                                      final isValid =
                                          formKey.currentState?.validate() ??
                                          false;
                                      if (isValid) {
                                        debugPrint('회원가입 가능');
                                      }
                                    }
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
                                  onPressed: () {
                                    debugPrint('로그인화면');
                                  },
                                  child: Text(
                                    '로그인',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.violet,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
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

class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

class ProfileStat {
  const ProfileStat({required this.label, required this.value});

  final String label;
  final String value;
}

const List<ProfileStat> profileStats = [
  ProfileStat(label: '본 영화', value: '342'),
  ProfileStat(label: '평점', value: '4.2'),
  ProfileStat(label: '즐겨찾기', value: '58'),
];
const List<String> favoriteGenres = ['드라마', 'SF', '애니메이션'];
const String? profileImage = 'assets/images/profile/profile_movielog.jpg';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key, required this.movieTitle});
 
  final String movieTitle;
 
  @override
  State<RatingScreen> createState() => _RatingScreenState();
}
 
class _RatingScreenState extends State<RatingScreen> {
  double rating = 0; 
 
  bool get canSave => rating > 0;
 
  String get ratingMessage {
    if (rating == 0) return '별을 눌러 평점을 남겨주세요';
    if (rating <= 1.5) return '별로였어요';
    if (rating <= 2.5) return '그저 그랬어요';
    if (rating <= 3.5) return '괜찮았어요';
    if (rating <= 4.5) return '재밌었어요';
    return '최고예요!';
  }
 
  void _save() {
    debugPrint('${widget.movieTitle} 평점 저장: $rating');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('평점 $rating점을 저장했어요.')),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '평점 남기기', centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              Text(
                widget.movieTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
 
              const SizedBox(height: 8),
 
              const Text(
                '이 영화는 어떠셨나요?',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
 
              const SizedBox(height: 40),
 
              Center(
                child: RatingBar.builder(
                  initialRating: rating,
                  minRating: 0.5,
                  allowHalfRating: true, // 0.5점 단위
                  itemCount: 5,
                  itemSize: 44,
                  glow: false,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.violet,
                  ),
                  unratedColor: AppColors.lightViolet,
                  onRatingUpdate: (value) {
                    setState(() {
                      rating = value;
                    });
                  },
                ),
              ),
 
              const SizedBox(height: 16),
 
              // 현재 점수와 한 줄 평
              Text(
                rating == 0 ? '- / 5.0' : '${rating.toStringAsFixed(1)} / 5.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.violet,
                  fontWeight: FontWeight.w700,
                ),
              ),
 
              const SizedBox(height: 4),
 
              Text(
                ratingMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
 
              const Spacer(),
 
              SignUpButtonLike(
                label: '평점 저장하기',
                onPressed: canSave ? _save : null,
              ),
 
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
 
class SignUpButtonLike extends StatelessWidget {
  const SignUpButtonLike({
    super.key,
    required this.label,
    required this.onPressed,
  });
 
  final String label;
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
          disabledForegroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: AppTextStyles.titleMedium),
      ),
    );
  }
}
 
