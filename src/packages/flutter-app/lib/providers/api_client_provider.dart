import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Provider for the API client singleton
final apiClientProvider = Provider<ApiClient>((ref) {
  // Create the API client
  final client = ApiClient();
  
  // Clean up when the provider is disposed
  ref.onDispose(() {
    client.close();
  });
  
  return client;
});
