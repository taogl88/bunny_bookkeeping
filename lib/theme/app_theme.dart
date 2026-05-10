import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// 主色 - 黄色
  static const Color primary = Color(0xFFFBD835);

  /// 主色深色变体 - 用于图标高亮、选中态
  static const Color primaryDark = Color(0xFFE6A817);

  /// 浅黄背景 - 快捷操作图标背景
  static const Color primaryLight = Color(0xFFFFF8E1);

  /// 页面背景色
  static const Color scaffoldBg = Color(0xFFF5F5F5);

  /// 卡片/列表白色背景
  static const Color surface = Colors.white;

  /// 红点提示色
  static const Color badge = Colors.red;

  /// 主要文字
  static const Color textPrimary = Colors.black87;

  /// 次要文字
  static const Color textSecondary = Colors.black54;

  /// 浅灰色
  static const Color gray = Color(0x4DD9D9D6);

  /// 深灰色
  static const Color darkGray = Color(0x204A4A4A);

  //备注灰色框
  static const Color remarkGray = Color(0xFFF6F7F9);

  /// 背景灰色
  static const Color backgroundGray = Color(0xFFF5F6F8);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    // fontFamily: 'myFont',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.scaffoldBg,
  );
}
