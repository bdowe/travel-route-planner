import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transport_api_service.dart';
import 'api_client_provider.dart';

final transportApiServiceProvider = Provider<TransportApiService>((ref) {
  return TransportApiService(ref.watch(apiClientProvider));
});
