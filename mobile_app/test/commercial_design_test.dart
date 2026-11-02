import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/commercial_hero.dart';

void main() {
  testWidgets(
    'commercial hero keeps financial text legible and availability truthful',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_WORKER'),
          home: const Scaffold(
            body: CommercialHero(
              child: Column(
                children: [
                  Text('2.450.000đ'),
                  PresenceAvatar(name: 'Nguyễn An', online: false),
                ],
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('2.450.000đ'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, Colors.white);
      expect(find.bySemanticsLabel('Tạm ngưng nhận việc'), findsOneWidget);
      expect(find.bySemanticsLabel('Sẵn sàng nhận việc'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
