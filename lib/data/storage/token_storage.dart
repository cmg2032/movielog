import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// MovieLog accessToken 저장 규칙 (인증 흐름이 구체 저장소에 직접 의존하지 않게 분리)
/// - 토큰만 저장합니다. 비밀번호는 어디에도 저장하지 않습니다.
/// - TMDB 토큰은 .env에서 읽으므로 여기와 관계없습니다.
abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

/// 기기 보안 저장소(Android Keystore / iOS Keychain)에 저장
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);
  static const _accessTokenKey = 'movielog.access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}

/// 메모리 저장소 (테스트용)
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this._token]);
  String? _token;

  @override
  Future<void> saveAccessToken(String token) async => _token = token;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<void> deleteAccessToken() async => _token = null;
}
