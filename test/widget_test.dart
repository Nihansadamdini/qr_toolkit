import 'package:flutter_test/flutter_test.dart';

import 'package:qr_toolkit/main.dart';

void main() {
  testWidgets('App loads with Generate tab', (WidgetTester tester) async {
    await tester.pumpWidget(const QrToolkitApp());

    expect(find.text('Generate'), findsWidgets);
    expect(find.text('Generate QR'), findsOneWidget);
  });
}