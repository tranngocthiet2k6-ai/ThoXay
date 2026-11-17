import 'dart:convert';

import '../services/job_links.dart';

enum QrKind { attendance, worker, job, payment }

class QrAction {
  const QrAction(this.kind, {this.id, this.token, this.payment});
  final QrKind kind;
  final int? id;
  final String? token;
  final VietQrPayment? payment;

  static String workerCode(int userId) =>
      jsonEncode({'type': 'THOXAY_WORKER', 'workerId': userId});

  static QrAction? parse(String value) {
    final raw = value.trim();
    if (raw.isEmpty || utf8.encode(raw).length > 4096) return null;
    if (raw.startsWith('{')) {
      try {
        final j = jsonDecode(raw);
        if (j is! Map<String, dynamic>) return null;
        final id = j[j['type'] == 'THOXAY_WORKER' ? 'workerId' : 'jobId'];
        if (id is! int || id <= 0 || id > 9007199254740991) return null;
        if (j['type'] == 'THOXAY_WORKER') {
          return QrAction(QrKind.worker, id: id);
        }
        if (j['type'] == 'THOXAY_ATTENDANCE' &&
            j['token'] is String &&
            RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(j['token'] as String)) {
          return QrAction(
            QrKind.attendance,
            id: id,
            token: j['token'] as String,
          );
        }
      } on FormatException {
        return null;
      }
      return null;
    }
    final uri = Uri.tryParse(raw);
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'thoxay.vercel.app' &&
        uri.userInfo.isEmpty &&
        uri.port == 443 &&
        uri.path == '/') {
      final id = JobLinks.parse(uri);
      if (id != null) return QrAction(QrKind.job, id: id);
    }
    final payment = VietQrPayment.parse(raw);
    return payment == null ? null : QrAction(QrKind.payment, payment: payment);
  }
}

/// NAPAS account-transfer TLV. CRC and byte lengths are checked before display.
class VietQrPayment {
  const VietQrPayment({
    required this.bankBin,
    required this.accountNo,
    required this.reference,
    required this.raw,
    this.amount,
    this.accountName = '',
  });
  final String bankBin, accountNo, reference, raw, accountName;
  final int? amount;
  bool get demo => bankBin == '000000';

  static Map<String, String> _tlv(List<int> bytes) {
    final result = <String, String>{};
    var cursor = 0;
    while (cursor < bytes.length) {
      if (cursor + 4 > bytes.length) throw const FormatException();
      final tag = ascii.decode(bytes.sublist(cursor, cursor + 2));
      final size = int.tryParse(
        ascii.decode(bytes.sublist(cursor + 2, cursor + 4)),
      );
      if (!RegExp(r'^\d{2}$').hasMatch(tag) ||
          size == null ||
          cursor + 4 + size > bytes.length ||
          result.containsKey(tag)) {
        throw const FormatException();
      }
      result[tag] = utf8.decode(bytes.sublist(cursor + 4, cursor + 4 + size));
      cursor += size + 4;
    }
    return result;
  }

  static int crc(List<int> bytes) {
    var value = 0xffff;
    for (final byte in bytes) {
      value ^= byte << 8;
      for (var i = 0; i < 8; i++) {
        value =
            ((value & 0x8000) != 0 ? (value << 1) ^ 0x1021 : value << 1) &
            0xffff;
      }
    }
    return value;
  }

  static VietQrPayment? parse(String raw) {
    try {
      final bytes = utf8.encode(raw);
      if (bytes.length < 12 ||
          bytes.length > 4096 ||
          raw.substring(raw.length - 8, raw.length - 4) != '6304') {
        return null;
      }
      final checksum = int.tryParse(raw.substring(raw.length - 4), radix: 16);
      if (checksum == null ||
          checksum != crc(bytes.sublist(0, bytes.length - 4))) {
        return null;
      }
      final fields = _tlv(bytes);
      if (fields['00'] != '01' ||
          fields['53'] != '704' ||
          fields['58'] != 'VN') {
        return null;
      }
      final merchant = _tlv(utf8.encode(fields['38'] ?? ''));
      if (merchant['00'] != 'A000000727' || merchant['02'] != 'QRIBFTTA') {
        return null;
      }
      final account = _tlv(utf8.encode(merchant['01'] ?? ''));
      if (!RegExp(r'^\d{6}$').hasMatch(account['00'] ?? '') ||
          !RegExp(r'^[A-Za-z0-9]{1,19}$').hasMatch(account['01'] ?? '')) {
        return null;
      }
      int? amount;
      if (fields['54'] != null) {
        if (!RegExp(r'^\d{1,13}(\.0{1,2})?$').hasMatch(fields['54']!)) {
          return null;
        }
        amount = int.parse(fields['54']!.split('.').first);
        if (amount <= 0) return null;
      }
      final note = _tlv(utf8.encode(fields['62'] ?? ''))['08'] ?? '';
      return VietQrPayment(
        bankBin: account['00']!,
        accountNo: account['01']!,
        amount: amount,
        reference: note,
        accountName: fields['59'] ?? '',
        raw: raw,
      );
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  Uri bankLink(String app, String bankCode, int amount) =>
      Uri.https('dl.vietqr.io', '/pay', {
        'app': app,
        'ba': '$accountNo@$bankCode',
        'am': '$amount',
        'tn': reference,
        if (accountName.isNotEmpty) 'bn': accountName,
        'url': 'https://thoxay.vercel.app',
      });
}
