import 'models.dart';
import 'worker_profile.dart';

class ContractorGroup {
  const ContractorGroup({
    required this.id,
    required this.name,
    required this.members,
  });
  final int id;
  final String name;
  final List<WorkerProfile> members;
  factory ContractorGroup.fromJson(Map<String, dynamic> j) => ContractorGroup(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    members: (j['members'] as List)
        .map((m) => WorkerProfile.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}

class TeamContact {
  const TeamContact({
    required this.workerId,
    required this.applicationId,
    required this.job,
    required this.phoneNumber,
  });
  final int workerId, applicationId;
  final Job job;
  final String phoneNumber;
  factory TeamContact.fromJson(Map<String, dynamic> j) => TeamContact(
    workerId: (j['workerId'] as num).toInt(),
    applicationId: (j['applicationId'] as num).toInt(),
    job: Job.fromJson(j['job'] as Map<String, dynamic>),
    phoneNumber: j['phoneNumber'] as String,
  );
}
