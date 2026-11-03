import 'tmdb_movie_dto.dart';

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    this.posterPath, // ← 추가
    this.runtime = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.tags = const [],
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final String? posterPath; // ← 추가 (TMDB 영화만 값 있음)
  final int runtime;
  final double rating;
  final int ratingCount;
  final List<String> tags;

  // ← 추가: TMDB DTO → Movie
  factory Movie.fromTmdb(
    TmdbMovieDto dto, {
    Map<int, String> genreNames = const {},
  }) {
    final names = dto.genreIds
        .map((id) => genreNames[id])
        .whereType<String>()
        .toList();

    return Movie(
      id: dto.id,
      title: dto.title,
      genre: names.isNotEmpty ? names.first : '',
      year:
          int.tryParse(
            dto.releaseDate.length >= 4 ? dto.releaseDate.substring(0, 4) : '',
          ) ??
          0,
      posterAsset: '',
      posterPath: dto.posterPath,
      rating: dto.voteAverage,
      ratingCount: dto.voteCount,
      tags: names,
    );
  }

  List<String> get mainGenres {
    return tags.isEmpty ? [genre] : tags.take(2).toList();
  }

  String get ratingCountLabel {
    return ratingCount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
  }
}
