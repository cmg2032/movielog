import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/storage/token_storage.dart';
import '../../view_models/auth_view_model.dart';
import 'api_error.dart';
import 'auth_interceptor.dart';

/// MovieLog 서버 Client (TMDB Client와 분리, 서로 합치지 않음)
/// - baseUrl은 .env의 MOVIELOG_BASE_URL (/v7는 넣지 않기: 서비스 코드가 /v7/... 로 붙임)
/// - 요청·토큰을 로그로 남기지 않습니다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: dotenv.env['MOVIELOG_BASE_URL'] ?? 'http://10.0.2.2:3000',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'accept': 'application/json'},
  );
}

// 공개 요청용: 로그인, 중복 체크, 회원가입 / Interceptor 없음
Dio createMovieLogClient() {
  return Dio(_movieLogOptions());
}

const _sessionVersionKey = 'sessionVersion';

// 보호 요청용: 내 정보, 내 평점, 평점 등록/수정/삭제 / Interceptor 등록
//
// [readSession]: 401 처리용. 요청을 보낸 시점의 sessionVersion을 기억해 두고,
// AUTH401_2/3/4(토큰 없음·무효·만료)면 그 요청을 보낸 세션이 아직 현재 세션일 때만 정리합니다.
// (AuthViewModel이 이 Client를 쓰는 MemberApiService를 필요로 해서 요청 시점에 늦게 읽습니다)
Dio createAuthMovieLogClient(
  TokenStorage storage, {
  AuthViewModel Function()? readSession,
}) {
  final dio = Dio(_movieLogOptions());
  if (readSession != null) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra[_sessionVersionKey] = readSession().sessionVersion;
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401 && isSessionAuthError(error)) {
            final requestVersion =
                error.requestOptions.extra[_sessionVersionKey];
            if (requestVersion is int) {
              // 동시 401이 여러 개여도 첫 번째만 세션을 정리하고, 나머지는 무시됨
              readSession().expire(requestVersion);
            }
          }
          handler.next(error);
        },
      ),
    );
  }
  dio.interceptors.add(AuthInterceptor(storage));
  return dio;
}
