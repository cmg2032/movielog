import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';

import '../theme/app_colors.dart';
import '../widget/common_app_bar.dart';

import '../widget/section_header.dart';
import '../widget/featured_movie_card.dart';

import '../widget/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = movies.first;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'MovieLog',
        actions: [
          IconButton(
            tooltip: '검색',
            icon: const Icon(Icons.search),
            color: AppColors.violet,
            onPressed: () => context.go('/movies'),
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
              onAction: () => context.go('/movies'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: movies.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 12);
              },
              itemBuilder: (context, index) {
                final movie = movies[index];
                return SizedBox(width: 150, child: MovieCard(movie: movie));
              },
            ),
          ),
        ],
      ),
    );
  }
}
