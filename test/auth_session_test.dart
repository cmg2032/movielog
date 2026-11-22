import 'package:dio/dio.dart';

import 'dart:async';

import 'package:flutter_application_1/data/models/login_models.dart';
import 'package:flutter_application_1/data/services/auth_api_service.dart';
import 'package:flutter_application_1/data/services/member_api_service.dart';
import 'package:flutter_application_1/data/storage/token_storage.dart';
import 'package:flutter_application_1/data/models/member_info.dart';
import 'package:flutter_application_1/view_models/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// fetchMe 결과를 정해 두는 가짜 내 정보 API
class FakeMemberApi extends MemberApiService {
  FakeMemberApi({this.error}) : super(Dio());
  final Object? error;
  int calls = 0;

  @override
  Future<MemberInfo> fetchMe() async {
    calls++;
    if (error != null) throw error!;
    return MemberInfo(
      email: 'me@example.com',
      nickname: 'Teemo',
      createdAt: DateTime(2026),
    );
  }
}

/// 로그인 결과를 정해 두는 가짜 로그인 API
class FakeAuthApi extends AuthApiService {
  FakeAuthApi({this.error}) : super(Dio());
  final Object? error;

  @override
  Future<LoginResult> login(LoginRequest request) async {
    if (error != null) throw error!;
    return const LoginResult(nickname: 'Teemo', accessToken: 'jwt');
  }
}

/// 저장을 직접 끝낼 때까지 기다리게 하는 저장소 (저장 중 로그아웃 흉내)
class SlowWriteStorage extends MemoryTokenStorage {
  final pending = Completer<void>();
  final log = <String>[];

  @override
  Future<void> saveAccessToken(String token) async {
    await pending.future;
    log.add('save');
    return super.saveAccessToken(token);
  }

  @override
  Future<void> deleteAccessToken() async {
    log.add('delete');
    return super.deleteAccessToken();
  }
}

/// 쓰기·삭제가 실패하는 저장소 (보안 저장소를 쓸 수 없는 기기 흉내)
class FailingWriteStorage extends MemoryTokenStorage {
  FailingWriteStorage([super.token]);
  bool failSave = true;
  bool failDelete = false;

  @override
  Future<void> saveAccessToken(String token) async {
    if (failSave) throw StateError('write failed');
    return super.saveAccessToken(token);
  }

  @override
  Future<void> deleteAccessToken() async {
    if (failDelete) throw StateError('delete failed');
    return super.deleteAccessToken();
  }
}

DioException authError(String code) {
  final options = RequestOptions(path: '/v7/members/me');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: 401,
      data: {'isSuccess': false, 'code': code, 'message': 'x', 'result': null},
    ),
  );
}

Future<AuthViewModel> signedInViewModel([TokenStorage? storage]) async {
  final vm = AuthViewModel(
    AuthApiService(Dio()),
    FakeMemberApi(),
    storage ?? MemoryTokenStorage(),
  );
  await vm.signIn(accessToken: 't1', nickname: 'a');
  return vm;
}

void main() {
  group('restoreSession', () {
    test('저장된 토큰이 없으면 signedOut, 내 정보 요청 안 함', () async {
      final api = FakeMemberApi();
      final vm = AuthViewModel(
        AuthApiService(Dio()),
        api,
        MemoryTokenStorage(),
      );
      await vm.restoreSession();
      expect(vm.status, AuthStatus.signedOut);
      expect(api.calls, 0);
    });

    test('토큰이 유효하면 signedIn + 내 정보', () async {
      final vm = AuthViewModel(
        AuthApiService(Dio()),
        FakeMemberApi(),
        MemoryTokenStorage('saved'),
      );
      await vm.restoreSession();
      expect(vm.status, AuthStatus.signedIn);
      expect(vm.nickname, 'Teemo');
      expect(vm.memberStatus, MemberLoadStatus.success);
    });

    test('토큰이 만료(AUTH401_4)면 저장소까지 정리하고 signedOut', () async {
      final storage = MemoryTokenStorage('expired');
      final vm = AuthViewModel(
        AuthApiService(Dio()),
        FakeMemberApi(error: authError('AUTH401_4')),
        storage,
      );
      await vm.restoreSession();
      expect(vm.status, AuthStatus.signedOut);
      expect(await storage.readAccessToken(), isNull);
      expect(vm.sessionExpired, isTrue);
    });

    test('네트워크 실패면 토큰을 지우지 않고 retryRequired', () async {
      final storage = MemoryTokenStorage('saved');
      final options = RequestOptions(path: '/v7/members/me');
      final vm = AuthViewModel(
        AuthApiService(Dio()),
        FakeMemberApi(
          error: DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        ),
        storage,
      );
      await vm.restoreSession();
      expect(vm.status, AuthStatus.retryRequired);
      expect(vm.message, isNotNull);
      expect(await storage.readAccessToken(), 'saved');
    });
  });

  group('401 처리', () {
    test('동시 401이 여러 개여도 세션 정리와 만료 안내는 한 번만', () async {
      final vm = await signedInViewModel();
      final version = vm.sessionVersion; // 세 요청 모두 같은 세션에서 보냄

      expect(vm.expire(version), isTrue);
      expect(vm.expire(version), isFalse);
      expect(vm.expire(version), isFalse);

      expect(vm.isLoggedIn, isFalse);
      expect(vm.sessionExpired, isTrue);
      vm.consumeSessionExpired(); // 로그인 화면이 안내를 한 번 보여준 뒤
      expect(vm.sessionExpired, isFalse);
    });

    test('이전 세션에서 늦게 온 401은 새 로그인 세션을 지우지 않음', () async {
      final vm = await signedInViewModel();
      final oldVersion = vm.sessionVersion;

      await vm.logout();
      await vm.signIn(accessToken: 'new', nickname: 'a');

      expect(vm.expire(oldVersion), isFalse);
      expect(vm.isLoggedIn, isTrue);
      expect(vm.sessionExpired, isFalse);
    });

    test('직접 로그아웃은 저장소를 비우고 만료 안내를 띄우지 않음', () async {
      final storage = MemoryTokenStorage();
      final vm = await signedInViewModel(storage);
      expect(await storage.readAccessToken(), 't1');

      await vm.logout();
      expect(vm.isLoggedIn, isFalse);
      expect(await storage.readAccessToken(), isNull);
      expect(vm.sessionExpired, isFalse);
    });
  });

  group('토큰 저장소', () {
    test('토큰 저장에 실패하면 로그인 상태로 바꾸지 않음', () async {
      final vm = AuthViewModel(
        AuthApiService(Dio()),
        FakeMemberApi(),
        FailingWriteStorage(),
      );
      final saved = await vm.signIn(accessToken: 't1', nickname: 'a');
      expect(saved, isFalse);
      expect(vm.isLoggedIn, isFalse);
    });

    test('로그아웃 때 삭제가 실패하면 빈 값으로 덮어써 다음 실행에 복원되지 않음', () async {
      final storage = FailingWriteStorage()..failSave = false;
      final vm = await signedInViewModel(storage);
      storage.failDelete = true;

      await vm.logout();
      expect(await storage.readAccessToken(), '');

      final next = AuthViewModel(
        AuthApiService(Dio()),
        FakeMemberApi(),
        storage,
      );
      await next.restoreSession();
      expect(next.status, AuthStatus.signedOut);
    });
  });

  group('login', () {
    test('성공하면 토큰을 저장한 뒤 signedIn', () async {
      final storage = MemoryTokenStorage();
      final vm = AuthViewModel(FakeAuthApi(), FakeMemberApi(), storage);
      final statuses = <AuthStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await vm.login('me@example.com', 'pw');
      expect(statuses, [AuthStatus.authenticating, AuthStatus.signedIn]);
      expect(await storage.readAccessToken(), 'jwt');
      expect(vm.nickname, 'Teemo');
    });

    test('AUTH401_1이면 signedOut + 입력 확인 문구, 만료 안내 없음', () async {
      final options = RequestOptions(path: '/v7/auth/login');
      final vm = AuthViewModel(
        FakeAuthApi(
          error: DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'isSuccess': false, 'code': 'AUTH401_1', 'message': 'x'},
            ),
          ),
        ),
        FakeMemberApi(),
        MemoryTokenStorage(),
      );
      await vm.login('me@example.com', 'wrong');
      expect(vm.status, AuthStatus.signedOut);
      expect(vm.message, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(vm.sessionExpired, isFalse);
    });

    test('서버에 닿지 못하면 연결 실패 문구 (입력 오류·저장 실패와 구분)', () async {
      final vm = AuthViewModel(
        FakeAuthApi(
          error: DioException(
            requestOptions: RequestOptions(path: '/v7/auth/login'),
            type: DioExceptionType.connectionError,
          ),
        ),
        FakeMemberApi(),
        MemoryTokenStorage(),
      );
      await vm.login('me@example.com', 'pw');
      expect(vm.status, AuthStatus.signedOut);
      expect(vm.message, '서버에 연결하지 못했어요. 네트워크를 확인해 주세요.');
    });

    test('토큰 저장에 실패하면 signedOut + 저장 실패 문구', () async {
      final vm = AuthViewModel(
        FakeAuthApi(),
        FakeMemberApi(),
        FailingWriteStorage(),
      );
      await vm.login('me@example.com', 'pw');
      expect(vm.status, AuthStatus.signedOut);
      expect(vm.message, '로그인 정보를 안전하게 저장하지 못했어요.');
    });

    test('정리는 진행 중인 토큰 저장이 끝난 뒤 삭제', () async {
      final storage = SlowWriteStorage();
      final vm = AuthViewModel(FakeAuthApi(), FakeMemberApi(), storage);
      final loginDone = vm.signIn(accessToken: 'jwt', nickname: 'a');
      await Future<void>.delayed(Duration.zero); // 저장 시작

      // 저장 중에 만료 정리가 시작돼도 삭제는 저장이 끝난 뒤
      vm.status = AuthStatus.signedIn;
      expect(vm.expire(vm.sessionVersion), isTrue);
      expect(vm.storageCleanupInProgress, isTrue);
      storage.pending.complete();
      expect(await loginDone, isFalse); // 정리로 세션이 바뀌어 로그인은 무효
      await Future<void>.delayed(Duration.zero);

      expect(storage.log, ['save', 'delete']);
      expect(await storage.readAccessToken(), isNull);
      expect(vm.status, AuthStatus.signedOut);
    });

    test('삭제·덮어쓰기가 모두 실패하면 저장소 확인 안내', () async {
      final storage = FailingWriteStorage()..failSave = false;
      final vm = await signedInViewModel(storage);
      storage
        ..failDelete = true
        ..failSave = true;
      await vm.logout();
      expect(vm.message, contains('저장된 인증 정보를 지우지 못했어요'));
    });
  });

  group('loadMember', () {
    Future<AuthViewModel> loggedIn(FakeMemberApi api) async {
      final vm = AuthViewModel(FakeAuthApi(), api, MemoryTokenStorage());
      await vm.login('me@example.com', 'pw');
      return vm;
    }

    test('로그인 직후 한 번 불러와 보관하고, 이미 있으면 다시 호출하지 않음', () async {
      final api = FakeMemberApi();
      final vm = await loggedIn(api);
      expect(api.calls, 0); // login()은 GET me를 부르지 않음

      await vm.loadMember();
      await vm.loadMember();
      expect(api.calls, 1);
      expect(vm.member?.nickname, 'Teemo');
      expect(vm.memberStatus, MemberLoadStatus.success);

      await vm.loadMember(force: true);
      expect(api.calls, 2);
    });

    test('복원으로 member가 이미 있으면 호출하지 않음', () async {
      final api = FakeMemberApi();
      final vm = AuthViewModel(FakeAuthApi(), api, MemoryTokenStorage('saved'));
      await vm.restoreSession();
      await vm.loadMember();
      expect(api.calls, 1); // 복원 때 한 번뿐
    });

    test('AUTH401_4면 세션 정리 → signedOut + 만료 안내', () async {
      final vm = await loggedIn(FakeMemberApi(error: authError('AUTH401_4')));
      await vm.loadMember();
      expect(vm.status, AuthStatus.signedOut);
      expect(vm.sessionExpired, isTrue);
    });

    test('네트워크 실패면 로그아웃하지 않고 error', () async {
      final vm = await loggedIn(
        FakeMemberApi(
          error: DioException(
            requestOptions: RequestOptions(path: '/v7/members/me'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      await vm.loadMember();
      expect(vm.status, AuthStatus.signedIn);
      expect(vm.memberStatus, MemberLoadStatus.error);
      expect(vm.message, '내 정보를 불러오지 못했어요.');
    });

    test('로그아웃 뒤 늦게 온 응답은 무시', () async {
      final api = SlowMemberApi();
      final vm = AuthViewModel(FakeAuthApi(), api, MemoryTokenStorage());
      await vm.login('me@example.com', 'pw');
      final loading = vm.loadMember();
      await vm.logout();
      api.pending.complete();
      await loading;
      expect(vm.member, isNull);
      expect(vm.status, AuthStatus.signedOut);
    });
  });
}

/// 응답을 직접 끝낼 때까지 기다리는 내 정보 API
class SlowMemberApi extends FakeMemberApi {
  final pending = Completer<void>();

  @override
  Future<MemberInfo> fetchMe() async {
    await pending.future;
    return super.fetchMe();
  }
}
