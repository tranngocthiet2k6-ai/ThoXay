import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/register_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/appearance_button.dart';
import 'package:tho_xay_mobile/widgets/auth_shell.dart';
import 'package:tho_xay_mobile/widgets/auth_forms.dart';

void main() {
  testWidgets(
    'legacy registration entry has one header and switches login in place',
    (tester) async {
      final api = ApiService();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RegisterScreen(api: api),
                ),
              ),
              child: const Text('Open register'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open register'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(AppearanceButton), findsOneWidget);
      expect(find.text('Quay lại đăng nhập'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(AuthTabs),
          matching: find.text('Đăng nhập'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.text('Open register'), findsNothing);
      Navigator.of(tester.element(find.byType(LoginForm))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Open register'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'registration offers worker and contractor and validates required fields',
    (tester) async {
      final api = ApiService();
      await tester.pumpWidget(MaterialApp(home: RegisterScreen(api: api)));
      expect(find.text('Tôi là thợ'), findsOneWidget);
      expect(find.text('Tôi là chủ thầu'), findsOneWidget);
      await tester.ensureVisible(find.text('Tạo tài khoản'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo tài khoản'));
      await tester.pump();
      expect(find.text('Nhập họ và tên'), findsOneWidget);
      expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);
      api.dispose();
    },
  );
}
