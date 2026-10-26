import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/models.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/profile_editor.dart';

class ProfileApi extends ApiService {
  int calls = 0;
  List<String>? savedSkills, savedImages;
  @override
  Future<UserProfile> updateProfile({
    required String fullName,
    String? dateOfBirth,
    required int experienceYears,
    required String experienceSummary,
    required List<String> skills,
    required List<String> projectImages,
  }) async {
    calls++;
    savedSkills = skills;
    savedImages = projectImages;
    return UserProfile(
      id: 3,
      fullName: fullName,
      phoneNumber: '0900000003',
      role: 'ROLE_WORKER',
      verified: false,
      rating: 5,
      dateOfBirth: dateOfBirth,
      experienceYears: experienceYears,
      experienceSummary: experienceSummary,
      skills: skills,
      projectImages: projectImages,
    );
  }
}

const person = UserProfile(
  id: 3,
  fullName: 'Thợ A',
  phoneNumber: '0900000003',
  role: 'ROLE_WORKER',
  verified: true,
  rating: 5,
);
void main() {
  testWidgets(
    'profile rejects invalid experience and HTTP project photos before saving',
    (tester) async {
      final api = ProfileApi();
      UserProfile? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileEditor(
                api: api,
                profile: person,
                onSaved: (value) => saved = value,
                onBusy: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('profile-years')), '-1');
      await tester.ensureVisible(find.text('Lưu hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu hồ sơ'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập số năm từ 0 đến 60'), findsOneWidget);
      expect(api.calls, 0);
      await tester.enterText(find.byKey(const ValueKey('profile-years')), '5');
      await tester.enterText(
        find.byKey(const ValueKey('profile-images')),
        'http://example.com/photo.jpg',
      );
      await tester.ensureVisible(find.text('Lưu hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu hồ sơ'));
      await tester.pumpAndSettle();
      expect(api.calls, 0);
      await tester.enterText(
        find.byKey(const ValueKey('profile-images')),
        'https://example.com/photo.jpg',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-skills')),
        'Xây, Tô, Xây',
      );
      await tester.ensureVisible(find.text('Lưu hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu hồ sơ'));
      await tester.pumpAndSettle();
      expect(api.calls, 1);
      expect(api.savedSkills, ['Xây', 'Tô']);
      expect(api.savedImages, ['https://example.com/photo.jpg']);
      expect(saved!.experienceYears, 5);
      expect(saved!.verified, isFalse);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
