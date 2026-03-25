// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cropsense_ai/main.dart';

void main() {
  testWidgets('App boots and shows navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const CropSenseApp());
    await tester.pumpAndSettle();

    // Bottom navigation labels should exist.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Process'), findsOneWidget);
    expect(find.text('Season'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
