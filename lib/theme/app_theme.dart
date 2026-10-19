// eCAT 可爱主题：奶油白 + 樱花粉 + 奶黄，大圆角、软阴影
// 深色模式：AppColors 按当前调色板（light/dark）动态取色，
// main.dart 启动时与主题模式变化时调用 AppColors.apply() 切换调色板。
library;

import 'package:flutter/material.dart';

/// 一套完整的调色板（浅色 / 深色各一份）
class AppPalette {
  // 主色：樱花粉
  final Color pink;
  final Color pinkLight;
  final Color pinkDeep;

  // 背景：奶油白（深色版为暖夜色）
  final Color cream;
  final Color card;

  // 辅助：奶黄 / 薄荷 / 天蓝
  final Color butter;
  final Color butterDeep;
  final Color mint;
  final Color mintDeep;
  final Color sky;
  final Color skyDeep;

  // 文字
  final Color textMain;
  final Color textSub;

  // 危险（过期提醒）
  final Color danger;

  const AppPalette({
    required this.pink,
    required this.pinkLight,
    required this.pinkDeep,
    required this.cream,
    required this.card,
    required this.butter,
    required this.butterDeep,
    required this.mint,
    required this.mintDeep,
    required this.sky,
    required this.skyDeep,
    required this.textMain,
    required this.textSub,
    required this.danger,
  });

  /// 浅色：奶油白 + 樱花粉（v1.0 起的原版配色）
  static const AppPalette light = AppPalette(
    pink: Color(0xFFF8A5B8),
    pinkLight: Color(0xFFFDE8EE),
    pinkDeep: Color(0xFFE8748F),
    cream: Color(0xFFFFFBF5),
    card: Colors.white,
    butter: Color(0xFFFFF3D6),
    butterDeep: Color(0xFFF5B942),
    mint: Color(0xFFDFF5EA),
    mintDeep: Color(0xFF5BBF8A),
    sky: Color(0xFFE3F0FD),
    skyDeep: Color(0xFF6FA8DC),
    textMain: Color(0xFF5C4A52),
    textSub: Color(0xFFA08A92),
    danger: Color(0xFFE86A6A),
  );

  /// 深色：暖夜色底 + 降饱和樱花粉，保持可爱氛围不刺眼
  static const AppPalette dark = AppPalette(
    pink: Color(0xFFD98CA0),
    pinkLight: Color(0xFF4A323B),
    pinkDeep: Color(0xFFE89AB0),
    cream: Color(0xFF221A1E),
    card: Color(0xFF2E2429),
    butter: Color(0xFF463A28),
    butterDeep: Color(0xFFE5B85C),
    mint: Color(0xFF28403A),
    mintDeep: Color(0xFF7CCFA4),
    sky: Color(0xFF2A3A4E),
    skyDeep: Color(0xFF8FB8E8),
    textMain: Color(0xFFF0E4E9),
    textSub: Color(0xFFA8969E),
    danger: Color(0xFFE87A7A),
  );
}

/// 全局颜色入口：用法与旧版一致（AppColors.pink 等），
/// 实际取值来自当前调色板 [_palette]，默认浅色。
class AppColors {
  /// 当前调色板（main.dart 在启动与主题模式变化时 apply）
  static AppPalette _palette = AppPalette.light;
  static AppPalette get palette => _palette;

  /// 切换调色板：ThemeMode.system 时按系统亮度，light/dark 直接指定
  static void apply(ThemeMode mode, Brightness systemBrightness) {
    final dark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && systemBrightness == Brightness.dark);
    _palette = dark ? AppPalette.dark : AppPalette.light;
  }

  static bool get isDark => identical(_palette, AppPalette.dark);

  // 主色：樱花粉
  static Color get pink => _palette.pink;
  static Color get pinkLight => _palette.pinkLight;
  static Color get pinkDeep => _palette.pinkDeep;

  // 背景：奶油白
  static Color get cream => _palette.cream;
  static Color get card => _palette.card;

  // 辅助：奶黄 / 薄荷 / 天蓝
  static Color get butter => _palette.butter;
  static Color get butterDeep => _palette.butterDeep;
  static Color get mint => _palette.mint;
  static Color get mintDeep => _palette.mintDeep;
  static Color get sky => _palette.sky;
  static Color get skyDeep => _palette.skyDeep;

  // 文字
  static Color get textMain => _palette.textMain;
  static Color get textSub => _palette.textSub;

  // 危险（过期提醒）
  static Color get danger => _palette.danger;
}

class AppTheme {
  static ThemeData get light => _build(AppPalette.light);

  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette c) => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: c.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: c.pink,
          primary: c.pinkDeep,
          surface: c.card,
          brightness:
              identical(c, AppPalette.dark) ? Brightness.dark : Brightness.light,
        ),
        fontFamily: null,
        appBarTheme: AppBarTheme(
          backgroundColor: c.cream,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: c.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: c.textMain),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: c.pink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: c.cream,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: c.pink, width: 2),
          ),
          hintStyle: TextStyle(color: c.textSub),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: c.card,
          selectedItemColor: c.pinkDeep,
          unselectedItemColor: c.textSub,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: c.card,
          surfaceTintColor: c.card,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: c.card,
          surfaceTintColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
}
