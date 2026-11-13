import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

Map<String, dynamic> auth(String token, {String phone = '0900000003'}) => {
  'token': token,
  'userId': 3,
  'fullName': 'Worker',
  'phoneNumber': phone,
  'role': 'ROLE_WORKER',
  'expiresIn': 3600,
};
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'credential rotation keeps fresh token and phone in persisted session',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/auth/login') {
            return http.Response(jsonEncode(auth('old')), 200);
          }
          if (request.url.path.endsWith('/password')) {
            expect(request.headers['Authorization'], 'Bearer old');
            expect(jsonDecode(request.body), {
              'currentPassword': 'Oldpass123',
              'newPassword': 'Newpass456',
            });
            return http.Response(jsonEncode(auth('fresh')), 200);
          }
          expect(request.url.path, '/api/users/me/settings/phone');
          expect(request.headers['Authorization'], 'Bearer fresh');
          expect(jsonDecode(request.body), {
            'phoneNumber': '0988881234',
            'currentPassword': 'Newpass456',
          });
          return http.Response(
            jsonEncode(auth('phone-token', phone: '0988881234')),
            200,
          );
        }),
      );
      await api.login('0900000003', 'Oldpass123');
      await api.changePassword('Oldpass123', 'Newpass456');
      expect(api.session!.token, 'fresh');
      await api.changePhone('0988881234', 'Newpass456');
      final saved = jsonDecode(
        (await SharedPreferences.getInstance()).getString('thoxay.session')!,
      );
      expect(saved['token'], 'phone-token');
      expect(saved['phoneNumber'], '0988881234');
      expect(requests.length, 3);
      api.dispose();
    },
  );
  test(
    'failed credential change retains current session and exposes server error',
    () async {
      final api = ApiService(
        client: MockClient(
          (request) async => request.url.path == '/api/auth/login'
              ? http.Response(jsonEncode(auth('old')), 200)
              : http.Response(
                  jsonEncode({'message': 'Mật khẩu hiện tại không đúng'}),
                  400,
                  headers: {'content-type': 'application/json; charset=utf-8'},
                ),
        ),
      );
      await api.login('0900000003', 'Oldpass123');
      await expectLater(
        api.changePassword('wrong', 'Newpass456'),
        throwsA(isA<ApiException>()),
      );
      expect(api.session!.token, 'old');
      api.dispose();
    },
  );
  test(
    'late credential response cannot restore a logged-out account',
    () async {
      final response = Completer<http.Response>();
      final api = ApiService(
        client: MockClient(
          (request) async => request.url.path == '/api/auth/login'
              ? http.Response(jsonEncode(auth('old')), 200)
              : response.future,
        ),
      );
      await api.login('0900000003', 'Oldpass123');
      final change = api.changePassword('Oldpass123', 'Newpass456');
      final assertion = expectLater(change, throwsA(isA<ApiException>()));
      await api.logout();
      response.complete(http.Response(jsonEncode(auth('fresh')), 200));
      await assertion;
      expect(api.session, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('thoxay.session'),
        isNull,
      );
      api.dispose();
    },
  );
  test('notification choices use authenticated account API and retain both categories', () async {
    final api = ApiService(
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(jsonEncode(auth('old')), 200);
        }
        expect(request.headers['Authorization'], 'Bearer old');
        expect(request.url.path, '/api/users/me/settings/notifications');
        if (request.method == 'GET') {
          return http.Response(
            '{"jobPushEnabled":true,"chatPushEnabled":false}',
            200,
          );
        }
        expect(jsonDecode(request.body), {
          'jobPushEnabled': false,
          'chatPushEnabled': true,
        });
        return http.Response('', 200);
      }),
    );
    await api.login('0900000003', 'Oldpass123');
    expect(await api.notificationPreferences(), {
      'jobPushEnabled': true,
      'chatPushEnabled': false,
    });
    await api.setNotificationPreferences(jobs: false, chat: true);
    api.dispose();
  });
}
