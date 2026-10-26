import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';
import '../models/chat_message.dart';
import '../models/app_notification.dart';
import '../models/worker_profile.dart';
import '../models/reputation.dart';
import '../models/wallet.dart';
import 'chat_connection.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService extends ChangeNotifier {
  Future<WalletBalance> wallet() async => WalletBalance.fromJson(
    await _request('GET', '/api/wallet') as Map<String, dynamic>,
  );
  Future<WalletPage<WalletEntry>> walletEntries({int? beforeId}) async {
    final j = await _request(
      'GET',
      '/api/wallet/transactions${beforeId == null ? '' : '?beforeId=$beforeId'}',
    ) as Map<String, dynamic>;
    return WalletPage(
      (j['items'] as List)
          .map((e) => WalletEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      j['hasMore'] as bool,
    );
  }

  Future<WalletPage<WalletRequest>> walletRequests({int? beforeId}) async {
    final j = await _request(
      'GET',
      '/api/wallet/requests${beforeId == null ? '' : '?beforeId=$beforeId'}',
    ) as Map<String, dynamic>;
    return WalletPage(
      (j['items'] as List)
          .map((e) => WalletRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      j['hasMore'] as bool,
    );
  }

  Future<void> createWalletRequest(Map<String, dynamic> input) async {
    await _request('POST', '/api/wallet/requests', body: input);
  }

  Future<void> transferEscrow(Map<String, dynamic> input) async {
    await _request('POST', '/api/wallet/escrow', body: input);
  }

  Future<Earnings> earnings(
    String period,
    DateTime date,
  ) async => Earnings.fromJson(
    await _request(
      'GET',
      '/api/wallet/earnings?period=$period&date=${date.toIso8601String().split('T').first}',
    ) as Map<String, dynamic>,
  );
  Future<List<JobPayment>> jobPayments(int id) async =>
      (await _request('GET', '/api/wallet/jobs/$id/payments') as List)
          .map((e) => JobPayment.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<JobPayment> payWorker(Map<String, dynamic> input) async =>
      JobPayment.fromJson(
        await _request('POST', '/api/wallet/job-payments', body: input)
            as Map<String, dynamic>,
      );
  Future<bool> availability() async =>
      (await _request('GET', '/api/users/me/availability')
              as Map<String, dynamic>)['available']
          as bool;
  Future<bool> setAvailability(bool available) async =>
      (await _request(
            'PUT',
            '/api/users/me/availability',
            body: {'available': available},
          ) as Map<String, dynamic>)['available']
          as bool;
  Future<JobApplication> cancelApplication(int id, String reason) async =>
      JobApplication.fromJson(
        await _request(
          'PUT',
          '/api/applications/$id/cancel',
          body: {'reason': reason},
        ) as Map<String, dynamic>,
      );
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/+$'), '');
  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.16:8080',
  );
  static const _storageKey = 'thoxay.session';
  final http.Client _client;
  final String baseUrl;
  Future<void> Function()? beforeLogout;
  bool _loggingOut = false;
  AuthSession? _session;
  AuthSession? get session => _session;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) return;
    try {
      final restored = AuthSession.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
      if (restored.expiresAt.isAfter(DateTime.now())) {
        _session = restored;
      } else {
        await prefs.remove(_storageKey);
      }
    } on Object {
      await prefs.remove(_storageKey);
    }
    notifyListeners();
  }

  Future<void> login(String phoneNumber, String password) async {
    await _authenticate('/api/auth/login', {
      'phoneNumber': phoneNumber,
      'password': password,
    });
  }

  Future<void> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String role,
    String? cccdFrontImage,
    String? cccdBackImage,
  }) async {
    await _authenticate('/api/auth/register', {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
      'cccdFrontImage': cccdFrontImage,
      'cccdBackImage': cccdBackImage,
    });
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    final result = await _request(
      'POST',
      path,
      body: body,
      authenticated: false,
    );
    final value = AuthSession.fromJson(result as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(value.toJson()));
    _session = value;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      await beforeLogout?.call().timeout(const Duration(seconds: 6));
    } on Object {
      /* Logout must remain available offline. */
    }
    try {
      _session = null;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } finally {
      _loggingOut = false;
    }
  }

  Future<NotificationPage> notifications({int? beforeId}) async {
    final data = await _request(
      'GET',
      '/api/notifications${beforeId == null ? '' : '?beforeId=$beforeId'}',
    ) as Map<String, dynamic>;
    return NotificationPage(
      (data['items'] as List)
          .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
          .toList(),
      data['hasMore'] as bool,
      (data['unreadCount'] as num).toInt(),
    );
  }

  Future<void> readNotification(int id) async {
    await _request('PUT', '/api/notifications/$id/read');
  }

  Future<void> readAllNotifications() async {
    await _request('PUT', '/api/notifications/read-all');
  }

  Future<void> registerDevice(String token) async {
    await _request('PUT', '/api/notifications/devices', body: {'token': token});
  }

  Future<void> unregisterDevice(String token) async {
    await _request(
      'POST',
      '/api/notifications/devices/unregister',
      body: {'token': token},
    );
  }

  Future<List<Job>> nearby(
    double lat,
    double lng,
    double radius, {
    String? jobType,
    String sort = 'DISTANCE',
  }) async => _jobs(
    await _request(
      'GET',
      '/api/jobs/nearby?${Uri(queryParameters: {'lat': '$lat', 'lng': '$lng', 'radius': '$radius', 'sort': sort, if (jobType != null && jobType.isNotEmpty) 'jobType': jobType}).query}',
    ),
  );
  Future<List<Job>> contractorJobs() async => _jobs(
    await _request('GET', '/api/jobs/contractor/${_requireSession().userId}'),
  );
  Future<Job> createJob(Map<String, dynamic> body) async => Job.fromJson(
    await _request('POST', '/api/jobs', body: body) as Map<String, dynamic>,
  );
  Future<UserProfile> profile() async => UserProfile.fromJson(
    await _request('GET', '/api/users/me') as Map<String, dynamic>,
  );
  Future<UserProfile> updateProfile({
    required String fullName,
    String? dateOfBirth,
    required int experienceYears,
    required String experienceSummary,
    required List<String> skills,
    required List<String> projectImages,
  }) async {
    final person = UserProfile.fromJson(
      await _request(
        'PUT',
        '/api/users/me',
        body: {
          'fullName': fullName,
          'dateOfBirth': dateOfBirth,
          'experienceYears': experienceYears,
          'experienceSummary': experienceSummary,
          'skills': skills,
          'projectImages': projectImages,
        },
      ) as Map<String, dynamic>,
    );
    final old = _session;
    if (old != null && old.userId == person.id) {
      final updated = AuthSession(
        token: old.token,
        userId: old.userId,
        fullName: person.fullName,
        phoneNumber: old.phoneNumber,
        role: old.role,
        expiresAt: old.expiresAt,
      );
      _session = updated;
      final prefs = await SharedPreferences.getInstance();
      if (identical(_session, updated)) {
        await prefs.setString(_storageKey, jsonEncode(updated.toJson()));
        notifyListeners();
      }
    }
    return person;
  }

  Future<WorkerProfile> workerProfile(int workerId) async =>
      WorkerProfile.fromJson(
        await _request('GET', '/api/workers/$workerId/profile')
            as Map<String, dynamic>,
      );
  Future<List<WorkerRank>> leaderboard() async =>
      (await _request('GET', '/api/workers/leaderboard') as List)
          .map((j) => WorkerRank.fromJson(j as Map<String, dynamic>))
          .toList();
  Future<ReviewPage> workerReviews(int id, {int? beforeId}) async {
    final j = await _request(
      'GET',
      '/api/workers/$id/reviews${beforeId == null ? '' : '?beforeId=$beforeId'}',
    ) as Map<String, dynamic>;
    return ReviewPage(
      (j['items'] as List)
          .map((r) => WorkerReview.fromJson(r as Map<String, dynamic>))
          .toList(),
      j['hasMore'] as bool,
    );
  }

  Future<ReputationPage> reputationHistory({int? beforeId}) async {
    final j = await _request(
      'GET',
      '/api/users/me/reputation${beforeId == null ? '' : '?beforeId=$beforeId'}',
    ) as Map<String, dynamic>;
    return ReputationPage(
      (j['items'] as List)
          .map((r) => ReputationEntry.fromJson(r as Map<String, dynamic>))
          .toList(),
      j['hasMore'] as bool,
    );
  }

  Future<MessagePage> messageHistory(
    int jobId,
    int peerId, {
    int? afterId,
    int? beforeId,
  }) async {
    final query = Uri(
      queryParameters: {
        'peerId': '$peerId',
        if (afterId != null) 'afterId': '$afterId',
        if (beforeId != null) 'beforeId': '$beforeId',
      },
    ).query;
    final data = await _request(
      'GET',
      '/api/jobs/$jobId/messages?$query',
    ) as Map<String, dynamic>;
    return MessagePage(
      (data['messages'] as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      data['hasMore'] as bool,
    );
  }

  Future<ChatMessage> sendMessage(
    int jobId,
    int recipientId,
    String content,
    String clientMessageId,
  ) async => ChatMessage.fromJson(
    await _request(
      'POST',
      '/api/jobs/$jobId/messages',
      body: {
        'recipientId': recipientId,
        'content': content,
        'clientMessageId': clientMessageId,
      },
    ) as Map<String, dynamic>,
  );

  Future<ChatConnection> connectChat(int jobId, int peerId) async {
    final auth = _requireSession();
    if (!auth.expiresAt.isAfter(DateTime.now())) {
      await logout();
      throw const ApiException('Phiên đăng nhập đã hết hạn', 401);
    }
    final base = Uri.parse(baseUrl);
    final socket = WebSocketChannel.connect(
      base.replace(
        scheme: base.scheme == 'https' ? 'wss' : 'ws',
        path: '${base.path}/ws/chat',
        query: null,
        fragment: null,
      ),
    );
    try {
      await socket.ready.timeout(const Duration(seconds: 10));
      // Send credentials as a frame, never in the URL or access logs. Works on Web and Android.
      socket.sink.add(
        jsonEncode({
          'type': 'subscribe',
          'token': auth.token,
          'jobId': jobId,
          'peerId': peerId,
        }),
      );
      return ChatConnection(
        events: socket.stream.map(
          (value) => jsonDecode(value as String) as Map<String, dynamic>,
        ),
        close: () async {
          await socket.sink.close();
        },
      );
    } on Object {
      unawaited(socket.sink.close().catchError((Object _) {}));
      throw const ApiException('Không kết nối được máy chủ nhắn tin');
    }
  }

  Future<UserProfile> updateCccd(
    String frontImageUrl,
    String backImageUrl,
  ) async => UserProfile.fromJson(
    await _request(
      'PUT',
      '/api/users/me/cccd',
      body: {'cccdFrontImage': frontImageUrl, 'cccdBackImage': backImageUrl},
    ) as Map<String, dynamic>,
  );
  Future<Job> completeJob(int jobId, Map<int, int> ratings) async =>
      Job.fromJson(
        await _request(
          'PUT',
          '/api/jobs/$jobId/complete',
          body: {
            'ratings': ratings.entries
                .map((entry) => {'workerId': entry.key, 'stars': entry.value})
                .toList(),
          },
        ) as Map<String, dynamic>,
      );
  Future<JobApplication> apply(int jobId) async => JobApplication.fromJson(
    await _request('POST', '/api/applications/apply', body: {'jobId': jobId})
        as Map<String, dynamic>,
  );
  Future<List<JobApplication>> workerApplications() async => _applications(
    await _request(
      'GET',
      '/api/applications/worker/${_requireSession().userId}',
    ),
  );
  Future<List<JobApplication>> jobApplications(int jobId) async =>
      _applications(await _request('GET', '/api/applications/job/$jobId'));
  Future<JobApplication> updateApplication(int id, String status) async =>
      JobApplication.fromJson(
        await _request(
          'PUT',
          '/api/applications/$id/status',
          body: {'status': status},
        ) as Map<String, dynamic>,
      );
  List<Job> _jobs(Object? data) => (data as List)
      .map((j) => Job.fromJson(j as Map<String, dynamic>))
      .toList();
  List<JobApplication> _applications(Object? data) => (data as List)
      .map((a) => JobApplication.fromJson(a as Map<String, dynamic>))
      .toList();
  AuthSession _requireSession() {
    final value = _session;
    if (value == null) throw const ApiException('Vui lòng đăng nhập lại', 401);
    return value;
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (authenticated) {
      final value = _requireSession();
      if (!value.expiresAt.isAfter(DateTime.now())) {
        await logout();
        throw const ApiException('Phiên đăng nhập đã hết hạn', 401);
      }
      headers['Authorization'] = 'Bearer ${value.token}';
    }
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      Object? data;
      try {
        data = response.bodyBytes.isEmpty
            ? null
            : jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ApiException('Máy chủ trả về dữ liệu không hợp lệ');
      }
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      if (authenticated &&
          (response.statusCode == 401 ||
              (response.statusCode == 403 &&
                  data is Map &&
                  data['code'] == 'ACCOUNT_LOCKED'))) {
        await logout();
      }
      throw ApiException(
        data is Map && data['message'] is String
            ? data['message'] as String
            : 'Không thể thực hiện yêu cầu (${response.statusCode})',
        response.statusCode,
      );
    } on TimeoutException {
      throw const ApiException('Kết nối quá thời gian. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiException(
        'Không kết nối được máy chủ. Kiểm tra mạng và địa chỉ API.',
      );
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
