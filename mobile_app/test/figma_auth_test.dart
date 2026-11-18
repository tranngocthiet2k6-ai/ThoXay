import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/login_screen.dart';
import 'package:tho_xay_mobile/screens/register_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/figma_design.dart';

void main() {
  testWidgets('Figma auth tabs keep role choice on registration only', (
    tester,
  ) async {
    final api = ApiService();
    await tester.pumpWidget(MaterialApp(home: LoginScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Tôi là thợ'), findsNothing);
    final tabs = find.byType(FigmaSegments);
    await tester.tap(find.descendant(of: tabs, matching: find.text('Đăng ký')));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Tôi là thợ'), findsOneWidget);
    expect(find.text('Tôi là chủ thầu'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(FigmaSegments),
        matching: find.text('Đăng nhập'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.text('Tôi là thợ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
