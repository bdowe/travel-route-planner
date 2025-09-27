import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route_request.dart';
import '../models/route_response.dart';
import '../models/location.dart';
import '../services/api_client.dart';
import 'api_client_provider.dart';

/// State for route optimization
class RouteState {
  final List<Location> locations;
  final RouteResponse? response;
  final bool isLoading;
  final String? error;
  final String? startTime;
  final String? startDate;
  final bool returnToStart;

  const RouteState({
    this.locations = const [],
    this.response,
    this.isLoading = false,
    this.error,
    this.startTime,
    this.startDate,
    this.returnToStart = false,
  });

  RouteState copyWith({
    List<Location>? locations,
    RouteResponse? response,
    bool? isLoading,
    String? error,
    String? startTime,
    String? startDate,
    bool? returnToStart,
  }) {
    return RouteState(
      locations: locations ?? this.locations,
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      startDate: startDate ?? this.startDate,
      returnToStart: returnToStart ?? this.returnToStart,
    );
  }

  /// Clear any error state
  RouteState clearError() {
    return copyWith(error: null);
  }

  /// Clear the response and reset state
  RouteState reset() {
    return const RouteState();
  }
}

/// Notifier for route optimization state
class RouteNotifier extends StateNotifier<RouteState> {
  final ApiClient _apiClient;

  RouteNotifier(this._apiClient) : super(const RouteState());

  /// Add a location to the route
  void addLocation(Location location) {
    final updatedLocations = [...state.locations, location];
    state = state.copyWith(
      locations: updatedLocations,
      response: null, // Clear previous response
      error: null,
    );
  }

  /// Remove a location from the route
  void removeLocation(int index) {
    if (index >= 0 && index < state.locations.length) {
      final updatedLocations = [...state.locations];
      updatedLocations.removeAt(index);
      state = state.copyWith(
        locations: updatedLocations,
        response: null, // Clear previous response
        error: null,
      );
    }
  }

  /// Update a location in the route
  void updateLocation(int index, Location location) {
    if (index >= 0 && index < state.locations.length) {
      final updatedLocations = [...state.locations];
      updatedLocations[index] = location;
      state = state.copyWith(
        locations: updatedLocations,
        response: null, // Clear previous response
        error: null,
      );
    }
  }

  /// Clear all locations
  void clearLocations() {
    state = state.copyWith(
      locations: [],
      response: null,
      error: null,
    );
  }

  /// Set optimization parameters
  void setOptimizationParams({
    String? startTime,
    String? startDate,
    bool? returnToStart,
  }) {
    state = state.copyWith(
      startTime: startTime,
      startDate: startDate,
      returnToStart: returnToStart,
      response: null, // Clear previous response
      error: null,
    );
  }

  /// Optimize the route
  Future<void> optimizeRoute() async {
    if (state.locations.isEmpty) {
      state = state.copyWith(error: 'Please add at least one location');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = RouteRequest(
        locations: state.locations,
        startTime: state.startTime,
        startDate: state.startDate,
        returnToStart: state.returnToStart,
      );

      final response = await _apiClient.optimizeRoute(request);

      state = state.copyWith(
        isLoading: false,
        response: response,
        error: null,
      );
    } catch (e) {
      String errorMessage = 'An unexpected error occurred';
      
      if (e is ApiException) {
        errorMessage = e.userFriendlyMessage;
      } else {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.clearError();
  }

  /// Reset all state
  void reset() {
    state = const RouteState();
  }
}

/// Provider for route optimization state
final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RouteNotifier(apiClient);
});
