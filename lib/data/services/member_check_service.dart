import 'package:dio/dio.dart';

import '../../models/check_result.dart';
import '../../models/common_response.dart';
import '../../models/create_member_request.dart';
import '../../models/sign_up_models.dart';

/// 회원 공개 API (공개 Client): 닉네임/이메일 중복 확인, 회원가입
class MemberCheckService {
  MemberCheckService(this._dio);
  final Dio _dio;

  /// 닉네임 사용 가능 여부 (true = 사용 가능)
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v7/members/nickname/$encoded');
    return CheckResult.fromJson(_unwrap(response.data)).available;
  }

  /// 이메일 사용 가능 여부 (true = 사용 가능)
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v7/members/email/$encoded');
    return CheckResult.fromJson(_unwrap(response.data)).available;
  }

  /// 회원가입: POST /v7/members
  /// 실패 시 DioException (409 중복, 400 검증 실패) → 뷰모델에서 처리
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v7/members', data: request.toJson());

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }

  /// 서버 공통 응답 { isSuccess, code, message, result } 에서 result를 꺼냄
  /// (인터셉터가 이미 꺼내 줬다면 그대로 사용)
  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic> &&
        data.containsKey('isSuccess') &&
        data['result'] is Map<String, dynamic>) {
      return data['result'] as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }
}

/// 회원가입 실패 시 화면에 보여줄 문구 (서버 공통 응답의 message 사용)
String writeSignUpErrorMessage(DioException error) {
  final data = error.response?.data;
  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;
  return common?.message ?? '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}
