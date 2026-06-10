import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:travel_route_planner/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TravelRoutePlannerApp()));

    // The app builds its MaterialApp shell. On the first frame the AuthGate
    // shows a loading splash while the stored session is checked (no network in
    // the test env), then routes to sign-in/home — so we assert the shell builds
    // cleanly rather than coupling to any one screen's text.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}