import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/screens/chat_screen.dart';

import 'support/fake_chat_api.dart';

void main() {
  testWidgets(
    'chat receives new messages, keeps failed draft and retries without duplicates',
    (tester) async {
      final api = FakeChatApi()..rows.add(message(1));
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            api: api,
            job: chatJob,
            peerId: 2,
            peerName: 'Chủ thầu A',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đã kết nối'), findsOneWidget);
      expect(find.text('Tin 1'), findsOneWidget);
      final incoming = message(2, content: 'Tin mới tức thì');
      api.rows.add(incoming);
      api.connections.last.add(messageEvent(incoming));
      await tester.pumpAndSettle();
      expect(find.text('Tin mới tức thì'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Hẹn sáng mai',
      );
      await tester.pump();
      api.failSendOnce = true;
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-input')))
            .controller!
            .text,
        'Hẹn sáng mai',
      );
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-input')))
            .controller!
            .text,
        isEmpty,
      );
      expect(api.sentIds[0], api.sentIds[1]);
      expect(find.text('Hẹn sáng mai'), findsOneWidget);
      expect(find.text('Tin mới tức thì'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(api.closed, 1);
      api.dispose();
    },
  );

  testWidgets('permission error is visible and disables the composer', (
    tester,
  ) async {
    final api = FakeChatApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          api: api,
          job: chatJob,
          peerId: 2,
          peerName: 'Chủ thầu A',
        ),
      ),
    );
    await tester.pumpAndSettle();
    api.connections.last.add({
      'type': 'error',
      'code': 'CHAT_FORBIDDEN',
      'message': 'Đơn chưa được duyệt',
    });
    await tester.pumpAndSettle();
    expect(find.text('Đơn chưa được duyệt'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('chat-input')))
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('chat-send')))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
