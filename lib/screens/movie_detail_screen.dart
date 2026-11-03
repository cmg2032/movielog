import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_detail.dart';
import '../widgets/rating_dialog.dart';

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
        // 이미 남긴 평점이 있으면 넘겨서 "다시 선택하기" 화면으로 시작
        return RatingDialog(initialRating: myRating ?? 0);
      },
    );

    debugPrint('평점 결과: $rating (movieId: ${widget.movie.id})');

    if (rating == null || !mounted) return; // 닫기 = 변경 없음

    if (rating == 0) {
      // 평점 초기화 후 확인 = 삭제
      setState(() {
        myRating = null;
      });
      _showMessage('평점을 삭제했어요.');
      return;
    }

    setState(() {
      myRating = rating;
    });
    _showMessage('평점 ${rating.toStringAsFixed(1)}점을 저장했어요.');
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
            MovieDetailPoster(movie: movie),
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
