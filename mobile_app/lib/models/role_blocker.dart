import 'models.dart';

class RoleBlocker {
  const RoleBlocker({
    required this.reason,
    required this.job,
    required this.owner,
  });
  final String reason;
  final Job job;
  final bool owner;
  bool get unpaid => reason == 'UNPAID_WORK';
  factory RoleBlocker.fromJson(Map<String, dynamic> json) => RoleBlocker(
    reason: json['reason'] as String,
    job: Job.fromJson(json['job'] as Map<String, dynamic>),
    owner: json['owner'] as bool,
  );
}
