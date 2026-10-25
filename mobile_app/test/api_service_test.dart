import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'saves session, sends JWT and clears it on unauthorized response',
    () async {
      var calls = 0;
      final api = ApiService(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          calls++;
          if (request.url.path == '/api/auth/login') {
            expect(jsonDecode(request.body)['phoneNumber'], '0900000003');
            return http.Response(
              jsonEncode({
                'token': 'signed-jwt',
                'userId': 3,
                'fullName': 'Thợ',
                'phoneNumber': '0900000003',
                'role': 'ROLE_WORKER',
                'expiresIn': 3600,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          expect(request.headers['Authorization'], 'Bearer signed-jwt');
          return http.Response(
            '{"message":"Phiên hết hạn"}',
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await api.login('0900000003', 'password');
      expect(api.session?.userId, 3);
      expect(
        (await SharedPreferences.getInstance()).getString('thoxay.session'),
        isNotNull,
      );
      await expectLater(api.nearby(10, 106, 10), throwsA(isA<ApiException>()));
      expect(api.session, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('thoxay.session'),
        isNull,
      );
      expect(calls, 2);
      api.dispose();
    },
  );
  test('restores persisted session and discards corrupted storage', () async {
    SharedPreferences.setMockInitialValues({
      'thoxay.session': jsonEncode({
        'token': 'jwt',
        'userId': 1,
        'fullName': 'A',
        'phoneNumber': '0900000001',
        'role': 'ROLE_WORKER',
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      }),
    });
    final api = ApiService();
    await api.restoreSession();
    expect(api.session?.userId, 1);
    api.dispose();
    SharedPreferences.setMockInitialValues({'thoxay.session': 'broken'});
    final invalid = ApiService();
    await invalid.restoreSession();
    expect(invalid.session, isNull);
    invalid.dispose();
  });
}
