import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/country_route_request.dart';
import '../models/country_route_response.dart';
import '../models/country.dart';
import '../services/api_client.dart';
import 'api_client_provider.dart';

/// State for country route optimization
class CountryState {
  final List<Country> countries;
  final CountryRouteResponse? response;
  final bool isLoading;
  final String? error;
  final String? startCountry;
  final String? tripStartDate;
  final int? tripDurationDays;
  final String optimizeFor;
  final bool returnToStart;

  const CountryState({
    this.countries = const [],
    this.response,
    this.isLoading = false,
    this.error,
    this.startCountry,
    this.tripStartDate,
    this.tripDurationDays,
    this.optimizeFor = 'balanced',
    this.returnToStart = false,
  });

  CountryState copyWith({
    List<Country>? countries,
    CountryRouteResponse? response,
    bool? isLoading,
    String? error,
    String? startCountry,
    String? tripStartDate,
    int? tripDurationDays,
    String? optimizeFor,
    bool? returnToStart,
  }) {
    return CountryState(
      countries: countries ?? this.countries,
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startCountry: startCountry ?? this.startCountry,
      tripStartDate: tripStartDate ?? this.tripStartDate,
      tripDurationDays: tripDurationDays ?? this.tripDurationDays,
      optimizeFor: optimizeFor ?? this.optimizeFor,
      returnToStart: returnToStart ?? this.returnToStart,
    );
  }

  /// Clear any error state
  CountryState clearError() {
    return copyWith(error: null);
  }

  /// Clear the response and reset state
  CountryState reset() {
    return const CountryState();
  }
}

/// Notifier for country route optimization state
class CountryNotifier extends StateNotifier<CountryState> {
  final ApiClient _apiClient;

  CountryNotifier(this._apiClient) : super(const CountryState());

  /// Add a country to the route
  void addCountry(Country country) {
    final updatedCountries = [...state.countries, country];
    state = state.copyWith(
      countries: updatedCountries,
      response: null, // Clear previous response
      error: null,
    );
  }

  /// Remove a country from the route
  void removeCountry(int index) {
    if (index >= 0 && index < state.countries.length) {
      final updatedCountries = [...state.countries];
      updatedCountries.removeAt(index);
      state = state.copyWith(
        countries: updatedCountries,
        response: null, // Clear previous response
        error: null,
      );
    }
  }

  /// Update a country in the route
  void updateCountry(int index, Country country) {
    if (index >= 0 && index < state.countries.length) {
      final updatedCountries = [...state.countries];
      updatedCountries[index] = country;
      state = state.copyWith(
        countries: updatedCountries,
        response: null, // Clear previous response
        error: null,
      );
    }
  }

  /// Clear all countries
  void clearCountries() {
    state = state.copyWith(
      countries: [],
      response: null,
      error: null,
    );
  }

  /// Set optimization parameters
  void setOptimizationParams({
    String? startCountry,
    String? tripStartDate,
    int? tripDurationDays,
    String? optimizeFor,
    bool? returnToStart,
  }) {
    state = state.copyWith(
      startCountry: startCountry,
      tripStartDate: tripStartDate,
      tripDurationDays: tripDurationDays,
      optimizeFor: optimizeFor,
      returnToStart: returnToStart,
      response: null, // Clear previous response
      error: null,
    );
  }

  /// Optimize the country route
  Future<void> optimizeCountries() async {
    if (state.countries.isEmpty) {
      state = state.copyWith(error: 'Please add at least one country');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = CountryRouteRequest(
        countries: state.countries,
        startCountry: state.startCountry,
        tripStartDate: state.tripStartDate,
        tripDurationDays: state.tripDurationDays,
        optimizeFor: state.optimizeFor,
        returnToStart: state.returnToStart,
      );

      final response = await _apiClient.optimizeCountries(request);

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
    state = const CountryState();
  }
}

/// Provider for country route optimization state
final countryProvider = StateNotifierProvider<CountryNotifier, CountryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CountryNotifier(apiClient);
});
