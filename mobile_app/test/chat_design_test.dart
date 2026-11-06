import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/chat_inbox.dart';
import 'package:tho_xay_mobile/models/chat_message.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/screens/chat_inbox_screen.dart';
import 'package:tho_xay_mobile/screens/chat_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/chat_contact.dart';
import 'package:tho_xay_mobile/theme/app_theme.dart';
import 'package:tho_xay_mobile/widgets/chat_call_sheet.dart';
import 'package:tho_xay_mobile/widgets/chat_ui.dart';
import 'package:tho_xay_mobile/widgets/private_image.dart';

import 'support/fake_chat_api.dart';

class DesignChatApi extends FakeChatApi {
  String applicationStatus = 'ACCEPTED';
  bool failContact = false, failInbox = false, contractor = false;
  Completer<List<JobApplication>>? pendingContact;
  @override
  AuthSession? get session => !contractor
      ? super.session
      : loggedOut
      ? null
      : AuthSession(
          token: 'contractor',
          userId: 2,
          fullName: 'Chủ thầu',
          phoneNumber: '0900000002',
          role: 'ROLE_CONTRACTOR',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

  JobApplication get application => JobApplication(
    id: 7,
    job: chatJob,
    workerId: 3,
    workerName: 'Anh An',
    workerPhone: '0900000003',
    workerRating: 5,
    workerVerified: true,
    workerActive: true,
    status: applicationStatus,
    agreedDailyRate: 450000,
  );
  @override
  Future<List<JobApplication>> workerApplications() async {
    if (failContact) throw const ApiException('Không tải được liên hệ');
    if (pendingContact != null) return pendingContact!.future;
    return [application];
  }

  @override
  Future<List<JobApplication>> jobApplications(int jobId) =>
      workerApplications();

  @override
  Future<ChatInbox> chatInbox({int? beforeId}) async {
    if (failInbox) throw const ApiException('Mất kết nối');
    return ChatInbox(
      [
        ChatConversation(
          job: chatJob,
          peerId: 2,
          peerName: 'Anh Minh',
          latest: message(10, content: 'Mai bắt đầu nhé'),
          unreadCount: 3,
        ),
        ChatConversation(
          job: chatJob,
          peerId: 4,
          peerName: 'Chị Lan',
          latest: ChatMessage(
            id: 9,
            senderId: 3,
            recipientId: 4,
            jobId: 1,
            content: '',
            createdAt: DateTime.now(),
            clientMessageId: 'photo',
            kind: 'IMAGE',
          ),
          unreadCount: 0,
        ),
        ChatConversation(
          job: chatJob,
          peerId: 5,
          peerName: 'Anh Bình',
          latest: ChatMessage(
            id: 8,
            senderId: 5,
            recipientId: 3,
            jobId: 1,
            content: 'Địa chỉ',
            createdAt: DateTime.now(),
            clientMessageId: 'gps',
            kind: 'LOCATION',
          ),
          unreadCount: 2,
        ),
      ],
      false,
      5,
    );
  }

  @override
  Future<Uint8List> privateImage(String path) async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
}

Future<void> openRoom(WidgetTester tester, DesignChatApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.forRole(api.session?.role),
      home: ChatScreen(api: api, job: chatJob, peerId: 2, peerName: 'Anh Minh'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [390.0, 840.0, 1440.0]) {
    testWidgets('inbox navigation adapts at 840px: $width', (tester) async {
      tester.view.physicalSize = Size(width, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = DesignChatApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forRole('ROLE_WORKER'),
          home: ChatInboxScreen(api: api),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bạn: [Hình ảnh]'), findsOneWidget);
      expect(find.text('[Vị trí GPS]'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('conversation-1:2')));
      await tester.pumpAndSettle();
      final room = tester.widget<ChatScreen>(find.byType(ChatScreen));
      expect(room.peerId, 2);
      expect(room.embedded, width >= 840);
      expect(
        find.byKey(const ValueKey('chat-split-view')),
        width >= 840 ? findsOneWidget : findsNothing,
      );
      if (width >= 840) {
        expect(find.byKey(const ValueKey('inbox-search')), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('chat-input')),
          'Bản nháp riêng',
        );
        await tester.tap(find.byKey(const ValueKey('conversation-1:4')));
        await tester.pumpAndSettle();
        expect(tester.widget<ChatScreen>(find.byType(ChatScreen)).peerId, 4);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('chat-input')))
              .controller!
              .text,
          isEmpty,
        );
        expect(api.closed, 1);
      } else {
        expect(find.byKey(const ValueKey('inbox-search')), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }

  testWidgets(
    'search and unread filters combine and preserve conversations offline',
    (tester) async {
      final api = DesignChatApi();
      await tester.pumpWidget(MaterialApp(home: ChatInboxScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chưa đọc'));
      await tester.pumpAndSettle();
      expect(find.text('Chị Lan'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('inbox-search')),
        'bình',
      );
      await tester.pumpAndSettle();
      expect(find.text('Anh Bình'), findsOneWidget);
      expect(find.text('Anh Minh'), findsNothing);
      api.failInbox = true;
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.text('Anh Bình'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('inbox-search')),
        'không tồn tại',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Chị Lan'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('inbox-search')),
        'Công trình A',
      );
      await tester.pumpAndSettle();
      expect(find.text('Anh Minh'), findsOneWidget);
      expect(find.text('Anh Bình'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets(
    'quick replies prepare drafts, messages show receipts only from peer cursor',
    (tester) async {
      final api = DesignChatApi();
      final outgoing = message(4, sender: 3, content: 'Tin của tôi');
      api.initialHistory = Completer<MessagePage>()
        ..complete(MessagePage([outgoing], false));
      await openRoom(tester, api);
      expect(find.textContaining('· Đã gửi'), findsOneWidget);
      expect(find.textContaining('Đã xem'), findsNothing);
      expect(
        api.readIds,
        contains(4),
      ); // Our read cursor must never imply the peer read it.
      await tester.tap(find.text('Tôi đang tới công trình'));
      await tester.pumpAndSettle();
      expect(api.sentIds, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-input')))
            .controller!
            .text,
        'Tôi đang tới công trình',
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();

      final confirmed = DesignChatApi();
      confirmed.initialHistory = Completer<MessagePage>()
        ..complete(MessagePage([outgoing], false, peerLastReadMessageId: 4));
      await openRoom(tester, confirmed);
      expect(find.textContaining('Đã xem'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      confirmed.dispose();
    },
  );

  for (final contractor in [false, true]) {
    testWidgets(
      'bubble colors, date labels and payload actions: contractor=$contractor',
      (tester) async {
        final api = DesignChatApi()..contractor = contractor;
        final photo = ChatMessage(
          id: 3,
          senderId: 3,
          recipientId: 2,
          jobId: 1,
          content: 'Ảnh nghiệm thu',
          createdAt: DateTime.now(),
          clientMessageId: 'p',
          kind: 'IMAGE',
          imagePath: '/api/jobs/1/messages/3/photo',
        );
        final gps = ChatMessage(
          id: 4,
          senderId: 2,
          recipientId: 3,
          jobId: 1,
          content: 'Vị trí công trường',
          createdAt: DateTime.now(),
          clientMessageId: 'l',
          kind: 'LOCATION',
          latitude: 16.46,
          longitude: 107.59,
        );
        String? coordinates;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ChatDayDivider(date: DateTime.now()),
                    ChatDayDivider(
                      date: DateTime.now().subtract(const Duration(days: 1)),
                    ),
                    ChatMessageBubble(
                      api: api,
                      message: photo,
                      mine: true,
                      peerName: 'Minh',
                      onLocation: (_, _) {},
                    ),
                    ChatMessageBubble(
                      api: api,
                      message: gps,
                      mine: false,
                      peerName: 'Minh',
                      onLocation: (lat, lng) => coordinates = '$lat,$lng',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hôm nay'), findsOneWidget);
        expect(find.text('Hôm qua'), findsOneWidget);
        final container = tester.widget<Container>(
          find.byKey(const ValueKey('message-3')),
        );
        expect(
          (container.decoration! as BoxDecoration).color,
          contractor ? const Color(0xFF059669) : const Color(0xFFEA580C),
        );
        await tester.tap(find.bySemanticsLabel('Phóng to ảnh công trường'));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        expect(find.byType(PrivateImage), findsNWidgets(2));
        await tester.tap(find.byTooltip('Đóng ảnh'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Mở vị trí trên bản đồ'));
        await tester.tap(find.text('Mở vị trí trên bản đồ'));
        expect(coordinates, '16.46,107.59');
        await tester.pumpWidget(const SizedBox());
        api.dispose();
      },
    );
  }

  for (final status in ['PENDING', 'REJECTED', 'CANCELLED']) {
    testWidgets('call requires fresh accepted application: $status', (
      tester,
    ) async {
      final api = DesignChatApi()..applicationStatus = status;
      await openRoom(tester, api);
      await tester.tap(find.byTooltip('Gọi điện'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatCallSheet), findsNothing);
      expect(find.textContaining('Chỉ gọi điện khi đơn'), findsOneWidget);
      expect(api.sentIds, isEmpty);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    });
  }

  testWidgets(
    'call sheet copies number and opens exact tel URI without inventing a call log',
    (tester) async {
      final api = DesignChatApi();
      Uri? called;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showChatCallSheet(
                    context,
                    api: api,
                    job: chatJob,
                    peerId: 2,
                    peerName: 'Anh Minh',
                    launcher: (uri) async {
                      called = uri;
                      return true;
                    },
                  ),
                  child: const Text('Liên hệ'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Liên hệ'));
      await tester.pumpAndSettle();
      expect(find.text('0900000002'), findsOneWidget);
      await tester.tap(find.text('Sao chép số'));
      await tester.pumpAndSettle();
      expect(copied, '0900000002');
      await tester.ensureVisible(find.text('Gọi qua SIM'));
      await tester.tap(find.text('Gọi qua SIM'));
      await tester.pumpAndSettle();
      expect(called.toString(), 'tel:0900000002');
      expect(api.sentIds, isEmpty);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets('simulated call timer, mic/speaker and idempotent log retry', (
    tester,
  ) async {
    final api = DesignChatApi()..failSendOnce = true;
    await openRoom(tester, api);
    expect(find.textContaining('450.000'), findsOneWidget);
    await tester.tap(find.byTooltip('Gọi điện'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gọi trực tiếp trên App (mô phỏng)'));
    await tester.tap(find.text('Gọi trực tiếp trên App (mô phỏng)'));
    await tester.pump();
    expect(find.text('Đang kết nối… (mô phỏng)'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Đang gọi · 00:01'), findsOneWidget);
    await tester.tap(find.byTooltip('Tắt mic (mô phỏng)'));
    await tester.tap(find.byTooltip('Bật loa ngoài (mô phỏng)'));
    await tester.pump();
    expect(find.byTooltip('Bật mic (mô phỏng)'), findsOneWidget);
    expect(find.byTooltip('Tắt loa ngoài (mô phỏng)'), findsOneWidget);
    await tester.tap(find.byTooltip('Kết thúc cuộc gọi'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi lại nhật ký'), findsOneWidget);
    await tester.tap(find.text('Gửi lại nhật ký'));
    await tester.pumpAndSettle();
    expect(api.sentIds.length, 2);
    expect(api.sentIds.first, api.sentIds.last);
    expect(api.rows.where((m) => m.content == simulatedCallLog), hasLength(1));
    await tester.tap(find.byTooltip('Đóng gọi điện'));
    await tester.pumpAndSettle();
    expect(find.text(simulatedCallLog), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'cancel during connection and disposal release timers without logging a completed call',
    (tester) async {
      final api = DesignChatApi();
      await openRoom(tester, api);
      await tester.tap(find.byTooltip('Gọi điện'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Gọi trực tiếp trên App (mô phỏng)'),
      );
      await tester.tap(find.text('Gọi trực tiếp trên App (mô phỏng)'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byTooltip('Kết thúc cuộc gọi'));
      await tester.pumpAndSettle();
      expect(api.sentIds, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
      api.dispose();
    },
  );

  testWidgets('narrow room and active call close safely on logout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = DesignChatApi();
    await openRoom(tester, api);
    await tester.tap(find.byTooltip('Gọi điện'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gọi trực tiếp trên App (mô phỏng)'));
    await tester.tap(find.text('Gọi trực tiếp trên App (mô phỏng)'));
    await tester.pump(const Duration(milliseconds: 1200));
    await api.logout();
    await tester.pumpAndSettle();
    expect(find.byType(ChatCallSheet), findsNothing);
    expect(api.sentIds, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    api.dispose();
  });

  testWidgets(
    'call logging preserves an unconfirmed text draft and its retry key',
    (tester) async {
      final api = DesignChatApi()..failSendOnce = true;
      await openRoom(tester, api);
      await tester.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Giữ lại bản nháp',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      final textKey = api.sentIds.single;
      await tester.tap(find.byTooltip('Gọi điện'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Gọi trực tiếp trên App (mô phỏng)'),
      );
      await tester.tap(find.text('Gọi trực tiếp trên App (mô phỏng)'));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.tap(find.byTooltip('Kết thúc cuộc gọi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đóng gọi điện'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-input')))
            .controller!
            .text,
        'Giữ lại bản nháp',
      );
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pumpAndSettle();
      expect(api.sentIds.last, textKey);
      expect(
        api.rows.where((m) => m.content == 'Giữ lại bản nháp'),
        hasLength(1),
      );
      expect(
        api.rows.where((m) => m.content == simulatedCallLog),
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  test('contact never leaks across a logout or to an unrelated peer', () async {
    final api = DesignChatApi();
    expect(await loadChatContact(api, chatJob, 99), isNull);
    api.pendingContact = Completer<List<JobApplication>>();
    final loading = loadChatContact(api, chatJob, 2);
    await api.logout();
    api.pendingContact!.complete([api.application]);
    expect(await loading, isNull);
    api.dispose();
  });
}
