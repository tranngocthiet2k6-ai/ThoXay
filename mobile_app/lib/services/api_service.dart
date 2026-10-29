import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';
import '../models/chat_message.dart';
import '../models/chat_inbox.dart';
import '../models/weather.dart';
import '../models/app_notification.dart';
import '../models/worker_profile.dart';
import '../models/reputation.dart';
import '../models/wallet.dart';
import '../models/scheduling.dart';
import '../models/crew.dart';
import '../models/portfolio_photo.dart';
import '../models/attendance.dart';
import '../models/deposit.dart';
import '../models/incident.dart';
import 'location_service.dart';
import 'chat_connection.dart';
import 'kyc_camera.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService extends ChangeNotifier {
  Future<AreaWeather> weather(double latitude, double longitude) async {
    final data = await _request(
      'GET',
      '/api/weather?latitude=$latitude&longitude=$longitude',
    );
    try {
      return AreaWeather.fromJson(data as Map<String, dynamic>);
    } on Object {
      throw const ApiException('Chưa lấy được thời tiết khu vực');
    }
  }

  Future<IncidentDetail> reportIncident(
    int jobId,
    Map<String, dynamic> body,
  ) async => IncidentDetail.fromJson(
    await _request('POST', '/api/jobs/$jobId/incidents', body: body)
        as Map<String, dynamic>,
  );
  Future<IncidentDetail> incident(int id) async => IncidentDetail.fromJson(
    await _request('GET', '/api/incidents/$id') as Map<String, dynamic>,
  );
  Future<IncidentPage> myIncidents({
    int? jobId,
    int? beforeId,
  }) async => IncidentPage.fromJson(
    await _request(
      'GET',
      '/api/incidents/me?${Uri(queryParameters: {if (jobId != null) 'jobId': '$jobId', if (beforeId != null) 'beforeId': '$beforeId'}).query}',
    ) as Map<String, dynamic>,
  );

  Future<Deposit> createDeposit(int amount, String clientRequestId) async =>
      Deposit.fromJson(
        await _request(
          'POST',
          '/api/wallet/deposits',
          body: {'amount': amount, 'clientRequestId': clientRequestId},
        ) as Map<String, dynamic>,
      );
  Future<Deposit> deposit(int id) async => Deposit.fromJson(
    await _request('GET', '/api/wallet/deposits/$id') as Map<String, dynamic>,
  );

  Future<AttendancePage> attendance(
    int id, {
    DateTime? beforeDay,
  }) async => AttendancePage.fromJson(
    await _request(
      'GET',
      '/api/applications/$id/attendance${beforeDay == null ? '' : '?beforeDay=${isoDay(beforeDay)}'}',
    ) as Map<String, dynamic>,
  );
  Future<AttendancePage> jobAttendance(
    int id,
    DateTime day, {
    int page = 0,
  }) async => AttendancePage.fromJson(
    await _request(
      'GET',
      '/api/jobs/$id/attendance?day=${isoDay(day)}&page=$page',
    ) as Map<String, dynamic>,
  );
  Future<ShiftCode> shiftCode(int jobId) async => ShiftCode.fromJson(
    await _request('POST', '/api/jobs/$jobId/attendance/shift-code')
        as Map<String, dynamic>,
  );
  Future<AttendancePage> markAttendance(
    int id,
    bool checkout, {
    GeoPoint? position,
    String? qrToken,
  }) async => AttendancePage.fromJson(
    await _request(
      'POST',
      '/api/applications/$id/attendance/${checkout ? 'check-out' : 'check-in'}',
      body: {
        if (position != null) 'latitude': position.latitude,
        if (position != null) 'longitude': position.longitude,
        if (position != null) 'accuracyMeters': position.accuracyMeters,
        'qrToken': ?qrToken,
      },
    ) as Map<String, dynamic>,
  );
  Future<AttendancePage> uploadWorkLog(
    int id,
    DateTime day,
    Uint8List bytes,
    String caption,
  ) async => AttendancePage.fromJson(
    await uploadPhoto(
      '/api/applications/$id/work-logs',
      bytes,
      fields: {'day': isoDay(day), 'caption': caption},
    ),
  );
  Future<void> reviewWorkLog(
    int id,
    int version,
    bool approved,
    String feedback,
  ) async {
    await _request(
      'PUT',
      '/api/work-logs/$id/review',
      body: {'approved': approved, 'feedback': feedback, 'version': version},
    );
  }

  Future<List<PortfolioPhoto>> portfolio(int userId) async =>
      (await _request('GET', '/api/users/$userId/portfolio') as List)
          .map((e) => PortfolioPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<void> deletePortfolio(String id) async {
    await _request('DELETE', '/api/users/me/portfolio/$id');
  }

  Future<PortfolioPhoto> uploadPortfolio(
    Uint8List bytes,
    String caption,
  ) async => PortfolioPhoto.fromJson(
    await uploadPhoto(
      '/api/users/me/portfolio',
      bytes,
      fields: {'caption': caption},
    ),
  );
  Future<Map<String, dynamic>> uploadPhoto(
    String path,
    Uint8List bytes, {
    Map<String, String> fields = const {},
  }) async {
    if (!path.startsWith('/api/') || path.contains('://')) {
      throw const ApiException('Đường dẫn tải ảnh không hợp lệ');
    }
    final auth = _requireSession();
    if (!auth.expiresAt.isAfter(DateTime.now())) {
      await logout();
      throw const ApiException('Phiên đăng nhập đã hết hạn', 401);
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const ApiException('Mỗi ảnh tối đa 5 MB');
    }
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer ${auth.token}'
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: 'photo.jpg'),
      );
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 401 ||
          (response.statusCode == 403 &&
              data is Map &&
              data['code'] == 'ACCOUNT_LOCKED')) {
        await logout();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Không tải được ảnh',
          response.statusCode,
        );
      }
      if (data is! Map<String, dynamic>) throw const FormatException();
      return data;
    } on FormatException {
      throw const ApiException('Máy chủ trả về dữ liệu không hợp lệ');
    } on TimeoutException {
      throw const ApiException('Tải ảnh quá thời gian. Hãy thử lại.');
    } on http.ClientException {
      throw const ApiException('Không kết nối được máy chủ tải ảnh');
    }
  }

  Future<Uint8List> privateImage(String path) async {
    if (!path.startsWith('/api/') || path.contains('://')) {
      throw const ApiException('Đường dẫn ảnh không hợp lệ');
    }
    final auth = _requireSession();
    if (!auth.expiresAt.isAfter(DateTime.now())) {
      await logout();
      throw const ApiException('Phiên đăng nhập đã hết hạn', 401);
    }
    try {
      final request = http.Request('GET', Uri.parse('$baseUrl$path'))
        ..followRedirects = false
        ..headers['Authorization'] = 'Bearer ${auth.token}';
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 &&
          response.headers['content-type']?.startsWith('image/') == true) {
        return response.bodyBytes;
      }
      if (response.statusCode == 401) await logout();
      if (response.statusCode == 403) {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is Map && data['code'] == 'ACCOUNT_LOCKED') await logout();
        } on FormatException {
          /* Use generic image error. */
        }
      }
      throw ApiException(
        'Không có quyền xem ảnh hoặc ảnh không còn tồn tại',
        response.statusCode,
      );
    } on TimeoutException {
      throw const ApiException('Tải ảnh quá thời gian');
    } on http.ClientException {
      throw const ApiException('Không tải được ảnh. Kiểm tra kết nối mạng.');
    }
  }

  Future<List<Crew>> crews() async =>
      (await _request('GET', '/api/crews') as List)
          .map((e) => Crew.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<void> createCrew(String name) async {
    await _request('POST', '/api/crews', body: {'name': name});
  }

  Future<void> inviteCrew(int id, String phone) async {
    await _request(
      'POST',
      '/api/crews/$id/invitations',
      body: {'phoneNumber': phone},
    );
  }

  Future<void> crewMembership(int id, bool accepted) async {
    await _request(
      'PUT',
      '/api/crews/$id/membership',
      body: {'accepted': accepted},
    );
  }

  Future<void> crewApply(int id, int jobId, WorkProposal p) async {
    await _request(
      'POST',
      '/api/crews/$id/applications',
      body: {
        'jobId': jobId,
        'proposedDailyRate': p.rate,
        'wageNote': p.note,
        'acceptedTerms': true,
        'termsVersion': p.version,
      },
    );
  }

  Future<void> crewDecision(
    int id,
    String status, {
    int? version,
    bool acceptOffer = false,
  }) async {
    await _request(
      'PUT',
      '/api/crew-applications/$id/status',
      body: {
        'status': status,
        'termsVersion': version,
        'acceptedTerms': status == 'ACCEPTED',
        'acceptCounterOffer': acceptOffer,
      },
    );
  }

  Future<void> withdrawCrew(int id) async {
    await _request('DELETE', '/api/crew-applications/$id/participation');
  }

  Future<List<Job>> savedJobs() async =>
      (await _request('GET', '/api/users/me/saved/jobs') as List)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<List<WorkerProfile>> savedWorkers() async =>
      (await _request('GET', '/api/users/me/saved/workers') as List)
          .map((e) => WorkerProfile.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<void> saveJob(int id, bool saved) async {
    await _request(saved ? 'PUT' : 'DELETE', '/api/users/me/saved/jobs/$id');
  }

  Future<void> saveWorker(int id, bool saved) async {
    await _request(saved ? 'PUT' : 'DELETE', '/api/users/me/saved/workers/$id');
  }

  Future<Job> fetchJob(int id) async => Job.fromJson(
    await _request('GET', '/api/jobs/$id') as Map<String, dynamic>,
  );
  Future<Job> updateJob(int id, Map<String, dynamic> body) async =>
      Job.fromJson(
        await _request('PUT', '/api/jobs/$id', body: body)
            as Map<String, dynamic>,
      );
  Future<CommitmentDocument> jobTerms(
    int id, {
    int? proposedRate,
  }) async => CommitmentDocument.fromJson(
    await _request(
      'GET',
      '/api/jobs/$id/terms${proposedRate == null ? '' : '?proposedDailyRate=$proposedRate'}',
    ) as Map<String, dynamic>,
  );
  Future<CommitmentDocument> commitment(
    int id, {
    bool acceptOffer = false,
  }) async => CommitmentDocument.fromJson(
    await _request(
      'GET',
      '/api/applications/$id/commitment?acceptCounterOffer=$acceptOffer',
    ) as Map<String, dynamic>,
  );
  Future<CommitmentDocument> confirmCommitment(int id, int version) async =>
      CommitmentDocument.fromJson(
        await _request(
          'PUT',
          '/api/applications/$id/commitment',
          body: {'accepted': true, 'termsVersion': version},
        ) as Map<String, dynamic>,
      );
  Future<JobApplication> applyWithTerms(int id, WorkProposal proposal) async =>
      JobApplication.fromJson(
        await _request(
          'POST',
          '/api/applications/apply',
          body: {
            'jobId': id,
            'proposedDailyRate': proposal.rate,
            'wageNote': proposal.note,
            'acceptedTerms': true,
            'termsVersion': proposal.version,
          },
        ) as Map<String, dynamic>,
      );
  Future<JobApplication> acceptWithTerms(
    int id,
    int version, {
    bool acceptOffer = false,
  }) async => JobApplication.fromJson(
    await _request(
      'PUT',
      '/api/applications/$id/status',
      body: {
        'status': 'ACCEPTED',
        'acceptedTerms': true,
        'termsVersion': version,
        'acceptCounterOffer': acceptOffer,
      },
    ) as Map<String, dynamic>,
  );
  Future<List<CalendarEntry>> calendar(DateTime from, DateTime to) async =>
      (await _request(
            'GET',
            '/api/users/me/calendar?from=${isoDay(from)}&to=${isoDay(to)}',
          ) as List)
          .map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>))
          .toList();
  Future<void> blockCalendar(DateTime from, DateTime to, String note) async {
    await _request(
      'POST',
      '/api/users/me/calendar',
      body: {'from': isoDay(from), 'to': isoDay(to), 'note': note},
    );
  }

  Future<void> removeCalendarBlock(int id) async {
    await _request('DELETE', '/api/users/me/calendar/$id');
  }

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
    defaultValue: 'https://thoxay-api.onrender.com',
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

  Future<ChatMessage> sendChatPhoto(
    int jobId,
    int peerId,
    Uint8List bytes,
    String caption,
    String clientId,
  ) async => ChatMessage.fromJson(
    await uploadPhoto(
      '/api/jobs/$jobId/messages/photo',
      bytes,
      fields: {
        'recipientId': '$peerId',
        'caption': caption,
        'clientMessageId': clientId,
      },
    ),
  );

  Future<ChatMessage> sendChatLocation(
    int jobId,
    int peerId,
    double latitude,
    double longitude,
    String clientId,
  ) async => ChatMessage.fromJson(
    await _request(
      'POST',
      '/api/jobs/$jobId/messages/location',
      body: {
        'recipientId': peerId,
        'latitude': latitude,
        'longitude': longitude,
        'clientMessageId': clientId,
      },
    ) as Map<String, dynamic>,
  );

  Future<ChatInbox> chatInbox({int? beforeId}) async => ChatInbox.fromJson(
    await _request(
      'GET',
      '/api/messages/inbox${beforeId == null ? '' : '?beforeId=$beforeId'}',
    ) as Map<String, dynamic>,
  );

  Future<int> unreadMessages() async {
    final data = await _request('GET', '/api/messages/unread');
    if (data is! Map ||
        data['unreadCount'] is! int ||
        (data['unreadCount'] as int) < 0) {
      throw const ApiException('Không đọc được số tin nhắn chưa đọc');
    }
    return data['unreadCount'] as int;
  }

  Future<void> readMessages(
    int jobId,
    int peerId,
    int lastReadMessageId,
  ) async {
    await _request(
      'PUT',
      '/api/jobs/$jobId/messages/read',
      body: {'peerId': peerId, 'lastReadMessageId': lastReadMessageId},
    );
  }

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

  Future<UserProfile> uploadCccd(KycPhoto front, KycPhoto back) async {
    final session = _requireSession();
    if (!session.expiresAt.isAfter(DateTime.now())) {
      await logout();
      throw const ApiException('Phiên đăng nhập đã hết hạn', 401);
    }
    if ([
      front,
      back,
    ].any((p) => p.bytes.isEmpty || p.bytes.length > 5 * 1024 * 1024)) {
      throw const ApiException('Cần hai ảnh hợp lệ, mỗi ảnh tối đa 5 MB');
    }
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$baseUrl/api/users/me/cccd/photos'),
          )
          ..headers['Authorization'] = 'Bearer ${session.token}'
          ..files.addAll([
            http.MultipartFile.fromBytes(
              'front',
              front.bytes,
              filename: 'front.jpg',
            ),
            http.MultipartFile.fromBytes(
              'back',
              back.bytes,
              filename: 'back.jpg',
            ),
          ]);
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 401 ||
          (response.statusCode == 403 &&
              data is Map &&
              data['code'] == 'ACCOUNT_LOCKED')) {
        await logout();
      }
      if (response.statusCode != 200) {
        throw ApiException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Không tải được ảnh CCCD',
          response.statusCode,
        );
      }
      if (data is! Map<String, dynamic>) throw const FormatException();
      return UserProfile.fromJson(data);
    } on FormatException {
      throw const ApiException('Máy chủ trả về dữ liệu không hợp lệ');
    } on TimeoutException {
      throw const ApiException(
        'Tải ảnh quá thời gian. Hai ảnh vẫn được giữ để gửi lại.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Không kết nối được máy chủ. Hai ảnh vẫn được giữ để gửi lại.',
      );
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
