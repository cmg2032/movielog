import 'package:dio/dio.dart';

import '../../models/rating_dto.dart';

/// 회원별 평점 API
class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  /// 내가 남긴 평점 목록
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// 내 평점 조회 실패 시 화면에 보여줄 문구
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
