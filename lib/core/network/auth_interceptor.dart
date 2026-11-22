import 'package:dio/dio.dart';

import '../../data/storage/token_storage.dart';

/// 기기 보안 저장소에서 토큰을 읽지 못함 (서버 401과 다른 오류)
class TokenStorageReadException implements Exception {
  const TokenStorageReadException();
  @override
  String toString() => '인증 저장소를 읽지 못했습니다.';
}

/// 보호 요청에만 Authorization: Bearer {MovieLog JWT}를 붙이는 Interceptor
/// - 보호용 MovieLog Client에만 등록합니다. 공개용 Client·TMDB Client에는 등록하지 않습니다.
/// - 토큰은 매 요청마다 TokenStorage에서 읽습니다. 로그로 남기지 않습니다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final TokenStorage _storage;

  /// MovieLog 서버(baseUrl과 같은 호스트)의 보호 경로인지
  /// - 내 정보: /v7/members/me, 내 평점 목록: /v7/members/me/ratings
  /// - 평점 등록/수정/삭제: /v7/ratings, /v7/ratings/{id}
  bool _isProtected(RequestOptions options) {
    final path = options.uri.path;
    return options.uri.host == Uri.parse(options.baseUrl).host &&
        (path == '/v7/members/me' ||
            path.startsWith('/v7/members/me/') ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isProtected(options)) {
      handler.next(options);
      return;
    }
    options.headers.remove('Authorization'); // 이전 요청의 토큰을 재사용하지 않습니다.
    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류입니다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: const TokenStorageReadException(),
        ),
      );
    }
  }
}
