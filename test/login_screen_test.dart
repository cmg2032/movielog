import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_application_1/data/models/login_models.dart';
import 'package:flutter_application_1/data/models/member_info.dart';
import 'package:flutter_application_1/data/services/auth_api_service.dart';
import 'package:flutter_application_1/data/services/member_api_service.dart';
import 'package:flutter_application_1/data/storage/saved_email_storage.dart';
import 'package:flutter_application_1/data/storage/token_storage.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/view_models/auth_view_model.dart';
import 'package:flutter_application_1/widgets/movielog_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

DioException error401(String code) {
  final options = RequestOptions(path: '/v7');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: 401,
      data: {'isSuccess': false, 'code': code, 'message': 'x'},
    ),
  );
}

class FakeAuthApi extends AuthApiService {
  FakeAuthApi({this.error}) : super(Dio());
  final Object? error;

  @override
  Future<LoginResult> login(LoginRequest request) async {
    if (error != null) throw error!;
    return const LoginResult(nickname: 'Teemo', accessToken: 'jwt');
  }
}

class FakeMemberApi extends MemberApiService {
  FakeMemberApi({this.error}) : super(Dio());
  final Object? error;

  @override
  Future<MemberInfo> fetchMe() async {
    if (error != null) throw error!;
    return MemberInfo(email: 'a@b.c', nickname: 'T', createdAt: DateTime(2026));
  }
}

Widget app(AuthViewModel auth, [SavedEmailStorage? emails]) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthViewModel>.value(value: auth),
    Provider<SavedEmailStorage>.value(
      value: emails ?? MemorySavedEmailStorage(),
    ),
  ],
  child: const MaterialApp(home: LoginScreen()),
);

const expiredText = '로그인이 만료됐어요. 다시 로그인해 주세요.';

void main() {
  testWidgets('만료로 정리된 뒤 열리면 SnackBar를 한 번만 보여줌', (tester) async {
    final auth = AuthViewModel(
      FakeAuthApi(),
      FakeMemberApi(error: error401('AUTH401_4')),
      MemoryTokenStorage('expired'),
    );
    await auth.restoreSession(); // 저장된 토큰이 만료 → sessionExpired
    expect(auth.sessionExpired, isTrue);

    await tester.pumpWidget(app(auth));
    await tester.pump(); // postFrameCallback
    expect(find.text(expiredText), findsOneWidget);
    expect(auth.sessionExpired, isFalse); // 보여준 뒤 꺼짐
  });

  testWidgets('직접 로그아웃이면 만료 SnackBar 없음', (tester) async {
    final auth = AuthViewModel(
      FakeAuthApi(),
      FakeMemberApi(),
      MemoryTokenStorage(),
    );
    await auth.login('a@b.c', 'pw');
    await auth.logout();

    await tester.pumpWidget(app(auth));
    await tester.pump();
    expect(find.text(expiredText), findsNothing);
  });

  testWidgets('AUTH401_1이면 Form 아래 오류 문구, 만료 SnackBar 없음', (tester) async {
    final auth = AuthViewModel(
      FakeAuthApi(error: error401('AUTH401_1')),
      FakeMemberApi(),
      MemoryTokenStorage(),
    );
    await auth.restoreSession(); // 저장된 토큰 없음 → signedOut

    await tester.pumpWidget(app(auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.c');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.ensureVisible(find.byType(MovieLogButton));
    await tester.tap(find.byType(MovieLogButton));
    await tester.pumpAndSettle();

    expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
    expect(find.text(expiredText), findsNothing);
  });

  testWidgets('빈 입력이면 요청 없이 Form 검증 문구', (tester) async {
    final auth = AuthViewModel(
      FakeAuthApi(),
      FakeMemberApi(),
      MemoryTokenStorage(),
    );
    await auth.restoreSession();

    await tester.pumpWidget(app(auth));
    await tester.ensureVisible(find.byType(MovieLogButton));
    await tester.tap(find.byType(MovieLogButton));
    await tester.pump();
    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
    expect(auth.status, AuthStatus.signedOut);
  });

  group('이메일 저장 (Challenge)', () {
    Future<AuthViewModel> signedOut() async {
      final auth = AuthViewModel(
        FakeAuthApi(),
        FakeMemberApi(),
        MemoryTokenStorage(),
      );
      await auth.restoreSession();
      return auth;
    }

    testWidgets('저장된 이메일이 있으면 채우고 체크', (tester) async {
      await tester.pumpWidget(
        app(await signedOut(), MemorySavedEmailStorage('saved@b.c')),
      );
      await tester.pumpAndSettle();
      expect(find.text('saved@b.c'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('체크하고 로그인 성공하면 이메일만 저장', (tester) async {
      final emails = MemorySavedEmailStorage();
      final auth = await signedOut();
      await tester.pumpWidget(app(auth, emails));
      await tester.enterText(find.byType(TextFormField).at(0), ' me@b.c ');
      await tester.enterText(find.byType(TextFormField).at(1), 'pw');
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.byType(MovieLogButton));
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(auth.status, AuthStatus.signedIn);
      expect(await emails.readEmail(), 'me@b.c'); // 비밀번호는 저장하지 않음
    });

    testWidgets('체크를 해제하고 로그인하면 저장된 이메일을 지움', (tester) async {
      final emails = MemorySavedEmailStorage('old@b.c');
      await tester.pumpWidget(app(await signedOut(), emails));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'pw');
      await tester.tap(find.byType(Checkbox)); // 해제
      await tester.ensureVisible(find.byType(MovieLogButton));
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(await emails.readEmail(), isNull);
    });
  });
}
