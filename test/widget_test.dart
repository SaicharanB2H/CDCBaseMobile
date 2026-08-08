import 'package:flutter_test/flutter_test.dart';
import 'package:cdc_mobile/main.dart';

void main() {
  testWidgets('App renders AuthScreen by default when no initial student', (WidgetTester tester) async {
    await tester.pumpWidget(const MailBaseApp());
    expect(find.text('MailBase CDC Portal'), findsOneWidget);
  });
}
