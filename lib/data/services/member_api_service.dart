import 'package:dio/dio.dart';

import '../models/member_info.dart';

/// 내 정보 API (보호 Client: AuthInterceptor가 토큰으로 '나'를 식별)
class MemberApiService {
  MemberApiService(this._authDio);
  final Dio _authDio;

  /// GET /v7/members/me → 앱 재시작 때 토큰 검증, 로그인 후 MainScreen에서 내 정보 조회
  /// 토큰이 없거나 무효·만료면 DioException (AUTH401_2/3/4)
  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  /// PATCH /v7/members/me { nickname } → 수정된 내 정보
  /// 실패: MEMBER409_1(다른 회원이 사용 중), COMMON400(2~12자 위반), MEMBER404_1, AUTH401_2/3/4
  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
