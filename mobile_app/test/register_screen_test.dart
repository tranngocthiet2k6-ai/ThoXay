import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/register_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/appearance_button.dart';

void main() {
  testWidgets(
    'registration has one appearance button and an inline back action',
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
      await tester.tap(find.text('Quay lại đăng nhập'));
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
