import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'logout clears session even when unregistering the push device returns 401',
    () async {
      var cleanup = 0;
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode({
                'token': 'jwt',
                'userId': 3,
                'fullName': 'Worker',
                'phoneNumber': '0900000003',
                'role': 'ROLE_WORKER',
                'expiresIn': 3600,
              }),
              200,
            );
          }
          return http.Response('{"message":"Expired"}', 401);
        }),
      );
      await api.login('0900000003', 'password');
      api.beforeLogout = () async {
        cleanup++;
        await api.unregisterDevice('fake-fid');
      };
      await api.logout();
      expect(api.session, isNull);
      expect(cleanup, 1);
      await api.login('0900000003', 'password');
      expect(api.session, isNotNull);
      api.dispose();
    },
  );
  test('chat HTTP sends authenticated recipient and retry ID and loads cursor history', () async {
    var historyCalls = 0;
    final payload = {
      'id': 12,
      'senderId': 3,
      'recipientId': 2,
      'jobId': 8,
      'content': 'Chào chủ thầu',
      'createdAt': '2026-10-26T08:00:00Z',
      'clientMessageId': 'retry-id',
    };
    final api = ApiService(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'token': 'jwt',
              'userId': 3,
              'fullName': 'Worker A',
              'phoneNumber': '0900000003',
              'role': 'ROLE_WORKER',
              'expiresIn': 3600,
            }),
            200,
          );
        }
        expect(request.headers['Authorization'], 'Bearer jwt');
        expect(request.url.path, '/api/jobs/8/messages');
        if (request.method == 'POST') {
          expect(jsonDecode(request.body), {
            'recipientId': 2,
            'content': 'Chào chủ thầu',
            'clientMessageId': 'retry-id',
          });
          return http.Response(
            jsonEncode(payload),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        historyCalls++;
        expect(request.url.queryParameters['peerId'], '2');
        expect(
          request.url.queryParameters[historyCalls == 1
              ? 'afterId'
              : 'beforeId'],
          historyCalls == 1 ? '10' : '12',
        );
        return http.Response(
          jsonEncode({
            'messages': [payload],
            'hasMore': true,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await api.login('0900000003', 'password');
    expect(
      (await api.sendMessage(8, 2, 'Chào chủ thầu', 'retry-id')).content,
      'Chào chủ thầu',
    );
    final newer = await api.messageHistory(8, 2, afterId: 10);
    expect(newer.hasMore, isTrue);
    expect(newer.messages.single.id, 12);
    await api.messageHistory(8, 2, beforeId: 12);
    api.dispose();
  });
  test(
    'CCCD update sends both faces and decodes them from the profile',
    () async {
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode({
                'token': 'jwt',
                'userId': 3,
                'fullName': 'A',
                'phoneNumber': '0900000003',
                'role': 'ROLE_WORKER',
                'expiresIn': 3600,
              }),
              200,
            );
          }
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/users/me/cccd');
          expect(jsonDecode(request.body), {
            'cccdFrontImage': 'https://example.com/front.jpg',
            'cccdBackImage': 'https://example.com/back.jpg',
          });
          return http.Response(
            jsonEncode({
              'id': 3,
              'fullName': 'A',
              'phoneNumber': '0900000003',
              'role': 'ROLE_WORKER',
              'verified': false,
              'rating': 5,
              'cccdFrontImage': 'https://example.com/front.jpg',
              'cccdBackImage': 'https://example.com/back.jpg',
            }),
            200,
          );
        }),
      );
      await api.login('0900000003', 'password');
      final profile = await api.updateCccd(
        'https://example.com/front.jpg',
        'https://example.com/back.jpg',
      );
      expect(profile.cccdFrontImage, 'https://example.com/front.jpg');
      expect(profile.cccdBackImage, 'https://example.com/back.jpg');
      expect(profile.verified, isFalse);
      api.dispose();
    },
  );
  test(
    'locked 403 clears session while ordinary permission 403 keeps it',
    () async {
      var locked = false;
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode({
                'token': 'jwt',
                'userId': 3,
                'fullName': 'A',
                'phoneNumber': '0900000003',
                'role': 'ROLE_WORKER',
                'expiresIn': 3600,
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'status': 403,
              'code': locked ? 'ACCOUNT_LOCKED' : 'FORBIDDEN',
              'message': 'Forbidden',
            }),
            403,
          );
        }),
      );
      await api.login('0900000003', 'password');
      await expectLater(api.nearby(10, 106, 10), throwsA(isA<ApiException>()));
      expect(api.session, isNotNull);
      locked = true;
      await expectLater(api.nearby(10, 106, 10), throwsA(isA<ApiException>()));
      expect(api.session, isNull);
      api.dispose();
    },
  );
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
