import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/reputation.dart';
import 'package:tho_xay_mobile/screens/leaderboard_screen.dart';
import 'package:tho_xay_mobile/screens/reputation_screen.dart';
import 'package:tho_xay_mobile/services/api_service.dart';

class RankingApi extends ApiService {
  @override
  Future<List<WorkerRank>> leaderboard() async => [
    WorkerRank.fromJson({
      'rank': 1,
      'workerId': 3,
      'fullName': 'Thợ Minh',
      'workerTier': 'GOLD',
      'reputationScore': 85,
      'rating': 4.5,
      'completedJobs': 8,
      'verified': true,
    }),
  ];
  @override
  Future<ReputationPage> reputationHistory({int? beforeId}) async =>
      ReputationPage([
        ReputationEntry.fromJson({
          'id': beforeId == null ? 2 : 1,
          'delta': beforeId == null ? -15 : 2,
          'scoreAfter': beforeId == null ? 85 : 100,
          'type': beforeId == null ? 'CANCELLED' : 'COMPLETED',
          'jobTitle': beforeId == null
              ? 'Công trình hủy'
              : 'Công trình hoàn tất',
          'createdAt': '2026-10-26T00:00:00Z',
        }),
      ], beforeId == null);
}

void main() {
  testWidgets('rank displays reviewed work, tier and transparent criteria', (
    tester,
  ) async {
    final api = RankingApi();
    await tester.pumpWidget(MaterialApp(home: LeaderboardScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Thợ Minh'), findsOneWidget);
    expect(find.text('Bậc Vàng'), findsOneWidget);
    expect(find.text('85/100 uy tín'), findsOneWidget);
    await tester.tap(find.text('Cách tính bậc thợ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('20 công trình'), findsOneWidget);
    api.dispose();
  });
  testWidgets(
    'reputation history paginates and distinguishes earned and lost points',
    (tester) async {
      final api = RankingApi();
      await tester.pumpWidget(MaterialApp(home: ReputationScreen(api: api)));
      await tester.pumpAndSettle();
      expect(
        find.text('-15 điểm · Uy tín sau thay đổi: 85/100'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tải lịch sử cũ'));
      await tester.pumpAndSettle();
      expect(
        find.text('+2 điểm · Uy tín sau thay đổi: 100/100'),
        findsOneWidget,
      );
      expect(find.text('Công trình hoàn tất'), findsOneWidget);
      api.dispose();
    },
  );
}
