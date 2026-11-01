import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/dto/tmdb_genre_dto.dart';
import '../data/dto/tmdb_movie_dto.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import 'tmdb_poster_image.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
      child: MovieCardContent(movie: movie),
    );
  }
}

class MovieCardContent extends StatelessWidget {
  const MovieCardContent({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MoviePoster(movie: movie),
                Positioned(
                  top: 8,
                  right: 8,
                  child: RatingBadge(rating: movie.rating),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.gray),
        ),
      ],
    );
  }

  // 연도나 장르가 비어 있으면 빼고 표시 (예: "2024 · 액션", "2024", "액션")
  String get _subtitle {
    final parts = <String>[
      if (movie.year > 0) '${movie.year}',
      if (movie.genre.isNotEmpty) movie.genre,
    ];
    return parts.join(' · ');
  }
}

/// TMDB 영화면 네트워크 이미지, mock 영화면 로컬 이미지
class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    if (movie.posterPath != null) {
      return TmdbPosterImage(
        posterPath: movie.posterPath,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (movie.posterAsset.isEmpty) {
      return const PosterPlaceholder();
    }

    return Image.asset(
      movie.posterAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const PosterPlaceholder();
      },
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.white),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class PosterPlaceholder extends StatelessWidget {
  const PosterPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lightGray,
      child: Center(
        child: Icon(Icons.movie_outlined, size: 48, color: AppColors.violet),
      ),
    );
  }
}

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies, this.genres = const []});

  final List<TmdbMovieDto> movies;
  final List<TmdbGenreDto> genres;

  @override
  Widget build(BuildContext context) {
    final genreNames = {for (final g in genres) g.id: g.name};

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (context, index) {
        return MovieCard(
          movie: Movie.fromTmdb(movies[index], genreNames: genreNames),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// 홈 "인기 영화" 전용 카드: 좌측 상단 순위 + 제목 + ⭐ 평점
// ─────────────────────────────────────────────

class PopularMovieCard extends StatelessWidget {
  const PopularMovieCard({super.key, required this.movie, required this.rank});

  final Movie movie;
  final int rank;

  static const _starColor = Color(0xFFE0A93B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MoviePoster(movie: movie),
                  Positioned(top: 8, left: 8, child: RankBadge(rank: rank)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: _starColor),
              const SizedBox(width: 2),
              Text(
                movie.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$rank',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}
