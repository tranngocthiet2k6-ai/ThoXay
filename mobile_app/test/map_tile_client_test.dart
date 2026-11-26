import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tho_xay_mobile/services/map_tile_client.dart';

void main() {
  final tile = Uri.parse('https://tiles.example/0/0/0.png');

  test(
    'retries a temporary connection failure without bypassing caching',
    () async {
      var calls = 0;
      final client = MapTileClient(
        retryDelay: Duration.zero,
        client: MockClient((request) async {
          expect(request.url, tile);
          expect(request.headers.containsKey('cache-control'), isFalse);
          expect(request.headers.containsKey('pragma'), isFalse);
          if (++calls == 1) {
            throw http.ClientException('Connection reset', tile);
          }
          return http.Response('image', 200);
        }),
      );
      addTearDown(client.close);
      expect((await client.get(tile)).statusCode, 200);
      expect(calls, 2);
    },
  );

  test('persistent connection failure stops after three requests', () async {
    var calls = 0;
    final client = MapTileClient(
      retryDelay: Duration.zero,
      client: MockClient((request) async {
        calls++;
        throw http.ClientException('Offline', tile);
      }),
    );
    addTearDown(client.close);
    await expectLater(client.get(tile), throwsA(isA<http.ClientException>()));
    expect(calls, 3);
  });

  test(
    'permission and rate-limit responses are returned without retries',
    () async {
      for (final status in [403, 429]) {
        var calls = 0;
        final client = MapTileClient(
          retryDelay: Duration.zero,
          client: MockClient((request) async {
            calls++;
            return http.Response('Unavailable', status);
          }),
        );
        expect((await client.get(tile)).statusCode, status);
        expect(calls, 1);
        client.close();
      }
    },
  );

  test(
    'temporary gateway responses recover with the same tile request',
    () async {
      var calls = 0;
      final client = MapTileClient(
        retryDelay: Duration.zero,
        client: MockClient(
          (request) async => http.Response('', ++calls == 1 ? 503 : 200),
        ),
      );
      addTearDown(client.close);
      expect((await client.get(tile)).statusCode, 200);
      expect(calls, 2);
    },
  );
}
