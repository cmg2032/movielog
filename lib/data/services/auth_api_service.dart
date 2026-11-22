import 'package:dio/dio.dart';

import '../../models/common_response.dart';
import '../models/login_models.dart';

/// MovieLog 로그인 API: 공개 Client(Interceptor 없음)와 W7 CommonResponse를 사용합니다.
class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;

  /// 로그인: POST /v7/auth/login → result { nickname, accessToken }
  /// 실패 시 DioException (401 AUTH401_1 등) → 뷰모델에서 처리
  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post('/v7/auth/login', data: request.toJson());
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('로그인 응답 형식이 올바르지 않습니다.');
    }
    final common = CommonResponse<LoginResult>.fromJson(
      data,
      (value) => LoginResult.fromJson(value as Map<String, dynamic>),
    );
    final result = common.result;
    if (result == null) throw StateError('로그인 result가 없습니다.');
    return result;
  }
}
