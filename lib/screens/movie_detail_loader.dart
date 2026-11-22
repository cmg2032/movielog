import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/tmdb_movie_dto.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import 'movie_detail_screen.dart';

/// 영화 상세의 시작점: 넘겨받은 영화가 없으면 TMDB 상세를 불러온 뒤 화면을 보여줌
class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });
  final int movieId;
  final TmdbMovieDto? initialMovie;
  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late final Future<TmdbMovieDto> _movieFuture;
  @override
  void initState() {
    super.initState();
    _movieFuture = widget.initialMovie != null
        ? Future.value(widget.initialMovie!)
        : context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto>(
      future: _movieFuture, // build마다 새 Future를 만들지 않습니다.
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('영화를 불러오지 못했습니다.')));
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            context.read<AuthViewModel>(),
            snapshot.data!,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}
