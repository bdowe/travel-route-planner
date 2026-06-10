import 'dart:convert';
import '../models/airport.dart';
import '../models/flight_search_request.dart';
import '../models/flight_search_response.dart';
import 'api_client.dart';

/// Wraps the /flights/* endpoints (Amadeus-backed flight search + airport
/// autocomplete). These endpoints are public, but we still send the bearer
/// token when present, matching the other services.
class FlightsApiService {
  final ApiClient apiClient;

  FlightsApiService(this.apiClient);

  Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final token = apiClient.authToken;
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<FlightSearchResponse> searchFlights(FlightSearchRequest request) async {
    final res = await apiClient.httpClient.post(
      Uri.parse('${apiClient.baseUrl}/flights/search'),
      headers: _headers(json: true),
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 200) {
      return FlightSearchResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to search flights: ${res.body}',
      endpoint: 'flights/search',
    );
  }

  Future<List<Airport>> searchAirports(String query) async {
    final uri = Uri.parse('${apiClient.baseUrl}/flights/airports')
        .replace(queryParameters: {'q': query});
    final res = await apiClient.httpClient.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (body['results'] as List<dynamic>? ?? []);
      return list
          .map((e) => Airport.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to search airports: ${res.body}',
      endpoint: 'flights/airports',
    );
  }
}
