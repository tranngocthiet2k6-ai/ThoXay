import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// Retries short connection failures without changing tile URLs or cache rules.
class MapTileClient extends http.BaseClient {
  MapTileClient({
    http.Client? client,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) : _client = RetryClient(
         client ?? http.Client(),
         retries: 2,
         when: (response) =>
             const [502, 503, 504].contains(response.statusCode),
         whenError: (error, _) =>
             error is TimeoutException ||
             error is http.ClientException &&
                 error is! http.RequestAbortedException,
         delay: (attempt) => retryDelay * (1 << attempt),
       );

  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request);

  @override
  void close() => _client.close();
}
