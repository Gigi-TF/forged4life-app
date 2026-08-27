import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Owns the light/dark choice and hands it to any widget that asks.
///
/// This replaces passing `onToggleTheme` down through constructors. That was
/// the bug: every screen that forgot the parameter got a null callback and a
/// button that silently did nothing.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _restore();
  }

  static const _storage = FlutterSecureStorage();
  static const _key = 'f4l_theme';

  /// null = follow the system.
  bool? _dark;

  ThemeMode get mode => switch (_dark) {
        null => ThemeMode.system,
        true => ThemeMode.dark,
        false => ThemeMode.light,
      };

  /// What is actually on screen right now, whether chosen or inherited.
  /// Reads the platform directly rather than through MediaQuery — the context
  /// above MaterialApp does not reliably carry platform brightness, which is
  /// why the old toggle sometimes flipped to the mode it was already in.
  bool get isDark =>
      _dark ??
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;

  void toggle() {
    _dark = !isDark;
    notifyListeners();
    _persist();
  }

  void followSystem() {
    _dark = null;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    // Secure storage is already a dependency, so this avoids adding
    // shared_preferences just to remember one boolean.
    await _storage.write(key: _key, value: _dark?.toString() ?? 'system');
  }

  Future<void> _restore() async {
    final v = await _storage.read(key: _key);
    if (v == null || v == 'system') return;
    _dark = v == 'true';
    notifyListeners();
  }

  /// `F4LTheme.of(context).toggle()` from anywhere below the provider.
  static ThemeController of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<F4LTheme>();
    assert(w != null, 'No F4LTheme found above this widget.');
    return w!.controller;
  }
}

class F4LTheme extends InheritedNotifier<ThemeController> {
  const F4LTheme({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  ThemeController get controller => notifier!;
}
