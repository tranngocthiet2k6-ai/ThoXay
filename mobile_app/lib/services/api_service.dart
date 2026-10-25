import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get _defaultBaseUrl => _configuredUrl.isNotEmpty
      ? _configuredUrl
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8080'
          : 'http://localhost:8080';
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
      final restored =
          AuthSession.fromJson(jsonDecode(stored) as Map<String, dynamic>);
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
    await _authenticate(
        '/api/auth/login', {'phoneNumber': phoneNumber, 'password': password});
  }

  Future<void> register(
      {required String fullName,
      required String phoneNumber,
      required String password,
      required String role,
      String? cccdImage}) async {
    await _authenticate('/api/auth/register', {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
      'cccdImage': cccdImage
    });
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    final result =
        await _request('POST', path, body: body, authenticated: false);
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

  Future<List<Job>> nearby(double lat, double lng, double radius) async =>
      _jobs(await _request(
          'GET', '/api/jobs/nearby?lat=$lat&lng=$lng&radius=$radius'));
  Future<List<Job>> contractorJobs() async => _jobs(await _request(
      'GET', '/api/jobs/contractor/${_requireSession().userId}'));
  Future<Job> createJob(Map<String, dynamic> body) async => Job.fromJson(
      await _request('POST', '/api/jobs', body: body) as Map<String, dynamic>);
  Future<JobApplication> apply(int jobId) async => JobApplication.fromJson(
      await _request('POST', '/api/applications/apply', body: {'jobId': jobId})
          as Map<String, dynamic>);
  Future<List<JobApplication>> workerApplications() async =>
      _applications(await _request(
          'GET', '/api/applications/worker/${_requireSession().userId}'));
  Future<List<JobApplication>> jobApplications(int jobId) async =>
      _applications(await _request('GET', '/api/applications/job/$jobId'));
  Future<JobApplication> updateApplication(int id, String status) async =>
      JobApplication.fromJson(await _request(
              'PUT', '/api/applications/$id/status', body: {'status': status})
          as Map<String, dynamic>);
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

  Future<Object?> _request(String method, String path,
      {Map<String, dynamic>? body, bool authenticated = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8'
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
      if (response.statusCode == 401 && authenticated) await logout();
      throw ApiException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Không thể thực hiện yêu cầu (${response.statusCode})',
          response.statusCode);
    } on TimeoutException {
      throw const ApiException('Kết nối quá thời gian. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiException(
          'Không kết nối được máy chủ. Kiểm tra mạng và địa chỉ API.');
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
