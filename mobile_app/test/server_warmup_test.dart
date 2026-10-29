import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/server_warmup.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

final _base = Uri.parse('https://thoxay-api.onrender.com');

class _HangingClient extends http.BaseClient {
  int aborted = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final response = Completer<http.StreamedResponse>();
    (request as http.AbortableRequest).abortTrigger!.then((_) {
      aborted++;
      response.completeError(http.ClientException('aborted'));
    });
    return response.future;
  }
}

void main() {
  test('timed out health request is aborted rather than left running in the background', () async {
    final client = _HangingClient();
    final warm = ServerWarmup(
      client,
      _base,
      enabled: true,
      budget: const Duration(milliseconds: 30),
    );
    await expectLater(warm.ensureReady(), throwsA(isA<ServerWarmupFailure>()));
    await Future<void>.delayed(Duration.zero);
    expect(client.aborted, 1);
    warm.dispose();
    client.close();
  });
  test('simultaneous requests share readiness and never put JWT on health requests', () async {
    final gate = Completer<http.Response>();
    final requests = <http.Request>[];
    final client = MockClient((request) {
      requests.add(request);
      return gate.future;
    });
    final warm = ServerWarmup(client, _base, enabled: true);
    final first = warm.ensureReady(), second = warm.ensureReady();
    await Future<void>.delayed(Duration.zero);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(requests.single.headers.containsKey('authorization'), isFalse);
    expect(requests.single.url.path, '/api/auth/health');
    gate.complete(http.Response('{"status":"UP"}', 200));
    await Future.wait([first, second]);
    await warm.ensureReady();
    expect(requests, hasLength(1));
    warm.dispose();
    client.close();
  });
  test(
    'only read-only health checks retry through sleep and proxy HTML',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.method, 'GET');
        return calls == 1
            ? http.Response('sleeping', 503)
            : calls == 2
            ? http.Response('<html>starting</html>', 200)
            : http.Response('{"status":"UP"}', 200);
      });
      final warm = ServerWarmup(
        client,
        _base,
        enabled: true,
        interval: const Duration(milliseconds: 1),
        budget: const Duration(seconds: 1),
      );
      await warm.ensureReady();
      expect(calls, 3);
      warm.dispose();
      client.close();
    },
  );
  test(
    'unavailable server has a bounded wait and does not leave a retry loop',
    () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('sleeping', 503);
      });
      final warm = ServerWarmup(
        client,
        _base,
        enabled: true,
        interval: const Duration(milliseconds: 1),
        budget: const Duration(milliseconds: 30),
      );
      await expectLater(
        warm.ensureReady(),
        throwsA(isA<ServerWarmupFailure>()),
      );
      final finished = calls;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls, finished);
      expect(calls, greaterThan(0));
      warm.dispose();
      client.close();
    },
  );
  test('local servers bypass warmup and older cloud servers with no alias remain compatible', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('not found', 404);
    });
    final local = ServerWarmup(
      client,
      Uri.parse('http://127.0.0.1:8080'),
      enabled: true,
    );
    await local.ensureReady();
    expect(calls, 0);
    final cloud = ServerWarmup(client, _base, enabled: true);
    await cloud.ensureReady();
    await cloud.ensureReady();
    expect(calls, 1);
    local.dispose();
    cloud.dispose();
    client.close();
  });
  test('disposal never releases a pending business request after readiness arrives', () async {
    final gate = Completer<http.Response>();
    final client = MockClient((_) => gate.future);
    final warm = ServerWarmup(client, _base, enabled: true);
    final waiting = warm.ensureReady();
    warm.dispose();
    gate.complete(http.Response('{"status":"UP"}', 200));
    await expectLater(waiting, throwsA(isA<ServerWarmupFailure>()));
    client.close();
  });
  test('API waits before login, sends it once and keeps connection events separate from auth', () async {
    SharedPreferences.setMockInitialValues({});
    final gate = Completer<http.Response>();
    var posts = 0, authChanges = 0;
    final api = ApiService(
      warmUpServer: true,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/health')) return gate.future;
        posts++;
        return http.Response(
          jsonEncode({
            'token': 'qa-jwt',
            'userId': 1,
            'fullName': 'QA',
            'phoneNumber': '0900000000',
            'role': 'ROLE_WORKER',
            'expiresIn': 3600,
          }),
          200,
        );
      }),
    );
    api.addListener(() => authChanges++);
    final login = api.login('0900000000', 'password');
    await Future<void>.delayed(Duration.zero);
    expect(posts, 0);
    expect(api.warmingUp, isTrue);
    expect(authChanges, 0);
    gate.complete(http.Response('{"status":"UP"}', 200));
    await login;
    expect(posts, 1);
    expect(authChanges, 1);
    expect(api.warmingUp, isFalse);
    api.dispose();
  });
  test(
    'ambiguous login response never triggers an automatic mutation retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      var posts = 0;
      final api = ApiService(
        warmUpServer: true,
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response('{"status":"UP"}', 200);
          }
          posts++;
          throw http.ClientException('response lost');
        }),
      );
      await expectLater(
        api.login('0900000000', 'password'),
        throwsA(isA<ApiException>()),
      );
      expect(posts, 1);
      api.dispose();
    },
  );
  test('logout during readiness prevents sending an authenticated request with the old token', () async {
    SharedPreferences.setMockInitialValues({
      'thoxay.session': jsonEncode({
        'token': 'old-jwt',
        'userId': 1,
        'fullName': 'QA',
        'phoneNumber': '0900000000',
        'role': 'ROLE_WORKER',
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      }),
    });
    final gate = Completer<http.Response>();
    var profileCalls = 0;
    final api = ApiService(
      warmUpServer: true,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/health')) return gate.future;
        profileCalls++;
        return http.Response('{}', 200);
      }),
    );
    await api.restoreSession();
    final profile = api.profile();
    await Future<void>.delayed(Duration.zero);
    await api.logout();
    gate.complete(http.Response('{"status":"UP"}', 200));
    await expectLater(profile, throwsA(isA<ApiException>()));
    expect(profileCalls, 0);
    api.dispose();
  });
}
