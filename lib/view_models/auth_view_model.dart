import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';

/// 세션 상태
/// - initializing: 앱 시작 후 저장된 토큰 확인 중 (Splash 인디케이터)
/// - retryRequired: 확인 실패 (Splash [다시 시도])
/// - signedOut / signedIn
/// - authenticating: 로그인 요청 중 (공개 화면만 허용)
enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

/// MovieLog 로그인 세션 ViewModel
///
/// - MovieLog JWT는 TokenStorage에만 둡니다. 요청 헤더는 AuthInterceptor가 저장소에서 읽어 붙입니다.
/// - 토큰은 로그에 찍지 않습니다. 비밀번호는 보관하지 않습니다.
/// - sessionVersion: 세션이 바뀔 때마다(복원·로그인·로그아웃·만료) 1씩 증가.
///   요청을 보낼 때의 버전과 비교해서, 이전 세션에서 늦게 도착한 응답·401이
///   새 세션을 덮거나 지우지 않게 합니다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);
  final AuthApiService _authApi; // 공개 Client
  final MemberApiService _memberApi; // 보호 Client (AuthInterceptor)
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member; // GET /members/me 결과 (마이페이지·평점 화면 등이 재사용)
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message; // Splash 재시도·로그인 실패·저장소 정리 실패 안내
  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  /// 토큰 만료·무효로 정리됐을 때만 true (직접 로그아웃·AUTH401_1은 false)
  /// signedOut만으로는 '만료로 쫓겨난 경우'를 구분할 수 없어서 따로 둡니다.
  bool sessionExpired = false;

  /// 저장소에서 토큰을 지우는 중이면 복원·로그인을 시작하지 않음 (지운 토큰과 섞이지 않도록)
  bool storageCleanupInProgress = false;

  bool _disposed = false;
  Future<void>? _tokenWrite; // 진행 중인 토큰 저장 (정리할 때 끝나길 기다린 뒤 삭제)
  String? _loginNickname; // 로그인 응답의 닉네임 (내 정보 조회 전 표시용)

  bool get isLoggedIn => status == AuthStatus.signedIn;
  String? get nickname => member?.nickname ?? _loginNickname;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// 앱 시작 시 저장된 토큰으로 세션 복원 (Splash에서 실행, [다시 시도]도 이 메서드)
  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;
    final version = ++_sessionVersion;
    status = AuthStatus.initializing;
    message = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();
    try {
      final token = await _storage.readAccessToken();
      if (!_isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        // 요청 헤더는 AuthInterceptor가 저장소에서 같은 토큰을 읽어 붙임
        final verifiedMember = await _memberApi.fetchMe();
        if (!_isCurrent(version)) return;
        member = verifiedMember;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionAuthError(error)) {
        await _clearCurrentSession(expired: true);
        return;
      }
      status = AuthStatus.retryRequired;
      message = isTokenStorageError(error)
          ? '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.'
          : '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) _notify();
  }

  /// 내 정보 불러오기: MainScreen이 처음 열릴 때 한 번 호출
  /// - 앱 재시작은 restoreSession()이 이미 member를 채웠으므로 다시 부르지 않음
  /// - AUTH401_2/3/4: 세션 정리 → signedOut → Router가 /login으로 이동
  /// - 네트워크 실패: 로그아웃하지 않고 error로 남겨 [force]로 재시도
  Future<void> loadMember({bool force = false}) async {
    if (status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return; // 이미 들고 있으면 다시 호출하지 않음

    final version = _sessionVersion;
    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();
      if (!_isCurrent(version)) return; // 로그아웃·계정 전환 뒤 늦게 온 응답 무시
      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      if (isSessionAuthError(error)) {
        await _clearCurrentSession(); // 세션 만료: signedOut이 되어 Router가 /login으로 이동
        return;
      }
      memberStatus = MemberLoadStatus.error; // 재시도 가능
      message = '내 정보를 불러오지 못했어요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      memberStatus = MemberLoadStatus.error; // 응답 형식 오류
      message = '내 정보를 불러오지 못했어요.';
    }
    _notify();
  }

  /// 프로필 수정 성공 응답으로 메모리의 내 정보를 교체합니다. GET me를 다시 호출하지 않습니다.
  /// (마이페이지가 member를 구독하고 있어 화면 이동 없이 새 닉네임이 보임)
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  /// 다른 ViewModel이 401(AUTH401_2/3/4)을 받았을 때 세션 정리를 요청하는 공개 진입점
  Future<void> expireSession() => _clearCurrentSession(expired: true);

  /// 이메일·비밀번호 로그인: 요청 중 authenticating → 토큰 저장 → signedIn
  /// 실패하면 signedOut으로 돌리고 [message]에 안내 문구를 둡니다.
  /// AUTH401_1(입력 오류)은 세션 만료가 아니므로 만료 안내를 띄우지 않습니다.
  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;
    final version = ++_sessionVersion;
    _notify();
    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
      if (!_isCurrent(version)) return;
      await _saveToken(result.accessToken);
      if (!_isCurrent(version)) return;
      // 신규 로그인 최종 흐름: 토큰 저장 → signedIn → MainScreen.loadMember().
      // 앱 재시작은 restoreSession()의 GET me 검증 후에만 signedIn입니다.
      _loginNickname = result.nickname;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      // 입력 오류 / 서버 연결 실패 / 그 밖의 요청 실패를 서로 다른 문구로 안내
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : error.response == null
          ? '서버에 연결하지 못했어요. 네트워크를 확인해 주세요.'
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }
    _notify();
  }

  /// 회원가입 직후 자동 로그인: 로그인 응답의 토큰을 저장한 뒤 signedIn
  /// 저장에 실패하면 보호 요청이 모두 401이 되므로 로그인하지 않고 false를 반환합니다.
  Future<bool> signIn({
    required String accessToken,
    required String nickname,
  }) async {
    if (_disposed || storageCleanupInProgress) return false;
    final version = ++_sessionVersion;
    try {
      await _saveToken(accessToken);
    } catch (_) {
      return false; // 보안 저장소를 쓸 수 없음
    }
    if (!_isCurrent(version)) return false;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _loginNickname = nickname;
    sessionExpired = false;
    message = null;
    status = AuthStatus.signedIn;
    _notify();
    return true;
  }

  /// 토큰 저장 (진행 중인 저장을 [_tokenWrite]로 기억 → 정리할 때 끝나길 기다림)
  Future<void> _saveToken(String token) async {
    final writing = _storage.saveAccessToken(token);
    _tokenWrite = writing;
    try {
      await writing;
    } finally {
      if (identical(_tokenWrite, writing)) _tokenWrite = null;
    }
  }

  /// 사용자가 직접 로그아웃: MovieLog 세션만 비움 (만료 안내는 띄우지 않음)
  /// 메모리와 저장소를 함께 정리하지만 직접 로그아웃에서는 만료 Snackbar를 켜지 않습니다.
  /// 클라이언트 세션만 비우며, 서버에서 토큰이 즉시 폐기됐다고 보장하지 않습니다.
  Future<void> logout() => _clearCurrentSession(expired: false);

  /// 보호 요청이 AUTH401_2/3/4로 거절됨 → 세션 정리 + 만료 안내 예약
  ///
  /// [requestVersion]은 그 요청을 보낼 때의 sessionVersion입니다.
  /// - 이미 정리됐거나(동시 401 중 두 번째 이후) 그사이 세션이 바뀌었으면 무시 → false
  /// - 실제로 세션을 정리했으면 true (알림·이동은 한 번만)
  bool expire(int requestVersion) {
    if (_disposed ||
        status != AuthStatus.signedIn ||
        requestVersion != _sessionVersion) {
      return false;
    }
    unawaited(_clearCurrentSession(expired: true));
    return true;
  }

  /// 로그인 화면이 만료 안내 SnackBar를 한 번 보여준 뒤 끔 (같은 안내 반복 방지)
  void consumeSessionExpired() {
    sessionExpired = false;
  }

  /// 현재 세션을 메모리와 저장소에서 지움
  Future<void> _clearCurrentSession({bool expired = true}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_sessionVersion; // 진행 중이던 요청의 늦은 응답·401은 이후 무시됨
    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _loginNickname = null;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();
    try {
      // 진행 중이던 토큰 저장을 기다린 뒤 삭제합니다. 정리 중 새 로그인은 막습니다.
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장 실패여도 삭제는 시도
      }
      await _storage.deleteAccessToken();
    } catch (_) {
      // 삭제 실패: 빈 값으로 덮어써서 다음 실행 때 자동 로그인되지 않게 함
      // (복원과 AuthInterceptor는 빈 토큰을 '없음'으로 취급)
      try {
        await _storage.saveAccessToken('');
      } catch (_) {
        if (_isCurrent(version)) {
          message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
        }
      }
    } finally {
      storageCleanupInProgress = false;
      if (_isCurrent(version)) _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
