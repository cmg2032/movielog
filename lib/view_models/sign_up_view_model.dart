import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

/// 중복 확인 상태
enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;

  static final _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  static const _networkErrorText = '네트워크 오류로 확인하지 못했어요. 다시 시도해 주세요.';
  static const _unknownErrorText = '응답을 처리하지 못했어요. 다시 시도해 주세요.';

  bool _disposed = false;

  // ─────────────────────────────────────────────
  // 닉네임
  // ─────────────────────────────────────────────
  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String _nickname = '';
  String? _checkedNickname; // 마지막으로 '사용 가능'이었던 값
  String? _duplicatedNickname; // 마지막으로 '중복'이었던 값
  int _nicknameVersion = 0;

  bool get isNicknameAvailable => nicknameCheckStatus == CheckStatus.available;

  /// 확인 중·사용 가능·중복 상태에서는 누를 수 없음
  bool get canCheckNickname =>
      _nickname.length >= 2 &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.available &&
      nicknameCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    _nickname = value.trim();

    if (_nickname.isNotEmpty && _nickname == _duplicatedNickname) {
      // 방금 중복이었던 값으로 되돌아옴 → 서버에 묻지 않고 바로 중복 상태
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else if (_nickname != _checkedNickname) {
      // 다른 값으로 수정 중 → 원래 상태(에러 아님), 버튼 다시 활성
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }
    notifyListeners();
  }

  Future<void> checkNickname(String raw) async {
    final nickname = raw.trim();
    if (nickname.length < 2) return;

    final version = ++_nicknameVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkNickname(nickname);
      if (_disposed || version != _nicknameVersion) return;

      if (nickname != _nickname) {
        nicknameCheckStatus = CheckStatus.idle; // 확인 중에 고쳤으면 버림
      } else if (available) {
        _checkedNickname = nickname;
        nicknameCheckStatus = CheckStatus.available;
        nicknameErrorText = null;
      } else {
        _duplicatedNickname = nickname; // 중복 값 기억
        nicknameCheckStatus = CheckStatus.duplicated;
        nicknameErrorText = '이미 사용 중인 닉네임입니다.';
      }
    } on DioException {
      // 통신 실패: 중복 응답과 다른 문구, 다시 시도 가능
      if (_disposed || version != _nicknameVersion) return;
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = _networkErrorText;
    } catch (_) {
      if (_disposed || version != _nicknameVersion) return;
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = _unknownErrorText;
    }

    if (!_disposed && version == _nicknameVersion) notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 이메일
  // ─────────────────────────────────────────────
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String _email = '';
  String? _checkedEmail; // 마지막으로 '사용 가능'이었던 값
  String? _duplicatedEmail; // 마지막으로 '중복'이었던 값
  int _emailVersion = 0;

  bool get isEmailAvailable => emailCheckStatus == CheckStatus.available;

  bool get canCheckEmail =>
      _emailRegExp.hasMatch(_email) &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.available &&
      emailCheckStatus != CheckStatus.duplicated;

  void onEmailChanged(String value) {
    _email = value.trim();

    if (_email.isNotEmpty && _email == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else if (_email != _checkedEmail) {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }
    notifyListeners();
  }

  Future<void> checkEmail(String raw) async {
    final email = raw.trim();
    if (!_emailRegExp.hasMatch(email)) return;

    final version = ++_emailVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(email);
      if (_disposed || version != _emailVersion) return;

      if (email != _email) {
        emailCheckStatus = CheckStatus.idle;
      } else if (available) {
        _checkedEmail = email;
        emailCheckStatus = CheckStatus.available;
        emailErrorText = null;
      } else {
        _duplicatedEmail = email;
        emailCheckStatus = CheckStatus.duplicated;
        emailErrorText = '이미 사용 중인 이메일입니다.';
      }
    } on DioException {
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = _networkErrorText;
    } catch (_) {
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = _unknownErrorText;
    }

    if (!_disposed && version == _emailVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameVersion++;
    _emailVersion++;
    super.dispose();
  }
}
