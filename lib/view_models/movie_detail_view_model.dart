import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../models/rating_dto.dart';
import '../models/tmdb_movie_dto.dart';
import 'auth_view_model.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 영화 상세: 평점 등록
class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._ratingService, this._session, this.movie);
  final RatingApiService _ratingService;
  final AuthViewModel _session; // 로그인 여부 확인용 (토큰은 AuthInterceptor가 헤더에 붙임)
  final TmdbMovieDto movie;
  RatingDto? createdRating; // 등록 성공 시 서버가 돌려준 평점
  bool alreadyRated = false; // 마지막 등록 시도가 RATING409_1(이미 평점 있음)이었는지
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  /// 평점 등록. 실패하면 상태를 error로 바꾼 뒤 예외를 던짐 (RatingDialog가 실패 문구 표시)
  Future<void> createRating({required int score, String? comment}) async {
    if (!_session.isLoggedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인이 필요합니다. 마이 탭에서 로그인해 주세요.';
      notifyListeners();
      throw StateError(submitMessage!);
    }
    if (submitStatus == SubmitStatus.submitting) {
      throw StateError('이미 저장 중입니다.');
    }
    // 요청을 보낸 세션 (로그아웃·회원 전환 뒤 늦게 온 응답을 화면에 반영하지 않기 위해)
    final version = _session.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    alreadyRated = false;
    notifyListeners();
    try {
      // body에 memberId 없음: Authorization 헤더(AuthInterceptor)만으로 '나'를 식별
      final created = await _ratingService.createRating(
        CreateRatingRequest(
          movieId: movie.id, // TMDB 영화 id
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      if (!_isCurrent(version)) {
        // 로그아웃·회원 전환 뒤 도착: 반영하지 않고 아래 catch에서 error로 정리
        throw StateError('이전 로그인 세션의 응답입니다.');
      }
      createdRating = created; // 등록 result의 Rating 객체로 화면 갱신
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed || !_isCurrent(version)) rethrow; // 이전 세션의 응답: 상태 변경 없음
      // 401(AUTH401_2/3/4): 세션 정리 → Router가 /login으로 이동
      // (보호 Client가 먼저 정리했다면 버전이 바뀌어 위에서 걸러짐)
      if (isSessionAuthError(error)) await _session.expireSession();
      // 403·409 등: 안내만 하고 로그인 상태 유지
      alreadyRated = isAlreadyRated(error); // RATING409_1 → 화면이 기존 기록 확인 안내
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

  bool _isCurrent(int version) =>
      version == _session.sessionVersion && _session.isLoggedIn;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
