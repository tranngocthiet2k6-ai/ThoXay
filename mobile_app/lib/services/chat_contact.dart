import '../models/models.dart';
import 'api_service.dart';

/// Contact details come from the accepted application, never from public jobs.
class ChatContact {
  const ChatContact(this.application, this.phone, this.verified);
  final JobApplication application;
  final String? phone;
  final bool verified;
  double get dailyRate =>
      application.agreedDailyRate?.toDouble() ?? application.job.salaryPerDay;
}

Future<ChatContact?> loadChatContact(
  ApiService api,
  Job job,
  int peerId,
) async {
  final session = api.session;
  if (session == null || session.userId == peerId) return null;
  final contractor = session.role == 'ROLE_CONTRACTOR';
  if (contractor
      ? session.userId != job.contractorId
      : session.role != 'ROLE_WORKER' || peerId != job.contractorId) {
    return null;
  }
  final rows = contractor
      ? await api.jobApplications(job.id)
      : await api.workerApplications();
  // Discard results from a previous login, including logout during the request.
  if (api.session?.token != session.token) return null;
  final application = rows
      .where(
        (a) =>
            a.job.id == job.id &&
            a.job.contractorId == job.contractorId &&
            a.workerId == (contractor ? peerId : session.userId) &&
            a.status == 'ACCEPTED' &&
            a.workerActive,
      )
      .firstOrNull;
  if (application == null) return null;
  return ChatContact(
    application,
    contractor ? application.workerPhone : application.job.contractorPhone,
    contractor
        ? application.workerVerified
        : application.job.contractorVerified,
  );
}
