import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:travel_route_planner/models/trip.dart';
import 'package:travel_route_planner/models/itinerary_item.dart';
import 'package:travel_route_planner/models/accommodation.dart';
import 'package:travel_route_planner/services/api_client.dart';
import 'package:travel_route_planner/services/trips_api_service.dart';
import 'package:travel_route_planner/providers/trips_provider.dart';
import 'package:travel_route_planner/screens/trip_detail_screen.dart';

/// Returns a fixed trip without hitting the network, so we can exercise the
/// real TripDetailScreen render path.
class _FakeTripsApiService extends TripsApiService {
  final Trip trip;
  _FakeTripsApiService(this.trip) : super(ApiClient(baseUrl: 'http://test'));

  @override
  Future<Trip> getTrip(String id) async => trip;
}

ItineraryItem _item(int pos, String name, String address, String category) =>
    ItineraryItem(
      id: 'i$pos',
      position: pos,
      name: name,
      address: address,
      // Zero coords so the screen skips the map widget in the test env.
      latitude: 0,
      longitude: 0,
      category: category,
    );

void main() {
  testWidgets('itinerary groups by locality with dates derived from a stay',
      (WidgetTester tester) async {
    final trip = Trip(
      id: 't1',
      title: 'Bahamas',
      status: 'planned',
      createdAt: '2026-06-01',
      updatedAt: '2026-06-01',
      items: [
        _item(0, "Brendal's Dive Center", 'Green Turtle Cay, Abaco, Bahamas', 'attraction'),
        _item(1, "Miss Emily's Blue Bee Bar", 'Green Turtle Cay, Abaco, Bahamas', 'restaurant'),
        _item(2, 'Dive Guana', 'Great Guana Cay, Abaco, Bahamas', 'attraction'),
        _item(3, "Nipper's Beach Bar", 'Great Guana Cay, Abaco, Bahamas', 'restaurant'),
      ],
      // A stay in Green Turtle Cay supplies that group's dates; Great Guana has none.
      accommodations: const [
        Accommodation(
          id: 'a1',
          name: 'Green Turtle Club',
          address: 'Green Turtle Cay, Abaco, Bahamas',
          checkIn: '2026-06-10',
          checkOut: '2026-06-12',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripsApiServiceProvider.overrideWithValue(_FakeTripsApiService(trip)),
        ],
        child: MaterialApp(home: TripDetailScreen(tripId: 't1')),
      ),
    );
    await tester.pumpAndSettle();

    // Two locality headers appear.
    expect(find.text('Green Turtle Cay'), findsOneWidget);
    expect(find.text('Great Guana Cay'), findsOneWidget);

    // The Green Turtle Cay group is labelled with the stay's date range.
    expect(find.text('Jun 10 – Jun 12'), findsOneWidget);

    // Items still render under their groups.
    expect(find.text("Brendal's Dive Center"), findsOneWidget);
    expect(find.text('Dive Guana'), findsOneWidget);
  });
}
