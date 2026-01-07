// FoodieGo Widget Tests
//
// Basic smoke test to verify the app builds and runs correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodiego/main.dart';

void main() {
  testWidgets('FoodieGo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FoodieGoApp());

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
