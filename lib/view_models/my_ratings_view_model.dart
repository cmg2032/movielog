import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/rating_with_movie.dart';
import '../models/tmdb_movie_dto.dart';

/// 내가 등록한 평점 (/my/ratings) ViewModel
enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService);
  final RatingApiService _service; // 토큰으로 '나'를 식별하므로 memberId가 필요 없음
  final TmdbMovieService _movieService;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  // ── 선택 삭제 ──
  bool isSelecting = false; // 선택 모드 (카드에 체크박스 표시)
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  /// 다중 삭제 중 일부 실패 문구 (화면이 SnackBar로 표시, 전부 성공이면 null)
  String? deleteSelectedMessage;

  void toggleSelecting() {
    if (isDeletingSelected) return;
    isSelecting = !isSelecting;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void toggleSelected(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    notifyListeners();
  }

  /// 선택한 평점을 하나씩 삭제. 실패한 항목은 선택 상태를 유지하고, 끝나면 목록을 다시 조회
  Future<void> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return;
    isDeletingSelected = true;
    deleteSelectedMessage = null;
    notifyListeners();
    var failed = 0;
    final deleted = <int>{};
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(ratingId);
          selectedRatingIds.remove(ratingId);
          deleted.add(ratingId);
        } on DioException {
          failed++;
          // 실패한 항목은 선택 상태를 유지합니다.
        }
        if (_disposed) return;
      }
    } finally {
      if (!_disposed) {
        isDeletingSelected = false;
        // 성공한 항목은 바로 목록에서 뺌 (아래 재조회가 실패해도 화면이 맞도록)
        ratings = ratings
            .where((entry) => !deleted.contains(entry.rating.ratingId))
            .toList();
        if (ratings.isEmpty) status = MyRatingsLoadStatus.empty;
        if (selectedRatingIds.isEmpty) isSelecting = false; // 모두 지웠으면 선택 모드 종료
        notifyListeners(); // 예상하지 못한 오류에도 로딩을 해제합니다.
      }
    }
    await _refreshAfterWrite(); // GET 실패는 삭제 성공 여부와 분리합니다.
    if (_disposed) return;
    if (failed > 0) {
      deleteSelectedMessage = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
    }
  }

  /// 서버 평점 + TMDB 영화 정보를 합쳐 목록을 만듦. 도중에 새 요청이 시작되면 null
  Future<({List<RatingWithMovie> entries, int missingMovies})?> _fetchEntries(
    int version,
  ) async {
    final rawRatings = await _service.fetchMyRatings();
    if (_disposed || version != _requestVersion) return null;
    final entries = <RatingWithMovie>[];
    var missingMovies = 0;
    // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
    for (final rating in rawRatings) {
      if (_disposed || version != _requestVersion) return null;
      if (!_movieCache.containsKey(rating.movieId)) {
        try {
          _movieCache[rating.movieId] = await _movieService.findMovieById(
            rating.movieId,
          );
        } on DioException {
          // 일시적 네트워크 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
        }
      }
      final movie = _movieCache[rating.movieId];
      if (movie == null) missingMovies++;
      entries.add(RatingWithMovie(rating: rating, movie: movie));
    }
    if (_disposed || version != _requestVersion) return null;
    return (entries: entries, missingMovies: missingMovies);
  }

  void _applyEntries(List<RatingWithMovie> entries, int missingMovies) {
    ratings = entries;
    status = entries.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
    message = missingMovies > 0 ? '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.' : null;
    // 서버에서 사라진 평점은 선택에서도 뺌
    final ids = entries.map((entry) => entry.rating.ratingId).toSet();
    selectedRatingIds.retainWhere(ids.contains);
  }

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final result = await _fetchEntries(version);
      if (result == null) return;
      _applyEntries(result.entries, result.missingMovies);
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      // 응답 형식이 다르거나 isSuccess=false: 로딩에 멈추지 않도록 에러 화면으로
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// 수정·삭제 후 조용히 다시 조회 (로딩 화면 없음)
  /// GET이 실패해도 지금 목록은 그대로 두고 안내만 표시 (쓰기 성공/실패와 분리)
  Future<void> _refreshAfterWrite() async {
    final version = ++_requestVersion;
    try {
      final result = await _fetchEntries(version);
      if (result == null) return;
      _applyEntries(result.entries, result.missingMovies);
    } catch (_) {
      // 네트워크·응답 형식 오류 모두: 지금 목록은 그대로 두고 안내만
      if (_disposed || version != _requestVersion) return;
      message = '목록을 새로 불러오지 못했습니다. 아래로 당겨 다시 시도해 주세요.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// 평점 수정: 성공하면 목록을 다시 조회, 실패하면 예외를 그대로 던짐(Dialog가 문구 표시)
  /// score는 항상 보내고, comment가 null이면 기존 코멘트를 지운다는 뜻으로 함께 보냄
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      // 403·404: 화면 목록이 서버와 어긋났으므로 다시 불러옴
      if (!_disposed && shouldRefreshAfterRatingError(error)) {
        _refreshAfterWrite();
      }
      rethrow;
    }
    if (_disposed) return;
    await _refreshAfterWrite();
  }

  /// 평점 삭제: 성공하면 목록을 다시 조회(마지막 항목이면 Empty UI), 실패하면 예외를 그대로 던짐
  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(ratingId);
    } on DioException catch (error) {
      if (!_disposed && shouldRefreshAfterRatingError(error)) {
        _refreshAfterWrite();
      }
      rethrow;
    }
    if (_disposed) return;
    await _refreshAfterWrite();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
