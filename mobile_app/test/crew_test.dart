import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/crew.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/models/scheduling.dart';
import 'package:tho_xay_mobile/screens/crew_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

class CrewApi extends ApiService {
  CrewApi({this.leader = false, this.confirmed = false});
  final bool leader;
  bool confirmed;
  bool applied = false;
  @override
  AuthSession? get session => AuthSession(
    token: 'qa',
    userId: leader ? 1 : 2,
    fullName: 'QA',
    phoneNumber: '0999999999',
    role: 'ROLE_WORKER',
    expiresAt: DateTime(2040),
  );
  @override
  Future<List<Crew>> crews() async => [
    Crew(
      id: 7,
      name: 'Tổ thợ QA',
      leaderId: 1,
      members: [
        const CrewMember(id: 1, name: 'Tổ trưởng QA', status: 'CONFIRMED'),
        CrewMember(
          id: 2,
          name: 'Thành viên QA',
          status: confirmed ? 'CONFIRMED' : 'INVITED',
        ),
      ],
    ),
  ];
  @override
  Future<void> crewMembership(int id, bool accepted) async {
    confirmed = accepted;
  }

  @override
  Future<CommitmentDocument> jobTerms(int id, {int? proposedRate}) async =>
      CommitmentDocument.fromJson({
        'termsVersion': 1,
        'state': 'DRAFT',
        'text': 'Cam kết riêng của tổ trưởng. Mỗi thành viên xác nhận riêng.',
        'selectedDailyRate': 350000,
      });
  @override
  Future<void> crewApply(int id, int jobId, WorkProposal p) async {
    applied = true;
  }
}

void main() {
  testWidgets('invited worker must explicitly join team', (tester) async {
    final api = CrewApi();
    await tester.pumpWidget(MaterialApp(home: CrewScreen(api: api)));
    await tester.pumpAndSettle();
    expect(api.confirmed, isFalse);
    expect(find.text('Đang chờ xác nhận'), findsOneWidget);
    await tester.ensureVisible(find.text('Tham gia tổ'));
    await tester.tap(find.text('Tham gia tổ'));
    await tester.pumpAndSettle();
    expect(api.confirmed, isTrue);
    expect(find.text('Tham gia tổ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('crew application cannot count unconfirmed invite as a worker', (
    tester,
  ) async {
    final api = CrewApi(leader: true);
    final job = Job(
      id: 1,
      contractorId: 3,
      contractorName: 'QA',
      contractorPhone: null,
      title: 'Việc QA',
      description: '',
      jobType: 'Thợ chính',
      salaryPerDay: 350000,
      address: 'QA',
      latitude: 10,
      longitude: 106,
      requiredWorkers: 2,
      status: 'OPEN',
      startsOn: DateTime(2030),
      endsOn: DateTime(2030, 1, 2),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CrewScreen(api: api, job: job),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.widgetWithText(FilledButton, 'Ứng tuyển 1 người');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(api.applied, isFalse);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
  testWidgets('leader submits only after reading and consenting to job terms', (
    tester,
  ) async {
    final api = CrewApi(leader: true, confirmed: true);
    final job = Job(
      id: 1,
      contractorId: 3,
      contractorName: 'QA',
      contractorPhone: null,
      title: 'Việc QA',
      description: '',
      jobType: 'Thợ chính',
      salaryPerDay: 350000,
      address: 'QA',
      latitude: 10,
      longitude: 106,
      requiredWorkers: 2,
      status: 'OPEN',
      startsOn: DateTime(2030),
      endsOn: DateTime(2030, 1, 2),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CrewScreen(api: api, job: job),
                ),
              ),
              child: const Text('Mở tổ'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở tổ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ứng tuyển 2 người'));
    await tester.tap(find.text('Ứng tuyển 2 người'));
    await tester.pumpAndSettle();
    expect(api.applied, isFalse);
    await tester.ensureVisible(
      find.byKey(const ValueKey('commitment-consent')),
    );
    await tester.tap(find.byKey(const ValueKey('commitment-consent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý & ứng tuyển'));
    await tester.pumpAndSettle();
    expect(api.applied, isTrue);
    expect(find.text('Mở tổ'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });
}
