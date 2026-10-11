import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 40,
      itemBuilder: (context, index) {
        return const Icon(Icons.star, color: Colors.amber);
      },
      onRatingUpdate: onChanged,
    );
  }
}

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

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double rating = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '영화는 어떠셨나요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            MovieRatingInput(
              rating: rating,
              onChanged: (value) {
                setState(() {
                  rating = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, rating);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
