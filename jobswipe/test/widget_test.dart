import 'package:flutter_test/flutter_test.dart';
import 'package:jobswipe/app/app.dart';

void main() {
  testWidgets('JobSwipe app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const JobSwipeApp());

    expect(find.text('JobSwipe'), findsOneWidget);
  });
}
