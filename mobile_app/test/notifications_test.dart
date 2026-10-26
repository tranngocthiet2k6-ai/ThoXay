import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/app_notification.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/notifications_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/push_notifications.dart';

class InboxApi extends ApiService {
  bool read = false;
  int pages = 0;
  @override
  AuthSession? get session => AuthSession(
    token: 'test',
    userId: 3,
    fullName: 'A',
    phoneNumber: '0900000003',
    role: 'ROLE_WORKER',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );
  AppNotification item(int id) => AppNotification(
    id: id,
    type: 'APPLICATION_ACCEPTED',
    title: 'Đơn được duyệt $id',
    body: 'Mở công trình để liên hệ.',
    createdAt: DateTime.utc(2026, 10, 26),
    readAt: read ? DateTime.now() : null,
  );
  @override
  Future<NotificationPage> notifications({int? beforeId}) async {
    pages++;
    return NotificationPage(
      [item(beforeId == null ? 2 : 1)],
      beforeId == null,
      read ? 0 : 2,
    );
  }

  @override
  Future<void> readAllNotifications() async {
    read = true;
  }

  @override
  Future<void> readNotification(int id) async {
    read = true;
  }
}

class FakePush implements PushClient {
  final updates = StreamController<void>.broadcast();
  @override
  bool get configured => false;
  @override
  Stream<void> get changes => updates.stream;
  @override
  Future<String> enable(ApiService api) async =>
      'Bạn vẫn xem được lịch sử bên dưới.';
}

void main() {
  testWidgets(
    'history paginates, marks read and handles missing push configuration honestly',
    (tester) async {
      final api = InboxApi();
      final push = FakePush();
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(api: api, push: push),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử · 2 chưa đọc'), findsOneWidget);
      await tester.tap(find.text('Tải thông báo cũ'));
      await tester.pumpAndSettle();
      expect(find.text('Đơn được duyệt 1'), findsOneWidget);
      await tester.tap(find.text('Đọc tất cả'));
      await tester.pumpAndSettle();
      expect(api.read, isTrue);
      expect(find.text('Lịch sử · 0 chưa đọc'), findsOneWidget);
      await tester.tap(find.text('Bật thông báo đẩy'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn vẫn xem được lịch sử bên dưới.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await push.updates.close();
      api.dispose();
    },
  );
  testWidgets(
    'foreground push refreshes inbox and the listener is removed on close',
    (tester) async {
      final api = InboxApi();
      final push = FakePush();
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(api: api, push: push),
        ),
      );
      await tester.pumpAndSettle();
      final first = api.pages;
      push.updates.add(null);
      await tester.pumpAndSettle();
      expect(api.pages, first + 1);
      await tester.pumpWidget(const SizedBox());
      push.updates.add(null);
      await tester.pumpAndSettle();
      expect(api.pages, first + 1);
      await push.updates.close();
      api.dispose();
    },
  );
}
