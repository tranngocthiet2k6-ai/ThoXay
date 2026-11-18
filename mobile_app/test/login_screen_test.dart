import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

void main() {
  testWidgets('login validates fields before making a request', (tester) async {
    final api = ApiService();
    await tester.pumpWidget(MaterialApp(home: LoginScreen(api: api)));
    final submit = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Nhập số điện thoại hợp lệ'), findsOneWidget);
    expect(find.text('Mật khẩu ít nhất 8 ký tự'), findsOneWidget);
    api.dispose();
  });
}
