import 'package:flutter_test/flutter_test.dart';

import 'package:ojeomneo/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OjeomeoApp());

    // Verify that splash screen loads
    expect(find.text('오점너'), findsOneWidget);
    expect(find.text('오늘 점심 뭐 먹지?'), findsOneWidget);
  });
}
