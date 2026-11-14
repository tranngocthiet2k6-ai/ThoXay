import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/wallet.dart';
import 'package:tho_xay_mobile/screens/worker_home_screen.dart';
import 'package:tho_xay_mobile/screens/wallet_screen.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';

import 'wallet_test.dart' show WalletApi;

class _TabsApi extends WalletApi {
  int walletLoads = 0;
  @override
  Future<bool> availability() async => false;
  @override
  Future<List<JobApplication>> workerApplications() async => [];
  @override
  Future<WalletBalance> wallet() async {
    walletLoads++;
    return super.wallet();
  }
}

void main() {
  testWidgets(
    'switching profile and wallet keeps wallet state without back navigation',
    (tester) async {
      final api = _TabsApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_WORKER'),
          home: WorkerHomeScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tab(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
      }

      await tab('Ví tiền');
      final state = tester.state(find.byType(WalletScreen));
      await tester.tap(find.byTooltip('Ẩn số dư'));
      await tester.pumpAndSettle();
      await tab('Hồ sơ');
      await tab('Ví tiền');
      expect(identical(tester.state(find.byType(WalletScreen)), state), isTrue);
      expect(find.byTooltip('Hiện số dư'), findsOneWidget);
      expect(api.walletLoads, 1);
      expect(
        Navigator.of(tester.element(find.byType(WalletScreen))).canPop(),
        isFalse,
      );
      expect(find.byType(BackButton), findsNothing);
      expect(find.byTooltip('Cài đặt'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  for (final role in ['ROLE_WORKER', 'ROLE_CONTRACTOR']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'withdraw label stays white on the dark wallet card $role $brightness',
        (tester) async {
          final api = WalletApi();
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.forRole(role, brightness: brightness),
              home: WalletScreen(api: api),
            ),
          );
          await tester.pumpAndSettle();
          final button = find.widgetWithText(OutlinedButton, 'Rút tiền');
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          final style = tester.widget<OutlinedButton>(button).style!;
          expect(style.foregroundColor!.resolve({}), Colors.white);
          expect(
            style.backgroundColor!.resolve({}),
            Colors.white.withValues(alpha: .14),
          );
          expect(style.side!.resolve({})!.width, 1.2);
          expect(
            tester.widget<Text>(find.text('Rút tiền')).style!.color,
            Colors.white,
          );
          await tester.pumpWidget(const SizedBox());
          api.dispose();
        },
      );
    }
  }
}
