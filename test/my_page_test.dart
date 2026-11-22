import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_application_1/data/models/login_models.dart';
import 'package:flutter_application_1/data/models/member_info.dart';
import 'package:flutter_application_1/data/services/auth_api_service.dart';
import 'package:flutter_application_1/data/services/member_api_service.dart';
import 'package:flutter_application_1/data/storage/token_storage.dart';
import 'package:flutter_application_1/screens/edit_profile_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/view_models/auth_view_model.dart';
import 'package:flutter_application_1/view_models/edit_profile_view_model.dart';
import 'package:flutter_application_1/widgets/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FakeAuthApi extends AuthApiService {
  FakeAuthApi() : super(Dio());

  @override
  Future<LoginResult> login(LoginRequest request) async =>
      const LoginResult(nickname: 'Teemo', accessToken: 'jwt');
}

class FakeMemberApi extends MemberApiService {
  FakeMemberApi({this.fail = false}) : super(Dio());
  bool fail;

  @override
  Future<MemberInfo> fetchMe() async {
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/v7/members/me'),
        type: DioExceptionType.connectionError,
      );
    }
    return MemberInfo(
      email: 'movie@example.com',
      nickname: '무비러버',
      createdAt: DateTime(2026, 10, 10, 9),
    );
  }
}

Future<AuthViewModel> loggedIn(FakeMemberApi api) async {
  final auth = AuthViewModel(FakeAuthApi(), api, MemoryTokenStorage());
  await auth.login('movie@example.com', 'pw');
  return auth;
}

Widget myPage(AuthViewModel auth) => ChangeNotifierProvider.value(
  value: auth,
  child: const MaterialApp(home: ProfileScreen()),
);

void main() {
  test('가입일은 "2026.10.10 가입" 형식', () {
    expect(formatJoinedDate(DateTime(2026, 10, 10, 23)), '2026.10.10 가입');
    expect(formatJoinedDate(DateTime(2026, 1, 5)), '2026.01.05 가입');
  });

  group('마이페이지', () {
    testWidgets('불러오는 동안 화면 전체 인디케이터', (tester) async {
      final auth = await loggedIn(FakeMemberApi()); // member 아직 없음
      await tester.pumpWidget(myPage(auth));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('로그아웃'), findsNothing);
    });

    testWidgets('실패하면 재시도 버튼 → 성공하면 내 정보 표시', (tester) async {
      final api = FakeMemberApi(fail: true);
      final auth = await loggedIn(api);
      await auth.loadMember();
      await tester.pumpWidget(myPage(auth));
      expect(find.text('내 정보를 불러오지 못했어요.'), findsOneWidget);
      expect(auth.status, AuthStatus.signedIn); // 로그아웃하지 않음

      api.fail = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('무비러버'), findsOneWidget);
      expect(find.text('2026.10.10 가입'), findsOneWidget);
      expect(find.text('movie@example.com'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
    });

    testWidgets('앱바 로그아웃 → 토큰과 member 정리', (tester) async {
      final auth = await loggedIn(FakeMemberApi());
      await auth.loadMember();
      await tester.pumpWidget(myPage(auth));
      await tester.tap(find.text('로그아웃'));
      await tester.pump();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.member, isNull);
      expect(auth.sessionExpired, isFalse); // 직접 로그아웃: 만료 안내 없음
    });
  });

  group('프로필 수정 뒤로가기', () {
    Future<(AuthViewModel, GoRouter)> open(WidgetTester tester) async {
      final api = FakeMemberApi();
      final auth = await loggedIn(api);
      await auth.loadMember();
      final router = GoRouter(
        initialLocation: '/my',
        routes: [
          GoRoute(
            path: '/my',
            builder: (_, _) => const Scaffold(body: Text('마이페이지')),
            routes: [
              GoRoute(
                path: 'profile/edit',
                builder: (_, _) => ChangeNotifierProvider(
                  create: (_) => EditProfileViewModel(api, auth),
                  child: const EditProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/my/profile/edit');
      await tester.pumpAndSettle();
      return (auth, router);
    }

    testWidgets('변경 없으면 Dialog 없이 바로 나감', (tester) async {
      await open(tester);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('변경 내용을 버릴까요?'), findsNothing);
      expect(find.text('마이페이지'), findsOneWidget);
    });

    testWidgets('변경 있으면 Dialog: [계속 수정]은 머무르고 입력 유지', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField).last, '새닉네임');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('변경 내용을 버릴까요?'), findsOneWidget);

      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('새닉네임'), findsOneWidget);
    });

    testWidgets('[나가기]는 저장하지 않고 마이페이지로', (tester) async {
      final (auth, _) = await open(tester);
      await tester.enterText(find.byType(TextField).last, '새닉네임');
      await tester.pump(); // 변경 감지 후 다시 그리기
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();
      expect(find.text('마이페이지'), findsOneWidget);
      expect(auth.member?.nickname, '무비러버');
    });
  });
}
