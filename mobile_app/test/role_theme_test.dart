import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/main.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';

void main() {
  test('role accent foregrounds remain readable on their filled buttons', () {
    for (final role in ['ROLE_WORKER', 'ROLE_CONTRACTOR', 'ROLE_ADMIN']) {
      final c = AppTheme.forRole(role).colorScheme;
      final a = c.primary.computeLuminance(),
          b = c.onPrimary.computeLuminance();
      expect(
        (math.max(a, b) + .05) / (math.min(a, b) + .05),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  testWidgets(
    'role theme follows login and also updates an already open route',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      var role = 'ROLE_WORKER';
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/login') {
            return http.Response(
              jsonEncode({
                'token': 'jwt',
                'userId': 3,
                'fullName': 'Demo',
                'phoneNumber': '0900000003',
                'role': role,
                'expiresIn': 3600,
              }),
              200,
            );
          }
          if (request.url.path.contains('notifications')) {
            return http.Response(
              '{"items":[],"hasMore":false,"unreadCount":0}',
              200,
            );
          }
          if (request.url.path.endsWith('/availability')) {
            return http.Response('{"available":false}', 200);
          }
          return http.Response('[]', 200);
        }),
      );
      await api.login('0900000003', 'password');
      await tester.pumpWidget(ThoXayApp(api: api));
      await tester.pumpAndSettle();
      final homeContext = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(homeContext).colorScheme.primary, AppTheme.workerOrange);
      Navigator.of(homeContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Theme route')),
        ),
      );
      await tester.pumpAndSettle();
      role = 'ROLE_CONTRACTOR';
      await api.login('0900000003', 'password');
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Theme route'))).colorScheme.primary,
        AppTheme.contractorEmerald,
      );
      await api.logout();
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Theme route'))).colorScheme.primary,
        AppTheme.light.colorScheme.primary,
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
