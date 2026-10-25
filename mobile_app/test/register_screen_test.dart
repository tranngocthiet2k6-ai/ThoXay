import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/register_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

void main() {
  testWidgets(
      'registration offers worker and contractor and validates required fields',
      (tester) async {
    final api = ApiService();
    await tester.pumpWidget(MaterialApp(home: RegisterScreen(api: api)));
    expect(find.text('Tôi là thợ'), findsOneWidget);
    expect(find.text('Tôi là chủ thầu'), findsOneWidget);
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pump();
    expect(find.text('Nhập họ và tên'), findsOneWidget);
    expect(find.text('Mật khẩu nhập lại chưa khớp'), findsOneWidget);
    api.dispose();
  });
}
