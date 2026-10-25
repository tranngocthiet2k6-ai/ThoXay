import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/chat_message.dart';
import 'package:tho_xay_mobile/services/chat_controller.dart';

import 'support/fake_chat_api.dart';

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 300 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

void main() {
  test(
    'merges realtime during initial history and deduplicates repeated delivery',
    () async {
      final api = FakeChatApi()..initialHistory = Completer<MessagePage>();
      final chat = ChatController(api, 1, 2)..start();
      await until(() => api.historyQueries.isNotEmpty);
      api.connections.last.add(messageEvent(message(12)));
      api.initialHistory!.complete(
        MessagePage([message(10), message(11)], false),
      );
      await until(() => chat.status == ChatStatus.connected);
      api.connections.last.add(messageEvent(message(12)));
      await Future<void>.delayed(Duration.zero);
      expect(chat.messages.map((m) => m.id), [10, 11, 12]);
      chat.dispose();
      await until(() => api.closed == 1);
      api.dispose();
    },
  );

  test('reconnect catches up from REST cursor even if higher realtime ID already arrived', () async {
    final api = FakeChatApi()..rows.add(message(10));
    final chat = ChatController(api, 1, 2)..start();
    await until(() => chat.status == ChatStatus.connected);
    api.rows.addAll([message(11), message(12), message(13), message(14)]);
    api.connections.last.add(messageEvent(message(14)));
    await until(() => chat.messages.length == 2);
    await api.connections.last.close();
    await until(
      () => api.connections.length == 2 && chat.status == ChatStatus.connected,
    );
    expect(chat.messages.map((m) => m.id), [10, 11, 12, 13, 14]);
    expect(api.historyQueries.any((q) => q.after == 10), isTrue);
    expect(api.historyQueries.any((q) => q.after == 12), isTrue);
    chat.dispose();
    api.dispose();
  });

  test(
    'retry after uncertain response reuses id and shows one message',
    () async {
      final api = FakeChatApi()..failSendOnce = true;
      final chat = ChatController(api, 1, 2)..start();
      await until(() => chat.status == ChatStatus.connected);
      expect(await chat.send('Chào chủ thầu'), isFalse);
      expect(chat.error, contains('Nội dung vẫn được giữ'));
      expect(await chat.send('Chào chủ thầu'), isTrue);
      expect(api.sentIds[0], api.sentIds[1]);
      expect(api.rows.length, 1);
      expect(chat.messages.length, 1);
      chat.dispose();
      api.dispose();
    },
  );

  test('loads older pages and closes transport on disposal', () async {
    final api = FakeChatApi()
      ..rows.addAll([
        message(1),
        message(2),
        message(3),
        message(4),
        message(5),
      ]);
    final chat = ChatController(api, 1, 2)..start();
    await until(() => chat.status == ChatStatus.connected);
    expect(chat.messages.map((m) => m.id), [4, 5]);
    expect(chat.hasOlder, isTrue);
    await chat.loadOlder();
    await chat.loadOlder();
    expect(chat.messages.map((m) => m.id), [1, 2, 3, 4, 5]);
    expect(chat.hasOlder, isFalse);
    chat.dispose();
    await until(() => api.closed == 1);
    api.dispose();
  });

  test(
    'locked realtime session stops reconnecting, logs out and disables sends',
    () async {
      final api = FakeChatApi();
      final chat = ChatController(api, 1, 2)..start();
      await until(() => chat.status == ChatStatus.connected);
      api.connections.last.add({
        'type': 'error',
        'code': 'ACCOUNT_LOCKED',
        'message': 'Tài khoản bị khóa',
      });
      await until(() => api.loggedOut);
      expect(chat.status, ChatStatus.stopped);
      expect(chat.canSend, isFalse);
      expect(await chat.send('Không gửi được'), isFalse);
      expect(api.sentIds, isEmpty);
      chat.dispose();
      api.dispose();
    },
  );
}
