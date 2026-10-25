import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude, longitude;
}

class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
}

class LocationService {
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure('Hãy bật dịch vụ vị trí GPS trên thiết bị.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        kIsWeb ? 'Cho phép vị trí trong trình duyệt rồi thử lại.' : 'Cho phép Thợ Xây truy cập vị trí trong cài đặt thiết bị rồi thử lại.',
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on TimeoutException {
      throw const LocationFailure(
        'Chưa lấy được GPS. Hãy thử lại hoặc chọn vị trí tìm việc.',
      );
    } on LocationServiceDisabledException {
      throw const LocationFailure('Dịch vụ GPS đang tắt.');
    } on PermissionDeniedException {
      throw const LocationFailure('Quyền truy cập vị trí đã bị từ chối.');
    }
  }
}
