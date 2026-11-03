import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, {List<int>? initialGenreIds})
    : selectedGenreIds = (initialGenreIds == null || initialGenreIds.isEmpty)
          ? null
          : List<int>.of(initialGenreIds);

  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// 선택된 장르 id 목록. null = 전체
  List<int>? selectedGenreIds;

  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  /// Pull to Refresh 진행 중 (기존 목록은 화면에 그대로 둠)
  bool isRefreshing = false;

  bool _retryDialogPending = false;
  int _requestVersion = 0;
  bool _disposed = false;

  /// 목록을 비우고 새로 불러오는 중
  bool get isLoading => status == MovieListLoadStatus.loading;

  /// 어떤 요청이든 진행 중 (장르 변경 막기용)
  bool get isBusy => isLoading || isRefreshing;

  /// 화면이 Dialog를 띄워야 하면 true를 한 번만 돌려줌
  bool takeRetryDialogRequest() {
    final pending = _retryDialogPending;
    _retryDialogPending = false;
    return pending;
  }

  // ─────────────────────────────────────────────
  // Discover: page 1부터, id 기준 중복 제거, 최대 30개
  // ─────────────────────────────────────────────
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int>? genreIds,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == 30) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(30).toList();
  }

  // ─────────────────────────────────────────────
  // 화면 진입: 장르 목록 + 영화 목록
  // ─────────────────────────────────────────────
  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      if (genres.isEmpty) {
        genres = await _service.fetchGenres();
      }
      final result = await fetchUpToThirtyMovies(genreIds: selectedGenreIds);
      if (!_isCurrent(version)) return;
      _applyResult(result);
    } catch (e) {
      if (!_isCurrent(version)) return;
      _handleFailure(e);
    }

    if (_isCurrent(version)) notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 장르 다중 선택
  // ─────────────────────────────────────────────

  /// BottomSheet 확인 / 칩 선택 결과 적용. 빈 목록이나 null이면 전체
  Future<void> applyGenres(List<int>? ids) async {
    if (isBusy) return;

    final next = (ids == null || ids.isEmpty) ? null : List<int>.of(ids);
    if (_sameIds(next, selectedGenreIds) &&
        status == MovieListLoadStatus.success) {
      return; // 바뀐 게 없으면 재요청 안 함
    }

    selectedGenreIds = next;
    movies = const []; // 장르가 바뀌면 리스트 초기화
    await _loadMovies();
  }

  /// 칩 하나 탭: 있으면 빼고, 없으면 추가
  Future<void> toggleGenre(int id) {
    final next = [...?selectedGenreIds];
    if (!next.remove(id)) next.add(id);
    return applyGenres(next);
  }

  // ─────────────────────────────────────────────
  // Pull to Refresh: 현재 장르 유지, 기존 목록 유지, page 1부터
  // ─────────────────────────────────────────────
  Future<void> refresh() async {
    if (isBusy) return;
    if (movies.isEmpty) return _loadMovies(); // 유지할 목록이 없으면 일반 로딩

    final version = ++_requestVersion;
    isRefreshing = true;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreIds: selectedGenreIds);
      if (!_isCurrent(version)) return;
      _applyResult(result); // 완료되면 최신 목록으로 교체
    } catch (e) {
      if (!_isCurrent(version)) return;
      _handleFailure(e); // 실패해도 기존 목록 유지
    }

    if (_isCurrent(version)) {
      isRefreshing = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // 재시도: 마지막 장르로 page 1부터 30개 로딩 전체 다시
  // ─────────────────────────────────────────────
  Future<void> retry() {
    if (genres.isEmpty) return loadInitial();
    if (movies.isNotEmpty) return refresh(); // 목록 유지한 채 교체
    return _loadMovies();
  }

  // ─────────────────────────────────────────────
  // 내부
  // ─────────────────────────────────────────────
  Future<void> _loadMovies() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreIds: selectedGenreIds);
      if (!_isCurrent(version)) return;
      _applyResult(result);
    } catch (e) {
      if (!_isCurrent(version)) return;
      _handleFailure(e);
    }

    if (_isCurrent(version)) notifyListeners();
  }

  void _applyResult(List<TmdbMovieDto> result) {
    movies = result;
    message = null;
    status = result.isEmpty
        ? MovieListLoadStatus.empty
        : MovieListLoadStatus.success;
  }

  void _handleFailure(Object error) {
    message = error is DioException
        ? '영화 목록을 불러오지 못했어요.\n네트워크 상태를 확인해 주세요.'
        : '데이터를 처리하지 못했어요.';

    if (error is! DioException && kDebugMode) {
      debugPrint('MovieListViewModel 오류: $error');
    }

    // 최근에 성공한 목록이 있으면 비우지 않고 그대로 보여줌
    status = movies.isNotEmpty
        ? MovieListLoadStatus.success
        : MovieListLoadStatus.error;

    _retryDialogPending = true;
  }

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  bool _sameIds(List<int>? a, List<int>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.toSet().containsAll(b);
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
