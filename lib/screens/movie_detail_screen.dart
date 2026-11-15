import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_detail.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;
  int? myScore; // 이 화면에서 저장에 성공한 내 평점

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
    int? savedScore;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          savedScore = score; // 상세 화면의 내 별점 표시용
          final viewModel = context.read<MovieDetailViewModel>();
          try {
            await viewModel.createRating(score: score, comment: comment);
          } catch (_) {
            // 실패 Snackbar (400/404/409 등 서버 message). Dialog는 입력을 유지한 채 열려 있음
            if (mounted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(viewModel.submitMessage ?? '저장에 실패했습니다.'),
                  ),
                );
            }
            rethrow;
          }
        },
      ),
    );

    if (!mounted || saved != true) return;
    setState(() => myScore = savedScore); // 상세 화면의 내 별점 표시용

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
      ),
    );
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
    // 화면 위젯은 앱 모델(Movie)을 쓰므로 뷰모델의 TMDB 영화를 변환
    final movie = Movie.fromTmdb(context.read<MovieDetailViewModel>().movie);

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
              child: MovieInfo(movie: movie, myRating: myScore?.toDouble()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MovieActionBar(
        isFavorite: isFavorite,
        hasRating: myScore != null,
        onFavorite: _toggleFavorite,
        onRate: _openRatingDialog,
      ),
    );
  }
}
