// eCAT 全局设置状态：首次引导标记 / 主题模式 / 通知开关
// 与 CatStore 同模式：ChangeNotifier + SharedPreferences 持久化，
// main() 启动时 load() 一次，之后 setter 即改即存。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  bool _onboardingDone = false;
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _loaded = false;

  bool get onboardingDone => _onboardingDone;
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get loaded => _loaded;

  // ---------- 持久化 key（ecat_ 前缀与 CatStore 一致） ----------
  static const _kOnboarding = 'ecat_onboarding_done';
  static const _kThemeMode = 'ecat_theme_mode';
  static const _kNotify = 'ecat_notify_enabled';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _onboardingDone = sp.getBool(_kOnboarding) ?? false;
    _themeMode = _decodeThemeMode(sp.getString(_kThemeMode));
    _notificationsEnabled = sp.getBool(_kNotify) ?? true;
    _loaded = true;
    notifyListeners();
  }

  /// 完成首次引导（只写一次，重复调用幂等）
  Future<void> completeOnboarding() async {
    if (_onboardingDone) return;
    _onboardingDone = true;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kOnboarding, true);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kThemeMode, _encodeThemeMode(mode));
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled == _notificationsEnabled) return;
    _notificationsEnabled = enabled;
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kNotify, enabled);
    notifyListeners();
  }

  static ThemeMode _decodeThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
