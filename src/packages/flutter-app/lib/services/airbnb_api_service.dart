import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airbnb_listing.dart';

class AirbnbApiService {
  final String baseUrl;
  final http.Client httpClient;

  AirbnbApiService({required this.baseUrl, http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  Future<AirbnbListing> parseListing(String url) async {
    final response = await httpClient
        .post(
          Uri.parse('$baseUrl/airbnb/parse'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'url': url}),
        )
        .timeout(const Duration(seconds: 165));

    if (response.statusCode == 200) {
      return AirbnbListing.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to parse Airbnb listing');
  }
}
