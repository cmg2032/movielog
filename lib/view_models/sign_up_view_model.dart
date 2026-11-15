import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/services/sign_up_service.dart';
import '../models/create_member_request.dart';
import 'submit_status.dart';

export 'submit_status.dart';

/// 중복 확인 상태
enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final SignUpService _service;

  static final _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  static const _networkErrorText = '네트워크 오류로 확인하지 못했어요. 다시 시도해 주세요.';
  static const _serverErrorText = '서버 오류로 확인하지 못했어요. 다시 시도해 주세요.';
  static const _unknownErrorText = '응답을 처리하지 못했어요. 다시 시도해 주세요.';

  bool _disposed = false;

  /// DioException을 화면 문구로 바꿈
  /// - 서버가 응답을 줬으면(400, 409 등) 서버의 message를 그대로 사용
  /// - 응답 자체가 없으면(연결 실패, 타임아웃) 네트워크 오류 문구
  static String _messageFrom(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final statusCode = e.response?.statusCode;
    if (e.response == null) return _networkErrorText; // 응답 자체가 없음
    if (statusCode == 404) {
      // 연결은 됐지만 서버에 해당 주소가 없음 (API 버전·주소 확인 필요)
      return '서버에서 확인 기능을 찾지 못했어요 (404). 서버 주소를 확인해 주세요.';
    }
    return '$fallback (${statusCode ?? '-'})';
  }

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

  /// 2~12자(서버 규칙과 동일)일 때만, 확인 중·사용 가능·중복 상태가 아닐 때 누를 수 있음
  bool get canCheckNickname =>
      _nickname.length >= 2 &&
      _nickname.length <= 12 &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.available &&
      nicknameCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    _nickname = value.trim();
    _clearSubmitError();

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
    if (nickname.length < 2 || nickname.length > 12) return;

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
    } on DioException catch (e) {
      // 통신 실패: 중복 응답과 다른 문구, 다시 시도 가능
      if (_disposed || version != _nicknameVersion) return;
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = _messageFrom(e, _serverErrorText);
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
    _clearSubmitError();

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
    } on DioException catch (e) {
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = _messageFrom(e, _serverErrorText);
    } catch (_) {
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = _unknownErrorText;
    }

    if (!_disposed && version == _emailVersion) notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 가입하기
  // ─────────────────────────────────────────────
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId; // 가입 성공 응답에서 읽은 실제 ID입니다.
  String? passwordErrorText;
  String? snackbarMessage;

  /// 닉네임·이메일 중복 확인을 모두 통과했고, 가입 요청 중이 아닐 때만 가능
  /// (비밀번호 형식은 화면의 Form validator에서 확인)
  bool get canSubmit =>
      isNicknameAvailable &&
      isEmailAvailable &&
      submitStatus != SubmitStatus.submitting;

  /// 닉네임·이메일을 고치면 이전 가입 실패(서버 오류) 결과도 무효화
  void _clearSubmitError() {
    if (submitStatus == SubmitStatus.error) submitStatus = SubmitStatus.idle;
    snackbarMessage = null;
  }

  void onPasswordChanged() {
    passwordErrorText = null;
    notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (submitStatus == SubmitStatus.submitting) return;
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      final id = response.result?.memberId;
      if (id == null) throw StateError('회원가입 결과에 memberId가 없습니다.');
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);
      if (error.response?.statusCode == 400 && message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on StateError {
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners(); // 요청 중 화면을 나갔으면 알리지 않음
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameVersion++;
    _emailVersion++;
    super.dispose();
  }
}
