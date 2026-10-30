class Deposit {
  Deposit.fromJson(Map<String, dynamic> j)
    : id = (j['requestId'] as num).toInt(),
      amount = (j['amount'] as num).toInt(),
      status = j['status'] as String,
      reference = j['reference'] as String,
      bankName = j['bankName'] as String,
      bankBin = j['bankBin'] as String? ?? '',
      accountNo = j['accountNo'] as String,
      accountName = j['accountName'] as String,
      payload = j['payload'] as String;
  final int id, amount;
  final String status, reference, bankName, accountNo, accountName, payload;
  final String bankBin;
  bool get isDemo => bankBin == '000000';
}
