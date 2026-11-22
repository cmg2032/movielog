import 'package:flutter_application_1/router/app_router.dart';
import 'package:flutter_application_1/view_models/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initializing·retryRequired: 스플래시(/start)만 유지', () {
    for (final status in [AuthStatus.initializing, AuthStatus.retryRequired]) {
      expect(authRedirect(status, '/start'), isNull);
      expect(authRedirect(status, '/home'), '/start');
      expect(authRedirect(status, '/login'), '/start');
      expect(authRedirect(status, '/my/ratings'), '/start');
    }
  });

  test('signedOut·authenticating: 공개 화면(/login, /register)만 허용', () {
    for (final status in [AuthStatus.signedOut, AuthStatus.authenticating]) {
      expect(authRedirect(status, '/login'), isNull);
      expect(authRedirect(status, '/register'), isNull);
      expect(authRedirect(status, '/start'), '/login');
      expect(authRedirect(status, '/home'), '/login');
      expect(authRedirect(status, '/movies/550'), '/login');
    }
  });

  test('signedIn: 스플래시·로그인·회원가입은 홈으로, 나머지는 그대로', () {
    expect(authRedirect(AuthStatus.signedIn, '/start'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/register'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/home'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/my/ratings'), isNull);
  });
}
