import 'package:flutter/material.dart';

class AppColors {
  static const accent   = Color(0xFFE07A3A);
  static const green    = Color(0xFF5A9E6F);
  static const bg       = Color(0xFFF8F6F2);
  static const card     = Colors.white;
  static const border   = Color(0xFFE5E0D8);
  static const muted    = Color(0xFF888888);
  static const tagBg    = Color(0xFFF0ECE4);
  static const hitBg    = Color(0xFFE8F5EC);
  static const missBg   = Color(0xFFFDF2F2);
  static const partialBg = Color(0xFFFFF4E8);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.bg,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    cardColor: AppColors.card,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: Color(0xFF2C2C2C),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFF2C2C2C),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.accent.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.tagBg,
      labelStyle: const TextStyle(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
