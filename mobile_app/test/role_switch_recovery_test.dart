import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/widgets/role_switch_tile.dart';
import 'package:tho_xay_mobile/models/role_blocker.dart';
import 'package:tho_xay_mobile/screens/role_switch_blockers_screen.dart';
import 'package:tho_xay_mobile/screens/job_payments_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

import 'stop_recruiting_status_test.dart' show closedJob;

import 'role_tier_ui_test.dart' show RoleTierApi;

class RecoveryApi extends RoleTierApi {
  bool failBlockersLoad = false;
  @override
  Future<List<RoleBlocker>> roleBlockers() async {
    if (failBlockersLoad) throw const ApiException('Không tải được công việc');
    return [
      RoleBlocker(
        reason: 'UNPAID_WORK',
        job: closedJob('COMPLETED'),
        owner: activeRole == 'ROLE_CONTRACTOR',
      ),
    ];
  }
}

void main() {
  for (final worker in [true, false]) {
    testWidgets(
      'blocked ${worker ? 'worker' : 'contractor'} can open work needing attention',
      (tester) async {
        final api = RecoveryApi()
          ..activeRole = worker ? 'ROLE_WORKER' : 'ROLE_CONTRACTOR'
          ..blocked = true;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RoleSwitchTile(api: api)),
          ),
        );
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chuyển vai trò'));
        await tester.pumpAndSettle();
        expect(find.text('Xem công việc cần xử lý'), findsOneWidget);
        await tester.tap(find.text('Xem công việc cần xử lý'));
        await tester.pumpAndSettle();
        expect(find.byType(RoleSwitchBlockersScreen), findsOneWidget);
        expect(find.text('Công trình đã dừng'), findsOneWidget);
        if (worker) {
          expect(
            find.textContaining('Chủ thầu chưa chốt thanh toán'),
            findsOneWidget,
          );
          expect(find.text('Thanh toán tiền công'), findsNothing);
        } else {
          await tester.tap(find.text('Thanh toán tiền công'));
          await tester.pumpAndSettle();
          expect(find.byType(JobPaymentsScreen), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }
  testWidgets('work recovery can retry a failed load', (tester) async {
    final api = RecoveryApi()..failBlockersLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: RoleSwitchBlockersScreen(api: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được công việc'), findsOneWidget);
    api.failBlockersLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Công trình đã dừng'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
