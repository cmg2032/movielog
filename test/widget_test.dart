import 'package:flutter_application_1/app/movie_log_app.dart';
import 'package:flutter_application_1/screens/start_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // 테스트에서는 .env 파일을 읽지 않으므로 빈 값으로 초기화
    dotenv.loadFromString(envString: '', isOptional: true);
  });

  testWidgets('앱을 켜면 시작 화면이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pump();

    expect(find.byType(StartScreen), findsOneWidget);
  });
}
