import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE86F51);
  static const Color primaryDark = Color(0xFF9F3F2B);
  static const Color primaryLight = Color(0xFFFFE7DF);
  static const Color scaffoldBg = Color(0xFFF7F0EA);
  static const Color surface = Color(0xFFFFFCF9);
  static const Color surfaceStrong = Color(0xFFF0DFD4);
  static const Color badge = Color(0xFFD64444);
  static const Color textPrimary = Color(0xFF241A16);
  static const Color textSecondary = Color(0xFF7C6A60);
  static const Color gray = Color(0xFFD8C8BC);
  static const Color darkGray = Color(0x1F4A3429);
  static const Color remarkGray = Color(0xFFF6EEE8);
  static const Color backgroundGray = Color(0xFFF4ECE5);
  static const Color accent = Color(0xFF2F7A78);
  static const Color accentSoft = Color(0xFFDDF1EE);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: Color(0xFFB83A2F),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.scaffoldBg,
    canvasColor: AppColors.surface,
    cardColor: AppColors.surface,
    dividerColor: AppColors.darkGray,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
