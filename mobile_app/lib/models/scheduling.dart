class CommitmentDocument {
  CommitmentDocument.fromJson(Map<String, dynamic> j)
    : version = (j['termsVersion'] as num).toInt(),
      text = j['text'] as String,
      state = j['state'] as String,
      hash = j['hash'] as String?,
      selectedRate = (j['selectedDailyRate'] as num).toInt(),
      applicationId = (j['applicationId'] as num?)?.toInt(),
      workerName = j['workerName'] as String? ?? 'Người thợ',
      contractorName = j['contractorName'] as String? ?? 'Chủ thầu',
      workerVerified = j['workerVerified'] == true,
      contractorVerified = j['contractorVerified'] == true,
      workerConfirmedAt = DateTime.tryParse(
        j['workerConfirmedAt'] as String? ?? '',
      ),
      contractorConfirmedAt = DateTime.tryParse(
        j['contractorConfirmedAt'] as String? ?? '',
      );
  final int version, selectedRate;
  final String text, state;
  final String? hash;
  final int? applicationId;
  final String workerName, contractorName;
  final bool workerVerified, contractorVerified;
  final DateTime? workerConfirmedAt, contractorConfirmedAt;
  bool get bothConfirmed =>
      state == 'FINAL' &&
      workerConfirmedAt != null &&
      contractorConfirmedAt != null;
}

class CalendarEntry {
  CalendarEntry.fromJson(Map<String, dynamic> j)
    : kind = j['kind'] as String,
      id = (j['referenceId'] as num).toInt(),
      title = j['title'] as String,
      from = DateTime.parse(j['startsOn'] as String),
      to = DateTime.parse(j['endsOn'] as String);
  final String kind, title;
  final int id;
  final DateTime from, to;
}

String isoDay(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class WorkProposal {
  const WorkProposal({required this.version, this.rate, this.note});
  final int version;
  final int? rate;
  final String? note;
}
