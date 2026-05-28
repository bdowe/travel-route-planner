import 'dart:convert';
import '../models/trip.dart';
import 'api_client.dart';

/// Wraps the authenticated /trips endpoints. Reads the bearer token from the
/// shared ApiClient at call time so it always reflects the current session.
class TripsApiService {
  final ApiClient apiClient;

  TripsApiService(this.apiClient);

  Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final token = apiClient.authToken;
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<List<Trip>> listTrips() async {
    final res = await apiClient.httpClient
        .get(Uri.parse('${apiClient.baseUrl}/trips'), headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load trips (${res.statusCode})');
  }

  Future<Trip> getTrip(String id) async {
    final res = await apiClient.httpClient
        .get(Uri.parse('${apiClient.baseUrl}/trips/$id'), headers: _headers());
    if (res.statusCode == 200) {
      return Trip.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load trip (${res.statusCode})');
  }

  Future<Trip> patchTrip(
    String id, {
    String? title,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (startDate != null) body['start_date'] = startDate;
    if (endDate != null) body['end_date'] = endDate;
    if (status != null) body['status'] = status;

    final res = await apiClient.httpClient.patch(
      Uri.parse('${apiClient.baseUrl}/trips/$id'),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return Trip.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to update trip (${res.statusCode})');
  }

  Future<void> deleteTrip(String id) async {
    final res = await apiClient.httpClient
        .delete(Uri.parse('${apiClient.baseUrl}/trips/$id'), headers: _headers());
    if (res.statusCode != 204) {
      throw Exception('Failed to delete trip (${res.statusCode})');
    }
  }
}
