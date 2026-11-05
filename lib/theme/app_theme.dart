import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2878C8);
  static const secondary = Color(0xFF79B9E8);
  static const cloudWhite = Color(0xFFF7FAFC);
  static const softBackground = Color(0xFFEAF3FA);
  static const textNavy = Color(0xFF172B4D);
  static const sunnyAccent = Color(0xFFF5B82E);
  static const rainAccent = Color(0xFF45A7D8);
  static const mutedText = Color(0xFF718096);
}

class AppTheme {
  static ThemeData lightTheme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cloudWhite,
    ),
    scaffoldBackgroundColor: AppColors.softBackground,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.mutedText),
      labelStyle: const TextStyle(color: AppColors.mutedText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    textTheme: Typography.material2021().black.apply(
      bodyColor: AppColors.textNavy,
      displayColor: AppColors.textNavy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.softBackground,
      foregroundColor: AppColors.textNavy,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withAlpha(28),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.mutedText,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
  );

  static ThemeData darkTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.secondary,
      secondary: AppColors.primary,
      surface: const Color(0xFF112033),
    ),
    scaffoldBackgroundColor: const Color(0xFF091827),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF12263B),
      hintStyle: const TextStyle(color: Color(0xFF9AAFC4)),
      labelStyle: const TextStyle(color: Color(0xFF9AAFC4)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF12263b),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    textTheme: Typography.material2021().white.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF091827),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
