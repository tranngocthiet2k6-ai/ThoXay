import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundNotification(RemoteMessage message) async {
  await Firebase.initializeApp();
  // The OS displays the notification. History remains authoritative on the server.
}

abstract class PushClient {
  bool get configured;
  Stream<void> get changes;
  Future<String> enable(ApiService api);
}

class PushNotifications implements PushClient {
  PushNotifications._();
  static final instance = PushNotifications._();
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  bool configured = false;
  String? _deviceToken;
  ApiService? _api;
  int _generation = 0;
  String? _sessionToken;
  String? _pendingRecipient;
  int _registrations = 0;
  VoidCallback? onOpen;
  void Function(String)? onForeground;

  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      await Firebase.initializeApp();
      configured = true;
      FirebaseMessaging.onBackgroundMessage(backgroundNotification);
      FirebaseMessaging.onMessage.listen((message) {
        if (message.data['userId'] != _api?.session?.userId.toString()) return;
        _changes.add(null);
        onForeground?.call(
          message.notification?.title ?? 'Bạn có thông báo mới',
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (message.data['userId'] != _api?.session?.userId.toString()) return;
        _changes.add(null);
        onOpen?.call();
      });
      FirebaseMessaging.instance.onRegistered.listen((token) async {
        if (_registrations > 0) return;
        final api = _api;
        final generation = _generation;
        if (api?.session == null) return;
        try {
          final old = _deviceToken;
          if (old != null && old != token) await api!.unregisterDevice(old);
          if (generation != _generation || api!.session == null) return;
          await api.registerDevice(token);
          if (generation == _generation) _deviceToken = token;
        } on Object {
          /* A restored session or enable action retries registration. */
        }
      });
      FirebaseMessaging.instance.onUnregistered.listen((fid) async {
        final api = _api;
        if (api?.session == null) return;
        try {
          await api!.unregisterDevice(fid);
        } on Object {
          /* Server prunes stale registrations. */
        }
      });
      _pendingRecipient =
          (await FirebaseMessaging.instance.getInitialMessage())?.data['userId']
              as String?;
    } on Object {
      configured = false;
    }
  }

  void attach(ApiService api) {
    _api = api;
    api.beforeLogout = () async {
      ++_generation;
      final token = _deviceToken;
      _deviceToken = null;
      if (configured) {
        try {
          await FirebaseMessaging.instance.setAutoInitEnabled(false);
          await FirebaseMessaging.instance.unregister();
        } on Object {
          /* Keep logout available when the device is offline. */
        }
      }
      if (token != null) {
        try {
          await api.unregisterDevice(token);
        } on Object {
          /* Native unregistration also stops future device delivery. */
        }
      }
    };
    api.addListener(() {
      if (_sessionToken == api.session?.token) return;
      _sessionToken = api.session?.token;
      ++_generation;
      if (api.session != null && configured) {
        unawaited(
          _sync(api, requestPermission: false).catchError((Object _) => ''),
        );
      }
    });
    _sessionToken = api.session?.token;
    if (api.session != null && configured) {
      unawaited(
        _sync(api, requestPermission: false).catchError((Object _) => ''),
      );
    }
  }

  void openInitialIfNeeded() {
    if (_pendingRecipient != null &&
        _pendingRecipient == _api?.session?.userId.toString()) {
      _pendingRecipient = null;
      onOpen?.call();
    }
  }

  @override
  Future<String> enable(ApiService api) async {
    if (!configured) {
      return 'Thông báo đẩy chưa sẵn sàng trên thiết bị này. Bạn vẫn xem được lịch sử bên dưới.';
    }
    try {
      return await _sync(api, requestPermission: true);
    } on Object {
      return 'Chưa bật được thông báo đẩy. Kiểm tra mạng và thử lại.';
    }
  }

  Future<String> _sync(
    ApiService api, {
    required bool requestPermission,
  }) async {
    final generation = _generation;
    final messaging = FirebaseMessaging.instance;
    final settings = requestPermission
        ? await messaging.requestPermission()
        : await messaging.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return 'Bạn chưa cấp quyền thông báo. Có thể bật quyền trong cài đặt của điện thoại.';
    }
    if (generation != _generation || api.session == null) {
      return 'Vui lòng đăng nhập lại.';
    }
    ++_registrations;
    try {
      final registration = messaging.onRegistered.first.timeout(
        const Duration(seconds: 12),
      );
      // Attach an error handler immediately if the native registration itself fails first.
      unawaited(registration.catchError((Object _) => ''));
      await messaging.setAutoInitEnabled(true);
      await messaging.register();
      final fid = await registration;
      if (generation != _generation || api.session == null) {
        return 'Vui lòng đăng nhập lại.';
      }
      await api.registerDevice(fid);
      if (generation == _generation) _deviceToken = fid;
      return 'Đã bật thông báo đẩy cho tài khoản này.';
    } finally {
      --_registrations;
    }
  }
}
