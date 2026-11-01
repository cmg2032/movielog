import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import 'movie_card.dart';
import 'movie_rating.dart';

/// 상세 화면 포스터 (2:3 비율)
/// TMDB 영화면 네트워크 이미지, mock 영화면 로컬 이미지 (movie_card.dart의 MoviePoster 재사용)
class MovieDetailPoster extends StatelessWidget {
  const MovieDetailPoster({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: MoviePoster(movie: movie),
    );
  }
}

class MovieInfo extends StatelessWidget {
  const MovieInfo({super.key, required this.movie, this.myRating});

  final Movie movie;
  final double? myRating;

  // 비어 있는 값은 빼고 표시 (예: "2008 • 액션/범죄 • 152분", TMDB면 "2008 • 액션/범죄")
  String get _subtitle {
    final genres = movie.mainGenres.where((g) => g.isNotEmpty).toList();
    return [
      if (movie.year > 0) '${movie.year}',
      if (genres.isNotEmpty) genres.join('/'),
      if (movie.runtime > 0) '${movie.runtime}분',
    ].join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.gray),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            MovieRatingDisplay(
              rating: averageRating,
              itemSize: 22,
              color: AppColors.violet,
            ),
            const SizedBox(width: 6),
            Text(
              '(${movie.ratingCountLabel})',
              style: const TextStyle(fontSize: 15, color: AppColors.gray),
            ),
          ],
        ),
        if (myRating != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '내 평점',
                style: TextStyle(fontSize: 14, color: AppColors.gray),
              ),
              const SizedBox(width: 8),
              MovieRatingDisplay(
                rating: myRating!,
                itemSize: 18,
                color: AppColors.violet,
              ),
            ],
          ),
        ],
        if (movie.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: movie.tags.map((tag) {
              return TagChip(label: tag);
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.black),
      ),
    );
  }
}

class MovieActionBar extends StatelessWidget {
  const MovieActionBar({
    super.key,
    required this.isFavorite,
    required this.hasRating,
    required this.onFavorite,
    required this.onRate,
  });

  final bool isFavorite;
  final bool hasRating;
  final VoidCallback onFavorite;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                  ),
                  label: const Text('즐겨찾기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.violet,
                    side: const BorderSide(color: AppColors.violet),
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.rate_review_outlined, size: 20),
                  label: Text(hasRating ? '평점 수정하기' : '평점 남기기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
