import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../models/tmdb_movie_dto.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 영화 상세: 평점 등록
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this.memberId, this.movie);
  final RatingApiService _ratingService;
  final int? memberId; // 학습용 현재 회원. 로그인 인증은 아닙니다.
  final TmdbMovieDto movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  /// 평점 등록. 실패하면 상태를 error로 바꾼 뒤 예외를 던짐 (RatingDialog가 실패 문구 표시)
  Future<void> createRating({required int score, String? comment}) async {
    final id = memberId;
    if (id == null) {
      submitStatus = SubmitStatus.error;
      submitMessage = '먼저 회원가입을 완료해 주세요.';
      notifyListeners();
      throw StateError(submitMessage!);
    }
    if (submitStatus == SubmitStatus.submitting) {
      throw StateError('이미 저장 중입니다.');
    }
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await _ratingService.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (!_disposed) {
        submitStatus = SubmitStatus.error;
        submitMessage = writeErrorMessage(error);
        notifyListeners();
      }
      rethrow;
    } catch (_) {
      // 201이 아닌 응답(StateError) 등: submitting에 멈추지 않도록 error로 돌림
      if (!_disposed) {
        submitStatus = SubmitStatus.error;
        submitMessage = '저장에 실패했습니다.';
        notifyListeners();
      }
      rethrow;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
