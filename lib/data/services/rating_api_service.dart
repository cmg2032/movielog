import 'package:dio/dio.dart';

import '../../models/common_response.dart';
import '../../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 회원별 평점 API
class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  /// 내가 남긴 평점 목록: GET /v6/members/{memberId}/ratings
  /// 응답이 직접 배열 [ ... ] 이어도, 공통 응답 { isSuccess, result: [ ... ] } 이어도 처리
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v6/members/$memberId/ratings');
    final data = response.data;

    final List<dynamic> list;
    if (data is List) {
      list = data; // 직접 배열
    } else if (data is Map<String, dynamic>) {
      final common = CommonResponse<List<dynamic>>.fromJson(
        data,
        (value) => value as List<dynamic>,
      );
      if (!common.isSuccess) throw StateError(common.message);
      list = common.result ?? const []; // wrapper (result가 null이면 빈 목록)
    } else {
      throw StateError('예상하지 못한 평점 목록 응답입니다.');
    }

    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 평점 등록: POST /v6/members/{memberId}/ratings
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // 201을 성공으로 처리합니다. result의 숫자/null 계약은 확인 전 파싱하지 않습니다.
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  /// 평점 수정: PATCH /v6/members/{memberId}/ratings/{ratingId}
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
  }

  /// 평점 삭제: DELETE /v6/members/{memberId}/ratings/{ratingId}
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 내 평점 조회 실패 시 화면에 보여줄 문구
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 요청 실패 시 화면에 보여줄 문구 (서버 공통 응답의 message 사용)
String writeErrorMessage(DioException error) {
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 수정·삭제 실패 후 목록을 다시 불러와야 하는지
bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map<String, dynamic> ? data['code'] as String? : null;
  // 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춥니다.
  return code == 'COMMON403' || code == 'COMMON404';
}
