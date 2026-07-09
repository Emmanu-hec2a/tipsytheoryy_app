// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:tipsytheoryy_app/main.dart';

void main() {
  testWidgets('landing screen shows primary sign-up options', (WidgetTester tester) async {
    await tester.pumpWidget(const TipsyTheoryyApp());

    expect(find.text('Premium Liquor Delivered Fast'), findsOneWidget);
    expect(find.text('Sign Up as Customer'), findsOneWidget);
    expect(find.text('Apply as Rider'), findsOneWidget);
  });
}
