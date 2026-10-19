// SettingsStore 单元测试：默认值、持久化读写、幂等性
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecat/store/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsStore', () {
    test('默认值：未完成引导 / 跟随系统 / 通知开启', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsStore();
      await s.load();

      expect(s.onboardingDone, isFalse);
      expect(s.themeMode, ThemeMode.system);
      expect(s.notificationsEnabled, isTrue);
      expect(s.loaded, isTrue);
    });

    test('完成引导后持久化，重新 load 仍生效', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsStore();
      await s.load();
      await s.completeOnboarding();

      // 模拟重启：新实例从同一份 mock 存储读取
      final s2 = SettingsStore();
      await s2.load();
      expect(s2.onboardingDone, isTrue);
    });

    test('completeOnboarding 幂等：重复调用不报错', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsStore();
      await s.load();
      await s.completeOnboarding();
      await s.completeOnboarding();
      expect(s.onboardingDone, isTrue);
    });

    test('主题模式三态切换并持久化', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsStore();
      await s.load();

      await s.setThemeMode(ThemeMode.dark);
      expect(s.themeMode, ThemeMode.dark);

      await s.setThemeMode(ThemeMode.light);
      expect(s.themeMode, ThemeMode.light);

      final s2 = SettingsStore();
      await s2.load();
      expect(s2.themeMode, ThemeMode.light);
    });

    test('旧版本无主题 key 时回退跟随系统', () async {
      SharedPreferences.setMockInitialValues({'ecat_onboarding_done': true});
      final s = SettingsStore();
      await s.load();
      expect(s.onboardingDone, isTrue);
      expect(s.themeMode, ThemeMode.system);
    });

    test('通知开关切换并持久化', () async {
      SharedPreferences.setMockInitialValues({});
      final s = SettingsStore();
      await s.load();

      await s.setNotificationsEnabled(false);
      expect(s.notificationsEnabled, isFalse);

      final s2 = SettingsStore();
      await s2.load();
      expect(s2.notificationsEnabled, isFalse);
    });

    test('非法主题字符串回退跟随系统', () async {
      SharedPreferences.setMockInitialValues({'ecat_theme_mode': 'xxx'});
      final s = SettingsStore();
      await s.load();
      expect(s.themeMode, ThemeMode.system);
    });
  });
}
