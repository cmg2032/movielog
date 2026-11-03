import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/rating_with_movie.dart';
import '../models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/profile.dart';
import '../widgets/tmdb_poster_image.dart';

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

// ─────────────────────────────────────────────
// 내가 등록한 평점: ViewModel
// ─────────────────────────────────────────────

const int sampleMemberId = 1; // 인증된 '내 계정'이 아닌 학습용 데이터입니다.

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;
      final entries = <RatingWithMovie>[];
      var missingMovies = 0;
      // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed || version != _requestVersion) return;
      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// 내가 등록한 평점: 화면 (/my/ratings)
// 중앙 AppBar + 뒤로가기, 하단 NavigationBar 없음
// ─────────────────────────────────────────────

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => context.pop(),
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          switch (viewModel.status) {
            case MyRatingsLoadStatus.idle:
            case MyRatingsLoadStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case MyRatingsLoadStatus.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.gray,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        viewModel.message ?? '평점을 불러오지 못했습니다.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: viewModel.load,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              );

            case MyRatingsLoadStatus.empty:
              return const Center(child: Text('아직 등록한 평점이 없어요.'));

            case MyRatingsLoadStatus.success:
              final hasNotice = viewModel.message != null;
              return RefreshIndicator(
                color: AppColors.violet,
                onRefresh: viewModel.load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  itemCount: viewModel.ratings.length + (hasNotice ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (hasNotice && index == 0) {
                      return _NoticeBanner(message: viewModel.message!);
                    }
                    final entry =
                        viewModel.ratings[index - (hasNotice ? 1 : 0)];
                    return _MyRatingCard(entry: entry);
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

/// 평점 카드: 포스터 | 제목 · 별점 N / 5 · 후기 · 등록일
class _MyRatingCard extends StatelessWidget {
  const _MyRatingCard({required this.entry});

  final RatingWithMovie entry;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;

    // TMDB에서 영화를 찾지 못하면 대체 제목
    final title = (movie != null && movie.title.isNotEmpty)
        ? movie.title
        : '영화 #${rating.movieId}';

    final comment = rating.comment?.trim() ?? '';
    final hasPoster = movie?.posterPath != null;

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.lightViolet, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 영화 정보가 있을 때만 상세로 이동 (TMDB id 전달)
        onTap: movie == null
            ? null
            : () => context.push(
                '/movies/${movie.id}',
                extra: Movie.fromTmdb(movie),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 포스터 (없으면 빈 박스)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 82,
                  height: 124,
                  child: hasPoster
                      ? TmdbPosterImage(
                          posterPath: movie!.posterPath,
                          width: 82,
                          height: 124,
                        )
                      : const ColoredBox(color: AppColors.lightViolet),
                ),
              ),
              const SizedBox(width: 16),

              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '별점 ${rating.score} / 5',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      comment.isNotEmpty
                          ? comment
                          : (hasPoster ? '작성한 후기가 없어요' : '포스터 정보 없음'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(rating.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightViolet,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.violet),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
