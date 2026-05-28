import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip.dart';
import '../services/trips_api_service.dart';
import 'api_client_provider.dart';

final tripsApiServiceProvider = Provider<TripsApiService>((ref) {
  return TripsApiService(ref.watch(apiClientProvider));
});

class TripsState {
  final List<Trip> trips;
  final bool loading;
  final String? error;

  const TripsState({this.trips = const [], this.loading = false, this.error});

  TripsState copyWith({List<Trip>? trips, bool? loading, Object? error = _sentinel}) {
    return TripsState(
      trips: trips ?? this.trips,
      loading: loading ?? this.loading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

const _sentinel = Object();

class TripsNotifier extends StateNotifier<TripsState> {
  final TripsApiService _service;

  TripsNotifier(this._service) : super(const TripsState());

  Future<void> loadTrips() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final trips = await _service.listTrips();
      state = state.copyWith(trips: trips, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> deleteTrip(String id) async {
    await _service.deleteTrip(id);
    state = state.copyWith(trips: state.trips.where((t) => t.id != id).toList());
  }
}

final tripsProvider = StateNotifierProvider<TripsNotifier, TripsState>((ref) {
  return TripsNotifier(ref.watch(tripsApiServiceProvider));
});
