import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ServerWarmupFailure implements Exception {
  const ServerWarmupFailure();
  String get message =>
      'Chưa kết nối được máy chủ. Vui lòng thử lại sau ít phút.';
}

/// Wake the free cloud server with read-only health checks, before sending any business request.
class ServerWarmup {
  ServerWarmup(
    this.client,
    this.base, {
    this.enabled = false,
    this.onChanged,
    this.budget = const Duration(minutes: 4),
    this.interval = const Duration(seconds: 4),
  });
  final http.Client client;
  final Uri base;
  final bool enabled;
  final void Function(bool)? onChanged;
  final Duration budget, interval;
  Future<void>? _pending;
  DateTime? _lastReachable;
  bool _disposed = false;
  final _cancel = Completer<void>();
  bool get _needed =>
      enabled && base.scheme == 'https' && base.host.endsWith('.onrender.com');

  Future<void> ensureReady() {
    if (_disposed) return Future.error(const ServerWarmupFailure());
    if (!_needed ||
        (_lastReachable != null &&
            DateTime.now().difference(_lastReachable!) <
                const Duration(minutes: 10))) {
      return Future.value();
    }
    return _pending ??= _check().whenComplete(() => _pending = null);
  }

  void reachable() {
    _lastReachable = DateTime.now();
  }

  Future<void> _check() async {
    final watch = Stopwatch()..start();
    onChanged?.call(true);
    try {
      while (!_disposed && watch.elapsed < budget) {
        final remaining = budget - watch.elapsed;
        final abort = Completer<void>();
        try {
          final request = http.AbortableRequest(
            'GET',
            base.replace(
              path: '${base.path}/api/auth/health',
              query: null,
              fragment: null,
            ),
            abortTrigger: Future.any([abort.future, _cancel.future]),
          )..followRedirects = false;
          final response = await client
              .send(request)
              .then(http.Response.fromStream)
              .timeout(
                remaining < const Duration(seconds: 8)
                    ? remaining
                    : const Duration(seconds: 8),
              );
          if (_disposed) throw const ServerWarmupFailure();
          final oldServer =
              response.statusCode >= 400 &&
              response.statusCode < 500 &&
              response.statusCode != 429;
          final ready =
              response.statusCode == 200 &&
              (jsonDecode(response.body) as Map)['status'] == 'UP';
          if (ready || oldServer) {
            reachable();
            return;
          }
        } on TimeoutException {
          /* Retry only this read-only health check. */
        } on http.ClientException {
          /* A sleeping instance may reject the first connection. */
        } on FormatException {
          /* A proxy HTML page is not readiness. */
        } on TypeError {
          /* Malformed readiness data is not success. */
        } finally {
          if (!abort.isCompleted) abort.complete();
        }
        final left = budget - watch.elapsed;
        if (!_disposed && left > Duration.zero) {
          final done = Completer<void>();
          final timer = Timer(
            left < interval ? left : interval,
            () => done.complete(),
          );
          try {
            await Future.any([done.future, _cancel.future]);
          } finally {
            timer.cancel();
          }
        }
      }
      throw const ServerWarmupFailure();
    } finally {
      watch.stop();
      onChanged?.call(false);
    }
  }

  void dispose() {
    _disposed = true;
    if (!_cancel.isCompleted) _cancel.complete();
  }
}
