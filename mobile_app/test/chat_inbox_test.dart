import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/chat_message.dart';
import 'package:tho_xay_mobile/models/chat_inbox.dart';
import 'package:tho_xay_mobile/models/app_notification.dart';
import 'package:tho_xay_mobile/screens/chat_inbox_screen.dart';
import 'package:tho_xay_mobile/screens/chat_screen.dart';
import 'package:tho_xay_mobile/widgets/home_navigation.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

import 'support/fake_chat_api.dart';

class _InboxApi extends FakeChatApi {
  bool fail = false, empty = false;
  int unreadCalls = 0;
  @override
  Future<ChatInbox> chatInbox({int? beforeId}) async {
    if (fail) throw const ApiException('Mất kết nối');
    return ChatInbox(
      empty
          ? []
          : [
              ChatConversation(
                job: chatJob,
                peerId: 2,
                peerName: 'Anh Minh',
                latest: message(5, content: 'Mai bắt đầu nhé'),
                unreadCount: 3,
              ),
            ],
      false,
      empty ? 0 : 3,
    );
  }

  @override
  Future<int> unreadMessages() async {
    unreadCalls++;
    if (fail) throw const ApiException('Mất kết nối');
    return 3;
  }

  @override
  Future<NotificationPage> notifications({int? beforeId}) async =>
      const NotificationPage([], false, 7);
}

void main() {
  testWidgets(
    'inbox shows actual unread preview, opens the right peer and keeps data offline',
    (tester) async {
      final api = _InboxApi();
      await tester.pumpWidget(MaterialApp(home: ChatInboxScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('3 chưa đọc'), findsOneWidget);
      expect(find.text('Anh Minh'), findsOneWidget);
      expect(find.text('Mai bắt đầu nhé'), findsOneWidget);
      api.fail = true;
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.text('Anh Minh'), findsOneWidget);
      expect(find.text('3 chưa đọc'), findsOneWidget);
      api.fail = false;
      await tester.tap(find.text('Anh Minh'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(tester.widget<ChatScreen>(find.byType(ChatScreen)).peerId, 2);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets('empty inbox has a job CTA and never invents a conversation', (
    tester,
  ) async {
    final api = _InboxApi()..empty = true;
    await tester.pumpWidget(MaterialApp(home: ChatInboxScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Cuộc trò chuyện bắt đầu từ công trình'), findsOneWidget);
    expect(find.text('Xem công trình'), findsOneWidget);
    expect(find.text('0 chưa đọc'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets(
    'home keeps notification and chat counts separate and skips polling while backgrounded',
    (tester) async {
      final api = _InboxApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HomeNavigation(api: api, worker: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final labels = tester
          .widgetList<Badge>(find.byType(Badge))
          .map((badge) => (badge.label! as Text).data);
      expect(labels, containsAll(['7', '3']));
      final before = api.unreadCalls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 21));
      expect(api.unreadCalls, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(api.unreadCalls, before + 1);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'new messages are unread while scrolling history until the bottom is visible',
    (tester) async {
      final api = FakeChatApi();
      final initial = List.generate(40, (i) => message(i + 1));
      api.rows.addAll(initial);
      api.initialHistory = Completer<MessagePage>()
        ..complete(MessagePage(initial, false));
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            api: api,
            job: chatJob,
            peerId: 2,
            peerName: 'Anh Minh',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.readIds.last, 40);
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      scroll.position.jumpTo(400);
      await tester.pumpAndSettle();
      final incoming = message(41);
      api.rows.add(incoming);
      api.connections.last.add(messageEvent(incoming));
      await tester.pumpAndSettle();
      expect(api.readIds.last, 40);
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      expect(api.readIds.last, 41);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
