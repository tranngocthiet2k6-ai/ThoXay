class WalletBalance {
  WalletBalance.fromJson(Map<String, dynamic> j)
    : main = (j['mainBalance'] as num).toInt(),
      escrow = (j['escrowBalance'] as num).toInt(),
      held = (j['heldBalance'] as num).toInt(),
      minimum = (j['minimumEscrow'] as num).toInt(),
      lowEscrow = j['lowEscrow'] as bool;
  final int main, escrow, held, minimum;
  final bool lowEscrow;
}

class WalletEntry {
  WalletEntry.fromJson(Map<String, dynamic> j)
    : id = (j['id'] as num).toInt(),
      kind = j['kind'] as String,
      amount = (j['amount'] as num).toInt(),
      description = j['description'] as String,
      createdAt = DateTime.parse(j['createdAt'] as String);
  final int id, amount;
  final String kind, description;
  final DateTime createdAt;
}

class WalletRequest {
  WalletRequest.fromJson(Map<String, dynamic> j)
    : id = (j['id'] as num).toInt(),
      kind = j['kind'] as String,
      status = j['status'] as String,
      amount = (j['amount'] as num).toInt(),
      note = j['note'] as String?,
      depositReference = j['depositReference'] as String?,
      createdAt = DateTime.parse(j['createdAt'] as String);
  final int id, amount;
  final String kind, status;
  final String? note, depositReference;
  final DateTime createdAt;
}

class WalletPage<T> {
  const WalletPage(this.items, this.hasMore);
  final List<T> items;
  final bool hasMore;
}

class Earnings {
  Earnings.fromJson(Map<String, dynamic> j)
    : base = (j['base'] as num).toInt(),
      tip = (j['tip'] as num).toInt(),
      bonus = (j['bonus'] as num).toInt(),
      total = (j['total'] as num).toInt(),
      jobs = (j['settledJobs'] as num).toInt(),
      days = (j['days'] as List? ?? [])
          .map((day) => EarningsDay.fromJson(day as Map<String, dynamic>))
          .toList(),
      from = DateTime.parse(j['from'] as String),
      to = DateTime.parse(j['toExclusive'] as String)
          .subtract(const Duration(days: 1));
  final int base, tip, bonus, total, jobs;
  final DateTime from, to;
  final List<EarningsDay> days;
}

class EarningsDay {
  EarningsDay.fromJson(Map<String, dynamic> json)
    : date = DateTime.parse(json['date'] as String),
      base = (json['base'] as num).toInt(),
      tip = (json['tip'] as num).toInt(),
      bonus = (json['bonus'] as num).toInt(),
      total = (json['total'] as num).toInt();
  final DateTime date;
  final int base, tip, bonus, total;
}

class JobPayment {
  JobPayment.fromJson(Map<String, dynamic> j)
    : applicationId = (j['applicationId'] as num?)?.toInt(),
      workerId = (j['workerId'] as num).toInt(),
      days = (j['workDays'] as num).toInt(),
      total = (j['total'] as num).toInt(),
      tip = (j['tip'] as num).toInt(),
      bonus = (j['bonus'] as num).toInt();
  final int? applicationId;
  final int workerId, days, total, tip, bonus;
}

String walletKind(String kind) => switch (kind) {
  'TOP_UP' => 'Nạp tiền',
  'WITHDRAW' => 'Rút tiền',
  'WITHDRAW_HOLD' => 'Giữ chỗ rút tiền',
  'WITHDRAW_PAID' => 'Đã chuyển tiền rút',
  'WITHDRAW_RELEASE' => 'Hoàn giữ chỗ',
  'ESCROW_LOCK' => 'Chuyển vào ký quỹ',
  'ESCROW_RELEASE' => 'Hoàn ký quỹ',
  'JOB_PAYMENT' => 'Thanh toán tiền công',
  'WORK_EARNING' => 'Tiền công',
  'TIP' => 'Tiền tip',
  'BONUS' => 'Tiền thưởng',
  _ => 'Giao dịch ví',
};
String requestStatus(String value) => switch (value) {
  'APPROVED' => 'Đã đối soát',
  'REJECTED' => 'Đã từ chối',
  _ => 'Chờ đối soát',
};

String walletEntrySign(String kind) => switch (kind) {
  'JOB_PAYMENT' || 'WITHDRAW_PAID' || 'WITHDRAW_HOLD' => '− ',
  'ESCROW_LOCK' || 'ESCROW_RELEASE' => '↔ ',
  _ => '+ ',
};
