import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

/// 별점 입력 (1점 단위, 1~5점 → 서버 평점 규칙과 동일)
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RatingBar(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      ignoreGestures: !enabled,
      itemCount: 5,
      itemSize: 48,
      itemPadding: const EdgeInsets.symmetric(horizontal: 2),
      ratingWidget: RatingWidget(
        full: const Icon(Icons.star_rounded, color: AppColors.violet),
        half: const Icon(Icons.star_half_rounded, color: AppColors.violet),
        empty: const Icon(Icons.star_border_rounded, color: AppColors.violet),
      ),
      onRatingUpdate: onChanged,
    );
  }
}

/// 별점 표시 (읽기 전용) + 숫자
class MovieRatingDisplay extends StatelessWidget {
  const MovieRatingDisplay({
    super.key,
    required this.rating,
    this.itemSize = 24,
    this.color = Colors.amber,
  });

  final double rating;
  final double itemSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemCount: 5,
          itemSize: itemSize,
          itemBuilder: (context, index) {
            return Icon(Icons.star, color: color);
          },
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
