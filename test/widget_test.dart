import 'package:flutter_application_1/app/movie_log_app.dart';
import 'package:flutter_application_1/screens/start_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('앱을 켜면 시작 화면이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pump();

    expect(find.byType(StartScreen), findsOneWidget);
  });
}
