// eCAT 可爱主题：奶油白 + 樱花粉 + 奶黄，大圆角、软阴影
library;

import 'package:flutter/material.dart';

class AppColors {
  // 主色：樱花粉
  static const Color pink = Color(0xFFF8A5B8);
  static const Color pinkLight = Color(0xFFFDE8EE);
  static const Color pinkDeep = Color(0xFFE8748F);

  // 背景：奶油白
  static const Color cream = Color(0xFFFFFBF5);
  static const Color card = Colors.white;

  // 辅助：奶黄 / 薄荷 / 天蓝 / 淡紫
  static const Color butter = Color(0xFFFFF3D6);
  static const Color butterDeep = Color(0xFFF5B942);
  static const Color mint = Color(0xFFDFF5EA);
  static const Color mintDeep = Color(0xFF5BBF8A);
  static const Color sky = Color(0xFFE3F0FD);
  static const Color skyDeep = Color(0xFF6FA8DC);

  // 文字
  static const Color textMain = Color(0xFF5C4A52);
  static const Color textSub = Color(0xFFA08A92);

  // 危险（过期提醒）
  static const Color danger = Color(0xFFE86A6A);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.pink,
          primary: AppColors.pinkDeep,
          surface: AppColors.card,
        ),
        fontFamily: null,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textMain),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: StadiumBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cream,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.pink, width: 2),
          ),
          hintStyle: const TextStyle(color: AppColors.textSub),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.pinkDeep,
          unselectedItemColor: AppColors.textSub,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
}
