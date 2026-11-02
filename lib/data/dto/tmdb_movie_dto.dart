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

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>? ?? const [])
          .map((e) => e as int)
          .toList(),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      releaseDate: json['release_date'] as String? ?? '',
      voteCount: json['vote_count'] as int? ?? 0,
    );
  }
}
