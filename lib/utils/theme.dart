import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onPrimary: AppColors.textPrimary,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
      onError: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 2,
      titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    cardColor: AppColors.card,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.textPrimary,
    ),
    textTheme: TextTheme(
      bodyText1: TextStyle(color: AppColors.textPrimary),
      bodyText2: TextStyle(color: AppColors.textSecondary),
      headline6: TextStyle(color: AppColors.textPrimary),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.lightPrimary,
    colorScheme: ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
      error: AppColors.error,
      onPrimary: AppColors.lightTextPrimary,
      onSecondary: AppColors.lightTextPrimary,
      onSurface: AppColors.lightTextPrimary,
      onBackground: AppColors.lightTextPrimary,
      onError: AppColors.lightTextPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 1,
      titleTextStyle: TextStyle(color: AppColors.lightTextPrimary, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    cardColor: AppColors.lightSurface,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.lightAccent,
      foregroundColor: AppColors.lightTextPrimary,
    ),
    textTheme: TextTheme(
      bodyText1: TextStyle(color: AppColors.lightTextPrimary),
      bodyText2: TextStyle(color: AppColors.lightTextSecondary),
      headline6: TextStyle(color: AppColors.lightTextPrimary),
    ),
  );
}
