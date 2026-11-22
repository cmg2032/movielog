import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 화면 "이메일 저장" (Challenge)
/// - 이메일만 저장합니다. 비밀번호와 토큰은 저장하지 않습니다 (토큰은 TokenStorage의 보안 저장소).
/// - shared_preferences는 암호화되지 않으므로 비민감한 값에만 사용합니다.
abstract interface class SavedEmailStorage {
  Future<String?> readEmail();
  Future<void> saveEmail(String email);
  Future<void> clearEmail();
}

class PrefsSavedEmailStorage implements SavedEmailStorage {
  PrefsSavedEmailStorage([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();
  static const _emailKey = 'movielog.saved_email';
  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> readEmail() => _prefs.getString(_emailKey);

  @override
  Future<void> saveEmail(String email) => _prefs.setString(_emailKey, email);

  @override
  Future<void> clearEmail() => _prefs.remove(_emailKey);
}

/// 메모리 저장소 (테스트용)
class MemorySavedEmailStorage implements SavedEmailStorage {
  MemorySavedEmailStorage([this._email]);
  String? _email;

  @override
  Future<String?> readEmail() async => _email;

  @override
  Future<void> saveEmail(String email) async => _email = email;

  @override
  Future<void> clearEmail() async => _email = null;
}
