import 'package:flutter_application_1/app/movie_log_app.dart';
import 'package:flutter_application_1/data/storage/saved_email_storage.dart';
import 'package:flutter_application_1/data/storage/token_storage.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // 테스트에서는 .env 파일을 읽지 않으므로 빈 값으로 초기화
    dotenv.loadFromString(envString: '', isOptional: true);
  });

  testWidgets('저장된 토큰이 없으면 Splash 다음 로그인 화면이 보인다', (tester) async {
    // 테스트 환경에는 기기 보안 저장소가 없으므로 빈 메모리 저장소 사용
    await tester.pumpWidget(
      MovieLogApp(
        tokenStorage: MemoryTokenStorage(),
        savedEmailStorage: MemorySavedEmailStorage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
