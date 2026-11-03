import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/featured_movie_card.dart';
import '../widgets/movie_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 영화 탭으로 전환 (영화 탭의 필터·스크롤 상태 유지)
  void _goToMoviesTab(BuildContext context) {
    StatefulNavigationShell.of(context).goBranch(1);
  }

  @override
  Widget build(BuildContext context) {
    final featured = movies.first; // 추천 신작은 아직 mock 데이터

    return Scaffold(
      appBar: CommonAppBar(
        title: 'MovieLog',
        actions: [
          IconButton(
            tooltip: '영화 찾기',
            icon: const Icon(Icons.search),
            color: AppColors.violet,
            onPressed: () => _goToMoviesTab(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '오늘은 어떤\n영화를 볼까요?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FeaturedMovieCard(
              movie: featured,
              badge: '추천 신작',
              description: [
                ...featured.mainGenres,
                '${featured.runtime}분',
              ].join(' · '),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: SectionHeader(
              title: '인기 영화',
              actionLabel: '전체보기',
              onAction: () => _goToMoviesTab(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            // 이 영역만 ViewModel을 구독 → notifyListeners() 때 여기만 다시 그림
            child: Consumer<MovieHomeViewModel>(
              builder: (context, vm, child) {
                switch (vm.status) {
                  case MovieHomeLoadStatus.idle:
                  case MovieHomeLoadStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case MovieHomeLoadStatus.error:
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(vm.message ?? '인기 영화를 불러오지 못했어요.'),
                          TextButton(
                            onPressed: vm.loadPopular,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );

                  case MovieHomeLoadStatus.empty:
                    return const Center(child: Text('표시할 영화가 없어요'));

                  case MovieHomeLoadStatus.success:
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: vm.popularMovies.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final movie = Movie.fromTmdb(vm.popularMovies[index]);
                        return SizedBox(
                          width: 140,
                          child: PopularMovieCard(
                            movie: movie,
                            rank: index + 1,
                          ),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
