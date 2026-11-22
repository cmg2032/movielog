import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

/// 프로필(닉네임) 수정 화면 ViewModel
/// - 입력칸 문제(길이, 중복)는 [nicknameError]로 필드 아래에 표시
/// - 입력과 무관한 문제(네트워크 등)는 [message]로 SnackBar에 표시 (로그아웃하지 않음)
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError; // 입력 필드 아래에 보여줄 오류
  String? message; // Snackbar로 보여줄 오류(네트워크 등)
  bool _disposed = false;

  /// 서버에 보내기 전에 확인할 수 있는 규칙은 클라이언트에서 먼저 검사합니다.
  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  /// 저장 성공이면 true (AuthViewModel.member가 이미 새 값으로 교체된 상태)
  Future<bool> save(String input) async {
    if (status == EditProfileStatus.saving) return false; // 중복 탭 방지

    final version = _auth.sessionVersion;
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        _auth.member == null) {
      return false;
    }
    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    if (nicknameError != null) {
      _notify();
      return false;
    }

    // 현재 닉네임과 같으면 요청 없이 완료로 처리합니다.
    if (nickname == _auth.member?.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    nicknameError = null;
    message = null;
    _notify();

    try {
      final updated = await _memberApi.updateNickname(nickname);
      if (!_isCurrent(version)) return false;
      _auth.updateMember(updated); // 마이페이지가 바로 새 닉네임을 보여줍니다.
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return false;
      final code = apiErrorCode(error);
      status = EditProfileStatus.failure;
      switch (code) {
        case 'AUTH401_2' || 'AUTH401_3' || 'AUTH401_4':
          // 세션 만료: 안내와 이동은 앱 루트 SnackBar와 Router가 처리합니다.
          await _auth.expireSession();
        case 'MEMBER409_1':
          nicknameError = '이미 사용 중인 닉네임이에요.'; // 입력값은 유지
        case 'COMMON400':
          nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
        case 'MEMBER404_1':
          message = '회원 정보를 찾을 수 없어요.';
        default:
          // 저장소 읽기 실패는 따로 안내, 나머지는 네트워크 안내 (로그아웃하지 않음)
          message = isTokenStorageError(error)
              ? noResponseMessage(error)
              : '네트워크 상태를 확인하고 다시 시도해 주세요.';
      }
    } catch (_) {
      if (_disposed || version != _auth.sessionVersion) return false;
      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }
    _notify();
    return false;
  }

  /// 화면이 닫혔거나, 그사이 로그아웃·만료로 세션이 바뀌었으면 늦게 온 응답을 무시
  bool _isCurrent(int version) =>
      !_disposed &&
      version == _auth.sessionVersion &&
      _auth.status == AuthStatus.signedIn;

  /// 화면이 사라진 뒤 도착한 응답이 notifyListeners()를 호출하지 않게 막습니다.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
