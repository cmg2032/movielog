import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';

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
                Image.asset(
                  movie.posterAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const PosterPlaceholder();
                  },
                ),
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
          '${movie.year} · ${movie.genre}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.gray),
        ),
      ],
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
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (context, index) {
        return MovieCard(movie: movies[index]);
      },
    );
  }
}
