import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/airbnb_listing.dart';
import '../services/airbnb_api_service.dart';
import 'api_client_provider.dart';

class AirbnbParserState {
  final AirbnbListing? listing;
  final bool isLoading;
  final String? error;

  const AirbnbParserState({
    this.listing,
    this.isLoading = false,
    this.error,
  });

  AirbnbParserState copyWith({
    AirbnbListing? listing,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearListing = false,
  }) {
    return AirbnbParserState(
      listing: clearListing ? null : (listing ?? this.listing),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AirbnbParserNotifier extends StateNotifier<AirbnbParserState> {
  final AirbnbApiService _service;

  AirbnbParserNotifier(this._service) : super(const AirbnbParserState());

  Future<void> parseListing(String url) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final listing = await _service.parseListing(url);
      state = state.copyWith(isLoading: false, listing: listing);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const AirbnbParserState();
}

final airbnbApiServiceProvider = Provider<AirbnbApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AirbnbApiService(baseUrl: client.baseUrl, httpClient: client.httpClient);
});

final airbnbParserProvider =
    StateNotifierProvider<AirbnbParserNotifier, AirbnbParserState>((ref) {
  return AirbnbParserNotifier(ref.watch(airbnbApiServiceProvider));
});
