import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device choices; push preferences remain authoritative on the account API.
class DevicePreferences extends ChangeNotifier {
  static final instance = DevicePreferences();
  static const radii = [5.0, 10.0, 20.0, 50.0];
  bool _haptics = true;
  double _radius = 10;
  bool get haptics => _haptics;
  double get radius => _radius;
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _haptics = prefs.getBool('experience.haptics') ?? true;
      final radius = prefs.getDouble('experience.radius') ?? 10;
      _radius = radii.contains(radius) ? radius : 10;
    } catch (_) {
      _haptics = true;
      _radius = 10;
    }
    notifyListeners();
  }

  Future<bool> setHaptics(bool value) async {
    try {
      if (!await (await SharedPreferences.getInstance()).setBool(
        'experience.haptics',
        value,
      )) {
        return false;
      }
      _haptics = value;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setRadius(double value) async {
    if (!radii.contains(value)) return false;
    try {
      if (!await (await SharedPreferences.getInstance()).setDouble(
        'experience.radius',
        value,
      )) {
        return false;
      }
      _radius = value;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
