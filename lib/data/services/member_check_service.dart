import 'package:dio/dio.dart';

/// 회원 닉네임/이메일 중복 확인 API
class MemberCheckService {
  MemberCheckService(this._dio);
  final Dio _dio;

  /// 닉네임 사용 가능 여부 (true = 사용 가능)
  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  /// 이메일 사용 가능 여부 (true = 사용 가능)
  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }
}

/// 중복 확인 응답 DTO
/// 예: { "available": true }
class CheckResult {
  const CheckResult({required this.available});

  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    // 값이 없거나 이상하면 "사용 불가"로 처리 (확실하지 않으면 가입을 막는 쪽이 안전)
    return CheckResult(available: json['available'] as bool? ?? false);
  }
}
