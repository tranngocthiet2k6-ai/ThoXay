import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode { light, dark, outdoor }

class AppearanceController extends ChangeNotifier {
  DisplayMode _mode = DisplayMode.light;
  DisplayMode get mode => _mode;
  Brightness get brightness =>
      _mode == DisplayMode.dark ? Brightness.dark : Brightness.light;
  Future<void> _saving = Future.value();
  Future<void> restore() async {
    try {
      final value = (await SharedPreferences.getInstance()).getString(
        'display_mode',
      );
      _mode =
          DisplayMode.values.where((mode) => mode.name == value).firstOrNull ??
          DisplayMode.light;
    } catch (_) {
      _mode = DisplayMode.light;
    }
  }

  Future<bool> setMode(DisplayMode mode) async {
    _mode = mode;
    notifyListeners();
    bool saved = false;
    _saving = _saving.then((_) async {
      try {
        saved = await (await SharedPreferences.getInstance()).setString(
          'display_mode',
          mode.name,
        );
      } catch (_) {
        saved = false;
      }
    });
    await _saving;
    return saved;
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppearanceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}
