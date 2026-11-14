import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

Map<String, dynamic> session(String token, String role) => {
  'token': token,
  'role': role,
  'userId': 3,
  'fullName': 'Worker',
  'phoneNumber': '0900000003',
  'expiresIn': 3600,
};
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'role change rotates and persists token/role without logout or new user ID',
    () async {
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode(session('old', 'ROLE_WORKER')),
              200,
            );
          }
          expect(request.url.path, '/api/users/me/settings/role');
          expect(request.method, 'PUT');
          expect(request.headers['Authorization'], 'Bearer old');
          expect(jsonDecode(request.body), {'role': 'ROLE_CONTRACTOR'});
          return http.Response(
            jsonEncode(session('fresh', 'ROLE_CONTRACTOR')),
            200,
          );
        }),
      );
      await api.login('0900000003', 'Password123');
      await api.switchRole('ROLE_CONTRACTOR');
      expect(api.session!.role, 'ROLE_CONTRACTOR');
      expect(api.session!.userId, 3);
      expect(api.session!.token, 'fresh');
      expect(
        jsonDecode(
          (await SharedPreferences.getInstance()).getString('thoxay.session')!,
        )['role'],
        'ROLE_CONTRACTOR',
      );
      api.dispose();
    },
  );
  test(
    'active-work conflict keeps authenticated session and its original role',
    () async {
      final api = ApiService(
        client: MockClient(
          (request) async => request.url.path == '/api/auth/login'
              ? http.Response(jsonEncode(session('old', 'ROLE_WORKER')), 200)
              : http.Response('{"message":"Active work remains"}', 409),
        ),
      );
      await api.login('0900000003', 'Password123');
      await expectLater(
        api.switchRole('ROLE_CONTRACTOR'),
        throwsA(isA<ApiException>()),
      );
      expect(api.session!.token, 'old');
      expect(api.session!.role, 'ROLE_WORKER');
      api.dispose();
    },
  );
  test(
    'old avatar response cannot log out the freshly switched session',
    () async {
      final image = Completer<http.Response>(), started = Completer<void>();
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode(session('old', 'ROLE_WORKER')),
              200,
            );
          }
          if (request.url.path.endsWith('/avatar')) {
            started.complete();
            return image.future;
          }
          return http.Response(
            jsonEncode(session('fresh', 'ROLE_CONTRACTOR')),
            200,
          );
        }),
      );
      await api.login('0900000003', 'Password123');
      final pending = api.privateImage('/api/users/3/avatar?v=old');
      final assertion = expectLater(pending, throwsA(isA<ApiException>()));
      await started.future;
      await api.switchRole('ROLE_CONTRACTOR');
      image.complete(http.Response('{"message":"Old token revoked"}', 401));
      await assertion;
      expect(api.session!.token, 'fresh');
      expect(api.session!.role, 'ROLE_CONTRACTOR');
      api.dispose();
    },
  );
}
