import '../models/movie.dart';
import '../models/profile_stat.dart';

const String nickname = '티모';

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    runtime: 124,
    rating: 4.5,
    ratingCount: 1245,
    tags: ['로맨스', '드라마', '감동적인'],
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    runtime: 132,
    rating: 4.2,
    ratingCount: 892,
    tags: ['SF', '모험', '웅장한'],
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    runtime: 98,
    rating: 4.9,
    ratingCount: 2103,
    tags: ['애니메이션', '판타지', '따뜻한'],
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    runtime: 115,
    rating: 3.8,
    ratingCount: 534,
    tags: ['스릴러', '범죄', '긴장감'],
  ),
];

const double averageRating = 4.5;

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}

const List<ProfileStat> profileStats = [
  ProfileStat(label: '본 영화', value: '342'),
  ProfileStat(label: '평점', value: '4.2'),
  ProfileStat(label: '즐겨찾기', value: '58'),
];

const List<String> favoriteGenres = ['드라마', 'SF', '애니메이션'];

const String profileImage = 'assets/images/profile/profile_movielog.jpg';

enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

class FakeMovieService {
  const FakeMovieService();

  // TODO(5주차 유저별 평점 조회 API): 실제 API 호출로 교체
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
