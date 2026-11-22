import 'package:dio/dio.dart';
import 'package:flutter_application_1/data/models/login_models.dart';
import 'package:flutter_application_1/data/models/member_info.dart';
import 'package:flutter_application_1/data/services/auth_api_service.dart';
import 'package:flutter_application_1/data/services/member_api_service.dart';
import 'package:flutter_application_1/data/storage/token_storage.dart';
import 'package:flutter_application_1/view_models/auth_view_model.dart';
import 'package:flutter_application_1/view_models/edit_profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthApi extends AuthApiService {
  FakeAuthApi() : super(Dio());

  @override
  Future<LoginResult> login(LoginRequest request) async =>
      const LoginResult(nickname: 'Teemo', accessToken: 'jwt');
}

/// 내 정보는 Teemo, 닉네임 수정 결과는 [updateError]로 정함
class FakeMemberApi extends MemberApiService {
  FakeMemberApi({this.updateError}) : super(Dio());
  final Object? updateError;
  final updated = <String>[];

  @override
  Future<MemberInfo> fetchMe() async => MemberInfo(
    email: 'me@example.com',
    nickname: 'Teemo',
    createdAt: DateTime(2026),
  );

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    updated.add(nickname);
    if (updateError != null) throw updateError!;
    return MemberInfo(
      email: 'me@example.com',
      nickname: nickname,
      createdAt: DateTime(2026),
    );
  }
}

DioException serverError(int status, String code, [String message = 'x']) {
  final options = RequestOptions(path: '/v7/members/me');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'isSuccess': false, 'code': code, 'message': message},
    ),
  );
}

Future<(AuthViewModel, EditProfileViewModel, FakeMemberApi)> setUpEdit({
  Object? updateError,
}) async {
  final api = FakeMemberApi(updateError: updateError);
  final auth = AuthViewModel(FakeAuthApi(), api, MemoryTokenStorage());
  await auth.login('me@example.com', 'pw');
  await auth.loadMember();
  return (auth, EditProfileViewModel(api, auth), api);
}

void main() {
  test('성공하면 AuthViewModel.member를 응답으로 교체 (GET me 재호출 없음)', () async {
    final (auth, vm, api) = await setUpEdit();
    expect(await vm.save('  무비러버 '), isTrue);
    expect(api.updated, ['무비러버']); // 앞뒤 공백 제거
    expect(auth.member?.nickname, '무비러버');
    expect(auth.nickname, '무비러버');
    expect(vm.status, EditProfileStatus.success);
  });

  test('2~12자가 아니면 요청 없이 필드 오류', () async {
    final (_, vm, api) = await setUpEdit();
    expect(await vm.save('a'), isFalse);
    expect(vm.nicknameError, '닉네임은 2~12자로 입력해 주세요.');
    expect(api.updated, isEmpty);
  });

  test('현재 닉네임과 같으면 요청 없이 완료', () async {
    final (_, vm, api) = await setUpEdit();
    expect(await vm.save('Teemo'), isTrue);
    expect(api.updated, isEmpty);
  });

  test('MEMBER409_1이면 필드 아래 중복 오류, 닉네임은 그대로', () async {
    final (auth, vm, _) = await setUpEdit(
      updateError: serverError(409, 'MEMBER409_1'),
    );
    expect(await vm.save('무비러버'), isFalse);
    expect(vm.nicknameError, '이미 사용 중인 닉네임이에요.');
    expect(vm.message, isNull);
    expect(auth.member?.nickname, 'Teemo');
  });

  test('COMMON400이면 서버 message를 필드 아래에', () async {
    final (_, vm, _) = await setUpEdit(
      updateError: serverError(400, 'COMMON400', '닉네임은 2자 이상 12자 이하여야 합니다.'),
    );
    await vm.save('무비러버');
    expect(vm.nicknameError, '닉네임은 2자 이상 12자 이하여야 합니다.');
  });

  test('401이면 세션 정리 → signedOut', () async {
    final (auth, vm, _) = await setUpEdit(
      updateError: serverError(401, 'AUTH401_4'),
    );
    expect(await vm.save('무비러버'), isFalse);
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isTrue);
  });

  test('네트워크 실패면 SnackBar 문구, 로그아웃하지 않음', () async {
    final (auth, vm, _) = await setUpEdit(
      updateError: DioException(
        requestOptions: RequestOptions(path: '/v7/members/me'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(await vm.save('무비러버'), isFalse);
    expect(vm.message, '네트워크 상태를 확인하고 다시 시도해 주세요.');
    expect(auth.status, AuthStatus.signedIn);
  });

  test('저장 중 다시 누르면 무시', () async {
    final (_, vm, api) = await setUpEdit();
    final first = vm.save('무비러버');
    expect(await vm.save('다른닉네임'), isFalse);
    expect(await first, isTrue);
    expect(api.updated, ['무비러버']);
  });
}
