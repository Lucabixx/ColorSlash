import 'package:flutter/material.dart';

/// AppColors: palette for both light and dark modes.
/// Provides core colors and gradients. Existing code that references
/// AppColors.primary, AppColors.primaryLight, AppColors.primaryDark, etc.
/// will keep working.
class AppColors {
  // --- Dark theme (default neon/metallic) ---
  static const Color primary = Color(0xFF00FFF5); // Neon Aqua
  static const Color primaryLight = Color(0xFF66FFF9);
  static const Color primaryDark = Color(0xFF00C7A8);

  static const Color secondary = Color(0xFFFF00E5); // Neon Magenta
  static const Color accent = Color(0xFFFFD700); // Bright gold

  static const Color background = Color(0xFF0D0D0D); // Almost black
  static const Color surface = Color(0xFF1A1A1A);
  static const Color card = surface;

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5); // Light metallic gray

  static const Color error = Color(0xFFFF1744);

  static const Color metallicShadow = Color(0xFF0A0A0A);

  // --- Light theme variants ---
  static const Color lightPrimary = Color(0xFF00695C);
  static const Color lightPrimaryLight = Color(0xFF338A7A);
  static const Color lightPrimaryDark = Color(0xFF003D33);

  static const Color lightSecondary = Color(0xFF8E24AA);
  static const Color lightAccent = Color(0xFFFFA000);

  static const Color lightBackground = Color(0xFFF6F9FC);
  static const Color lightSurface = Colors.white;

  static const Color lightTextPrimary = Color(0xFF0F1720); // almost black
  static const Color lightTextSecondary = Color(0xFF546E7A);

  // --- Gradients ---
  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00FFF5),
      Color(0xFFFF00E5),
    ],
  );

  static const LinearGradient fireGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF1744),
      Color(0xFFFF9100),
      Color(0xFFFFEA00),
    ],
  );

  // --- Helpers that return colors based on brightness ---
  static Color primaryFor(Brightness b) => b == Brightness.dark ? primary : lightPrimary;
  static Color secondaryFor(Brightness b) => b == Brightness.dark ? secondary : lightSecondary;
  static Color backgroundFor(Brightness b) => b == Brightness.dark ? background : lightBackground;
  static Color surfaceFor(Brightness b) => b == Brightness.dark ? surface : lightSurface;
  static Color textPrimaryFor(Brightness b) => b == Brightness.dark ? textPrimary : lightTextPrimary;
  static Color textSecondaryFor(Brightness b) => b == Brightness.dark ? textSecondary : lightTextSecondary;
  static Color accentFor(Brightness b) => b == Brightness.dark ? accent : lightAccent;
}
