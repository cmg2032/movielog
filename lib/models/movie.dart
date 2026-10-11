class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
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
  final int runtime;
  final double rating;
  final int ratingCount;
  final List<String> tags;

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
