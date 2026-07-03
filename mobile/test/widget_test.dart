import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('WebView render smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IqamahMobileApp());

    // WebView controller initialization is async; just check that the main MaterialApp builds
    expect(find.byType(IqamahMobileApp), findsOneWidget);
  });
}
