class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
    required this.releaseDate,
    required this.voteCount,
    this.runtime = 0,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;
  final String releaseDate;
  final int voteCount;

  /// 상영시간(분). 상세 API에만 있고, 목록 API에서는 0
  final int runtime;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      genreIds: _parseGenreIds(json),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      releaseDate: json['release_date'] as String? ?? '',
      voteCount: json['vote_count'] as int? ?? 0,
      runtime: json['runtime'] as int? ?? 0,
    );
  }

  /// 목록 API: "genre_ids": [28, 12]
  /// 상세 API: "genres": [{"id": 28, "name": "액션"}, ...]
  static List<int> _parseGenreIds(Map<String, dynamic> json) {
    final ids = json['genre_ids'] as List<dynamic>?;
    if (ids != null) {
      return ids.map((e) => e as int).toList();
    }

    final genres = json['genres'] as List<dynamic>? ?? const [];
    return genres.map((g) => (g as Map<String, dynamic>)['id'] as int).toList();
  }
}
