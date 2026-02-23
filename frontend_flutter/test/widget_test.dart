import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_ai_system/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UrbanAISystemApp());

    // Verify that the app renders without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
