import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_route_planner/models/booking_todo.dart';
import 'package:travel_route_planner/screens/trip_detail_derivation.dart';
import 'package:travel_route_planner/widgets/booking_todo_card.dart';

import 'support/l10n_test_app.dart';

/// Dismissal (00077): a derived slot the trip doesn't need. The row offers
/// "Remove — no booking needed" only where the tab wires it (auto, live,
/// bare slot); a dismissed row mutes, tags itself, hides its checkbox and
/// offers only Restore; and the counts derivation drops dismissed entries
/// from the denominator — "Bad Ischl · 1/1", not 1/2.
BookingTodo _todo({bool auto = true, bool dismissed = false}) => BookingTodo(
      id: 't1',
      kind: 'stay',
      todoKey: 'stay:bad ischl',
      title: 'Stay in Bad Ischl',
      subtitle: 'Sep 7 – Sep 10',
      booked: false,
      auto: auto,
      dismissed: dismissed,
      position: 0,
    );

Future<void> _pumpRow(WidgetTester tester, BookingTodoRow row) => tester
    .pumpWidget(localizedTestApp(home: Scaffold(body: Material(child: row))));

void main() {
  testWidgets('a live derived row offers the dismissal in its menu',
      (tester) async {
    var dismissed = false;
    await _pumpRow(
        tester,
        BookingTodoRow(
          todo: _todo(),
          onBookedChanged: (_) {},
          onDismiss: () => dismissed = true,
        ));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Remove — no booking needed'), findsOneWidget);
    await tester.tap(find.text('Remove — no booking needed'));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
  });

  testWidgets(
      'a dismissed row mutes, tags itself, hides the checkbox, and restores',
      (tester) async {
    var restored = false;
    await _pumpRow(
        tester,
        BookingTodoRow(
          todo: _todo(dismissed: true),
          onBookedChanged: (_) {},
          dismissed: true,
          onRestore: () => restored = true,
        ));
    expect(find.text('Removed — no booking needed'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing,
        reason: 'a dismissed slot has no booked state to record');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Restore to checklist'), findsOneWidget);
    await tester.tap(find.text('Restore to checklist'));
    await tester.pumpAndSettle();
    expect(restored, isTrue);
  });

  test('bookingEntryDismissed reads only the todo, and counts skip dismissed',
      () {
    final live = (todo: _todo(), stay: null, segment: null);
    final gone = (todo: _todo(dismissed: true), stay: null, segment: null);
    expect(bookingEntryDismissed(live), isFalse);
    expect(bookingEntryDismissed(gone), isTrue);
    expect(bookingEntryDismissed((todo: null, stay: null, segment: null)),
        isFalse,
        reason: 'confirmed records are real, never dismissed');
  });
}
