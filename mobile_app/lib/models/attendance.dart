import 'dart:convert';

class AttendanceEntry {
  AttendanceEntry.fromJson(Map<String, dynamic> j)
    : id = (j['id'] as num).toInt(),
      applicationId = (j['applicationId'] as num).toInt(),
      workerName = j['workerName'] as String,
      day = DateTime.parse(j['workDay'] as String),
      checkedInAt = DateTime.parse(j['checkedInAt'] as String),
      checkedOutAt = j['checkedOutAt'] == null
          ? null
          : DateTime.parse(j['checkedOutAt'] as String),
      logId = (j['logId'] as num?)?.toInt(),
      caption = j['caption'] as String? ?? '',
      reviewStatus = j['reviewStatus'] as String?,
      feedback = j['feedback'] as String? ?? '',
      logVersion = (j['logVersion'] as num?)?.toInt();
  final int id, applicationId;
  final String workerName, caption, feedback;
  final DateTime day, checkedInAt;
  final DateTime? checkedOutAt;
  final int? logId, logVersion;
  final String? reviewStatus;
  String? get photoPath => logId == null ? null : '/api/work-logs/$logId/photo';
}

class AttendancePage {
  AttendancePage.fromJson(Map<String, dynamic> j)
    : today = DateTime.parse(j['today'] as String),
      items = (j['items'] as List)
          .map((e) => AttendanceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore = j['hasMore'] as bool;
  final DateTime today;
  final List<AttendanceEntry> items;
  final bool hasMore;
}

class ShiftCode {
  ShiftCode.fromJson(Map<String, dynamic> j)
    : jobId = (j['jobId'] as num).toInt(),
      token = j['token'] as String,
      expiresAt = DateTime.parse(j['expiresAt'] as String);
  final int jobId;
  final String token;
  final DateTime expiresAt;
  String get qr =>
      jsonEncode({'type': 'THOXAY_ATTENDANCE', 'jobId': jobId, 'token': token});
  static String? parse(String raw, int jobId) {
    try {
      final j = jsonDecode(raw);
      if (j is Map &&
          j['type'] == 'THOXAY_ATTENDANCE' &&
          j['jobId'] == jobId &&
          j['token'] is String &&
          RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(j['token'] as String)) {
        return j['token'] as String;
      }
    } on FormatException {
      /* Ignore unrelated QR codes. */
    }
    return null;
  }
}
