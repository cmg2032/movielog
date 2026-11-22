import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/data/models/rating_request.dart';
import 'package:flutter_application_1/data/services/rating_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> ok(Object? result) => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': 'ok',
  'result': result,
};

const ratingJson = {
  'ratingId': 10,
  'movieId': 550,
  'score': 4,
  'comment': '좋아요',
  'createdAt': '2026-10-30T12:00:00Z',
};

/// 보낸 요청을 기록하고 정해 둔 응답을 돌려주는 어댑터
class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.body);
  final Object? body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(RatingApiService, RecordingAdapter, RecordingAdapter) service(Object? body) {
  final publicAdapter = RecordingAdapter(body);
  final authAdapter = RecordingAdapter(body);
  final publicDio = Dio()..httpClientAdapter = publicAdapter;
  final authDio = Dio()..httpClientAdapter = authAdapter;
  return (RatingApiService(publicDio, authDio), publicAdapter, authAdapter);
}

void main() {
  group('Client 선택', () {
    test('유저별 평점 조회는 공개 Client', () async {
      final (api, public, auth) = service([ratingJson]);
      final list = await api.fetchMemberRatings(7);
      expect(list.single.ratingId, 10);
      expect(public.requests.single.path, '/v7/members/7/ratings');
      expect(auth.requests, isEmpty);
    });

    test('등록·수정·삭제는 보호 Client', () async {
      final (api, public, auth) = service({
        'isSuccess': true,
        'code': 'COMMON200',
        'message': 'ok',
        'result': ratingJson,
      });
      await api.createRating(const CreateRatingRequest(movieId: 550, score: 4));
      await api.updateRating(ratingId: 10, score: 5, comment: null);
      await api.deleteRating(10);
      expect(public.requests, isEmpty);
      expect(auth.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /v7/ratings',
        'PATCH /v7/ratings/10',
        'DELETE /v7/ratings/10',
      ]);
    });

    test('수정은 comment가 null이어도 score와 함께 보냄 (전체 교체)', () async {
      final (api, _, auth) = service(ok(ratingJson));
      await api.updateRating(ratingId: 10, score: 5);
      expect(auth.requests.single.data, {'score': 5, 'comment': null});
    });
  });

  group('파싱', () {
    test('parseRatingResult: result 객체를 읽고, 없으면 오류', () {
      expect(parseRatingResult(ok(ratingJson)).movieId, 550);
      expect(() => parseRatingResult(ok(null)), throwsStateError);
      expect(() => parseRatingResult('x'), throwsStateError);
    });

    test('parseRatingList: 직접 배열과 공통 응답 둘 다 읽음', () {
      expect(parseRatingList([ratingJson]).length, 1);
      expect(
        parseRatingList({
          'isSuccess': true,
          'result': [ratingJson],
        }).length,
        1,
      );
      expect(() => parseRatingList({'result': null}), throwsStateError);
    });
  });
}
