import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/network/api_error.dart';
import 'package:flutter_application_1/core/network/auth_interceptor.dart';
import 'package:flutter_application_1/data/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// 실제로 보내지 않고 요청 헤더만 기록하는 어댑터
class RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'isSuccess': true, 'code': 'COMMON200', 'result': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class ThrowingReadStorage extends MemoryTokenStorage {
  @override
  Future<String?> readAccessToken() async => throw StateError('read failed');
}

(Dio, RecordingAdapter) authClient(TokenStorage storage) {
  final adapter = RecordingAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'))
    ..httpClientAdapter = adapter
    ..interceptors.add(AuthInterceptor(storage));
  return (dio, adapter);
}

void main() {
  test('보호 경로에만 Bearer 토큰을 붙임', () async {
    final (dio, adapter) = authClient(MemoryTokenStorage('jwt'));

    await dio.get('/v7/members/me');
    await dio.get('/v7/members/me/ratings');
    await dio.post('/v7/ratings');
    await dio.delete('/v7/ratings/3');
    await dio.get('/v7/members/nickname/teemo'); // 공개: 중복 체크
    await dio.post('/v7/auth/login'); // 공개: 로그인

    final auth = adapter.requests.map((r) => r.headers['Authorization']);
    expect(auth.take(4), everyElement('Bearer jwt'));
    expect(auth.skip(4), everyElement(isNull));
  });

  test('다른 호스트로 가는 요청에는 토큰을 붙이지 않음', () async {
    final (dio, adapter) = authClient(MemoryTokenStorage('jwt'));
    await dio.get('https://api.themoviedb.org/v7/ratings');
    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('토큰이 없으면 헤더 없이 보내고, 이전 요청의 토큰을 재사용하지 않음', () async {
    final (dio, adapter) = authClient(MemoryTokenStorage());
    await dio.get(
      '/v7/members/me',
      options: Options(headers: {'Authorization': 'Bearer old'}),
    );
    expect(adapter.requests.single.headers['Authorization'], isNull);
  });

  test('저장소 읽기 실패는 요청을 보내지 않고 저장소 오류로 거절', () async {
    final (dio, adapter) = authClient(ThrowingReadStorage());
    try {
      await dio.get('/v7/members/me');
      fail('요청이 거절되어야 합니다');
    } on DioException catch (e) {
      expect(isTokenStorageError(e), isTrue);
      expect(noResponseMessage(e), contains('로그인 정보를 읽지 못했어요'));
    }
    expect(adapter.requests, isEmpty);
  });
}
