import 'tmdb_movie_dto.dart';

// tmdb_movie_page_dto.dart
class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });
  final int page;
  final List<TmdbMovieDto> results;
  final int totalPages;
  final int totalResults;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? const [];
    return TmdbMoviePageDto(
      page: json['page'] as int? ?? 1,
      results: list
          .map((e) => TmdbMovieDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: json['total_pages'] as int? ?? 1,
      totalResults: json['total_results'] as int? ?? 0,
    );
  }
}
