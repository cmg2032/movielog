import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widget/common_app_bar.dart';
import '../widget/movie_detail.dart';
import '../widget/movie_rating.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;
  double? myRating;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    _showMessage(isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
  }

  Future<void> _openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) {
        return const RatingDialog();
      },
    );

    debugPrint('$rating');

    if (rating == null || !mounted) return;

    setState(() {
      myRating = rating;
    });
    _showMessage('평점 $rating점을 저장했어요.');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/movies');
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Cinema Archive',
        centerTitle: true,
        onBack: _goBack,
        actions: [
          IconButton(
            tooltip: '공유',
            icon: const Icon(Icons.share),
            onPressed: () => _showMessage('공유 기능은 준비 중이에요.'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoviePoster(posterAsset: movie.posterAsset),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: MovieInfo(movie: movie, myRating: myRating),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MovieActionBar(
        isFavorite: isFavorite,
        hasRating: myRating != null,
        onFavorite: _toggleFavorite,
        onRate: _openRatingDialog,
      ),
    );
  }
}
