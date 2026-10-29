class IncidentItem {
  IncidentItem.fromJson(Map<String, dynamic> j)
    : id = (j['id'] as num).toInt(),
      jobId = (j['jobId'] as num).toInt(),
      jobTitle = j['jobTitle'] as String,
      type = j['type'] as String,
      status = j['status'] as String,
      description = j['description'] as String,
      adminNote = j['adminNote'] as String? ?? '',
      createdAt = DateTime.parse(j['createdAt'] as String);
  final int id, jobId;
  final String jobTitle, type, status, description, adminNote;
  final DateTime createdAt;
}

class IncidentAudit {
  IncidentAudit.fromJson(Map<String, dynamic> j)
    : status = j['status'] as String,
      note = j['note'] as String,
      createdAt = DateTime.parse(j['createdAt'] as String);
  final String status, note;
  final DateTime createdAt;
}

class IncidentDetail {
  IncidentDetail.fromJson(Map<String, dynamic> j)
    : incident = IncidentItem.fromJson(j['incident'] as Map<String, dynamic>),
      history = (j['history'] as List)
          .map((e) => IncidentAudit.fromJson(e as Map<String, dynamic>))
          .toList();
  final IncidentItem incident;
  final List<IncidentAudit> history;
}

class IncidentPage {
  IncidentPage.fromJson(Map<String, dynamic> j)
    : items = (j['items'] as List)
          .map((e) => IncidentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore = j['hasMore'] as bool;
  final List<IncidentItem> items;
  final bool hasMore;
}

String incidentType(String type) => switch (type) {
  'SOS' => 'SOS khẩn cấp',
  'SAFETY' => 'An toàn công trường',
  'PAYMENT_DISPUTE' => 'Tranh chấp thanh toán',
  _ => 'Sự cố khác',
};
String incidentStatus(String status) => switch (status) {
  'NEW' => 'Đã gửi tới Admin',
  'IN_REVIEW' => 'Admin đang xử lý',
  'RESOLVED' => 'Đã có kết quả',
  _ => status,
};
String incidentTime(DateTime time) {
  final vn = time.toUtc().add(const Duration(hours: 7));
  return '${vn.day.toString().padLeft(2, '0')}/${vn.month.toString().padLeft(2, '0')}/${vn.year} ${vn.hour.toString().padLeft(2, '0')}:${vn.minute.toString().padLeft(2, '0')}';
}
