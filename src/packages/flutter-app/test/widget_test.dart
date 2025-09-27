import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:travel_route_planner/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TravelRoutePlannerApp()));

    // Verify that the app title is shown
    expect(find.text('Travel Route Planner'), findsOneWidget);
    expect(find.text('Welcome to Travel Route Planner'), findsOneWidget);
  });
}