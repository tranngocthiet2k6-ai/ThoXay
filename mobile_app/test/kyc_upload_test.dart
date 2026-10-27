import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/services/kyc_camera.dart';

class UploadClient extends http.BaseClient {
  int uploads = 0;
  bool locked = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Object data;
    int status = 200;
    if (request.url.path == '/api/auth/login') {
      data = {
        'token': 'jwt',
        'userId': 3,
        'fullName': 'Worker',
        'phoneNumber': '0900000003',
        'role': 'ROLE_WORKER',
        'expiresIn': 3600,
      };
    } else {
      uploads++;
      expect(request, isA<http.MultipartRequest>());
      final multipart = request as http.MultipartRequest;
      expect(multipart.method, 'POST');
      expect(multipart.url.path, '/api/users/me/cccd/photos');
      expect(multipart.headers['Authorization'], 'Bearer jwt');
      expect(multipart.files.map((f) => f.field), ['front', 'back']);
      expect(multipart.fields, isEmpty);
      expect(await multipart.files.first.finalize().toBytes(), [1, 2, 3]);
      expect(await multipart.files.last.finalize().toBytes(), [4, 5, 6]);
      data = locked
          ? {'code': 'ACCOUNT_LOCKED', 'message': 'Tài khoản bị khóa'}
          : {
              'id': 3,
              'fullName': 'Worker',
              'phoneNumber': '0900000003',
              'role': 'ROLE_WORKER',
              'verified': false,
              'rating': 5,
            };
      if (locked) status = 403;
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(data))),
      status,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('CCCD sends two binary parts with bearer authentication', () async {
    final client = UploadClient();
    final api = ApiService(client: client);
    await api.login('0900000003', 'password');
    final profile = await api.uploadCccd(
      KycPhoto(Uint8List.fromList([1, 2, 3])),
      KycPhoto(Uint8List.fromList([4, 5, 6])),
    );
    expect(profile.verified, false);
    expect(client.uploads, 1);
    api.dispose();
  });
  test('CCCD locked response removes the old authenticated session', () async {
    final client = UploadClient()..locked = true;
    final api = ApiService(client: client);
    await api.login('0900000003', 'password');
    await expectLater(
      api.uploadCccd(
        KycPhoto(Uint8List.fromList([1, 2, 3])),
        KycPhoto(Uint8List.fromList([4, 5, 6])),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(api.session, isNull);
    api.dispose();
  });
}
