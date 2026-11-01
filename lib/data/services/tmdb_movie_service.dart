import 'package:dio/dio.dart';

import '../dto/tmdb_movie_page_dto.dart'; // 실제 경로에 맞게
import '../dto/tmdb_genre_dto.dart';
import '../dto/tmdb_movie_dto.dart';

class TmdbMovieService {
  TmdbMovieService(this._dio);
  final Dio _dio;

  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    final withGenres = (genreIds == null || genreIds.isEmpty)
        ? null
        : genreIds.join('|');

    final response = await _dio.get(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        'with_genres': withGenres,
      },
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await _dio.get(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
    );
    final data = response.data as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>? ?? const [];
    return genres
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // tmdb_movie_service.dart, 클래스 안
  Future<List<TmdbMovieDto>> fetchTopFivePopular() async {
    final page = await fetchPopular();
    return page.results.take(5).toList();
  }

  // 탐색 화면용: 최대 30개까지, 중복 없이
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage) {
      final page = await discoverMovies(
        page: pageNumber,
        genreIds: genreId != null ? [genreId] : null,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == 30) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(30).toList();
  }
} // 실제 경로에 맞게
