class CommitmentDocument {
  CommitmentDocument.fromJson(Map<String, dynamic> j)
    : version = (j['termsVersion'] as num).toInt(),
      text = j['text'] as String,
      state = j['state'] as String,
      hash = j['hash'] as String?,
      selectedRate = (j['selectedDailyRate'] as num).toInt();
  final int version, selectedRate;
  final String text, state;
  final String? hash;
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
