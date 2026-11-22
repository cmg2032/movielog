import '../../models/common_response.dart';

/// 내 정보: GET /v7/members/me → result { email, nickname, createdAt }
/// MemberApiService.fetchMe()가 반환하고 AuthViewModel.member가 보관합니다.
class MemberInfo {
  const MemberInfo({
    required this.email,
    required this.nickname,
    required this.createdAt,
  });

  final String email;
  final String nickname;
  final DateTime createdAt;

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// W7 CommonResponse에서 내 정보 result를 꺼냄
MemberInfo parseMemberInfo(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('내 정보 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<MemberInfo>.fromJson(
    data,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  );
  final member = common.result;
  if (member == null) throw StateError('내 정보 result가 없습니다.');
  return member;
}
