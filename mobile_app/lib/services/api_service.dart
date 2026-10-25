import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';
import '../models/chat_message.dart';
import 'chat_connection.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService extends ChangeNotifier {
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
    _session = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
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
