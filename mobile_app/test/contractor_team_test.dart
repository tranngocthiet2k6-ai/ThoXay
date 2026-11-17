import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/contractor_team.dart';
import 'package:tho_xay_mobile/models/worker_profile.dart';
import 'package:tho_xay_mobile/screens/contractor_team_screen.dart';
import 'package:tho_xay_mobile/widgets/profile_summary.dart';

import 'contractor_home_test.dart' show ContractorApi;

const worker = WorkerProfile(
  id: 3,
  fullName: 'Nguyễn Văn An',
  verified: true,
  rating: 4.8,
  experienceYears: 5,
  experienceSummary: 'Xây tô',
  skills: ['Xây tô'],
  projectImages: [],
);

class TeamApi extends ContractorApi {
  final groups = <ContractorGroup>[];
  List<int>? invited;
  @override
  Future<List<WorkerProfile>> savedWorkers() async => [worker];
  @override
  Future<List<ContractorGroup>> contractorGroups() async => groups.toList();
  @override
  Future<List<TeamContact>> teamContacts() async => [];
  @override
  Future<void> createContractorGroup(String name) async =>
      groups.add(ContractorGroup(id: 1, name: name, members: []));
  @override
  Future<void> contractorGroupMember(int id, int workerId, bool add) async {
    groups[0] = ContractorGroup(
      id: id,
      name: groups[0].name,
      members: add ? [worker] : [],
    );
  }

  @override
  Future<void> inviteTeamToJob(int jobId, List<int> workerIds) async {
    invited = workerIds;
  }
}

void main() {
  testWidgets(
    'team has two tabs, compact workers and guarded contact actions',
    (tester) async {
      final api = TeamApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ContractorTeamScreen(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thợ đã lưu'), findsOneWidget);
      expect(find.text('Nhóm thợ của tôi'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.byType(ProfileSummary), findsNothing);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Nhắn tin'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Gọi điện'), findsNothing);
      await tester.tap(find.text('Nhóm thợ của tôi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo nhóm thợ mới'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên nhóm'),
        'Đội xây tô',
      );
      await tester.tap(find.text('Tạo nhóm'));
      await tester.pumpAndSettle();
      expect(api.groups.single.name, 'Đội xây tô');
      await tester.tap(find.text('Thêm thợ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nguyễn Văn An'));
      await tester.pumpAndSettle();
      expect(api.groups.single.members.single.id, 3);
      await tester.tap(find.text('Mời cả nhóm vào công trình'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Công trình A'));
      await tester.pumpAndSettle();
      expect(api.invited, isNull);
      await tester.tap(find.text('Gửi lời mời'));
      await tester.pumpAndSettle();
      expect(api.invited, [3]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
