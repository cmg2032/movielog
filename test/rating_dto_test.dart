import 'package:flutter_application_1/models/rating_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RatingDto.fromJson', () {
    test('모든 값이 있는 평점', () {
      final dto = RatingDto.fromJson({
        'ratingId': 10,
        'movieId': 550,
        'score': 4,
        'comment': '다시 봐도 좋아요',
        'createdAt': '2026-10-30T12:00:00Z',
      });

      expect(dto.ratingId, 10);
      expect(dto.movieId, 550);
      expect(dto.score, 4);
      expect(dto.comment, '다시 봐도 좋아요');
      expect(dto.createdAt, DateTime.utc(2026, 10, 30, 12));
    });

    test('comment가 null인 평점', () {
      final dto = RatingDto.fromJson({
        'ratingId': 11,
        'movieId': 13,
        'score': 3,
        'comment': null,
        'createdAt': '2026-10-31T09:30:00Z',
      });

      expect(dto.movieId, 13);
      expect(dto.score, 3);
      expect(dto.comment, isNull);
    });
  });
}
