/// 로그인 요청: POST /v7/auth/login
class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password; // 요청 본문에만 사용. 로그·저장소에 남기지 않음

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

/// 로그인 응답 result: { nickname, accessToken }
/// memberId는 응답에 없으며 JWT payload에서 꺼내 쓰지도 않습니다.
class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});
  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}
