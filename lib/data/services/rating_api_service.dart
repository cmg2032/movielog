import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../../models/common_response.dart';
import '../../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 등록·수정 응답의 result(Rating 객체)를 RatingDto로 읽음
RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

/// 평점 목록: 직접 배열 [ ... ]
/// (로컬 서버처럼 공통 응답 { isSuccess, result: [ ... ] }으로 감싸 오면 result 배열을 꺼냄)
List<RatingDto> parseRatingList(Object? data) {
  final list = data is Map<String, dynamic> ? data['result'] : data;
  if (list is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return list
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// MovieLog 평점 API (v7)
/// - 공개 Client: 유저별 평점 조회 / 보호 Client(AuthInterceptor): 내 평점, 등록·수정·삭제
/// - 사용자 식별은 Authorization 헤더의 토큰으로 합니다.
/// - 등록·수정·삭제에는 memberId를 보내지 않습니다 (토큰으로 식별).
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio; // 토큰 없음
  final Dio _authDio; // AuthInterceptor 등록

  /// 유저별 평점 목록 (공개): GET /v7/members/{memberId}/ratings
  /// 로그인 없이 호출 가능. 의도가 드러나도록 공개 Client(토큰 없음)로 보냅니다.
  Future<List<RatingDto>> fetchMemberRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  /// 내가 남긴 평점 목록 (보호): GET /v7/members/me/ratings
  /// v7 로그인·내 정보 응답에 memberId가 없어서, 공개 조회 대신 토큰으로 '나'를 식별하는 경로를 씁니다.
  /// (로컬 서버에 추가한 경로 / AuthInterceptor 보호 경로 /v7/members/me/... 에 포함)
  Future<List<RatingDto>> fetchMyRatings() async {
    final response = await _authDio.get('/v7/members/me/ratings');
    return parseRatingList(response.data);
  }

  /// 평점 등록 (보호): POST /v7/ratings → result = Rating 객체
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// 평점 수정 (보호): PATCH /v7/ratings/{ratingId} → result = Rating 객체
  /// PATCH는 부분 수정이 아니라 전체 교체입니다. comment를 생략하면 null로 전달되어
  /// 기존 후기가 지워지므로, Dialog에 기존 score·comment를 채워 항상 두 값을 함께 보냅니다.
  /// 없는 ratingId면 RATING404_1
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  /// 평점 삭제 (보호): DELETE /v7/ratings/{ratingId} → 204가 아니라 result가 null인 200
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) throw StateError('예상하지 못한 삭제 응답');
  }
}

/// 내 평점 조회 실패 시 화면에 보여줄 문구
String writeMyRatingsErrorMessage(DioException error) {
  final noResponse = noResponseMessage(error);
  if (noResponse != null) return noResponse;
  if (apiErrorCode(error) == 'MEMBER404_1') return '회원 정보를 찾을 수 없습니다.';
  // AUTH401_2/3/4는 서버 문구 그대로 (세션 정리는 보호 Client가 한 번만, 로그인 이동은 redirect가 처리)
  return apiErrorMessage(error) ?? '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 요청 실패 시 화면에 보여줄 문구 (서버 message 우선)
/// - RATING403_1: 본인 평점이 아님 → 안내만 (로그아웃하지 않음)
/// - RATING404_1·MEMBER404_1: 없는 평점·회원 → 안내 + 목록 새로고침 (shouldRefreshAfterRatingError)
/// - RATING409_1: 이미 평점을 남긴 영화 → 기존 기록 확인 안내
/// - COMMON400: 별점 범위 등 입력 검증 실패 → 서버 message를 입력 필드 아래에 표시
String writeErrorMessage(DioException error) {
  final noResponse = noResponseMessage(error);
  if (noResponse != null) return noResponse;
  return apiErrorMessage(error) ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 같은 영화에 이미 평점이 있음
bool isAlreadyRated(DioException error) => apiErrorCode(error) == 'RATING409_1';

/// 평점 수정·삭제 실패 후 목록을 다시 불러와야 하는지
/// 없는 평점·회원(404)은 화면 목록이 서버와 어긋났다는 뜻이므로 다시 조회합니다.
/// 남의 평점(RATING403_1)은 안내만 하고 목록·세션은 그대로 둡니다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'RATING404_1' || code == 'MEMBER404_1';
}
