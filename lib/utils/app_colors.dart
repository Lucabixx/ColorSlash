import 'package:flutter/material.dart';

/// 🎨 Tavolozza principale di ColorSlash (blu metallico 3D)
class AppColors {
  // Palette principale (blu metallico)
  static const Color primary = Color(0xFF2979FF); // Blu brillante
  static const Color primaryLight = Color(0xFF82B1FF); // Blu chiaro
  static const Color primaryDark = Color(0xFF004C8C); // Blu profondo

  static const Color accent = Color(0xFF00E5FF); // Ciano metallico
  static const Color secondary = Color(0xFF00BFA5);

  // Backgrounds
  static const Color background = Color(0xFF0D1117); // Nero grafite
  static const Color surface = Color(0xFF1C1F26); // Blu-grigio scuro
  static const Color bgColor = background; // alias usato nello splash

  // Testo
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF78909C);

  // Stati
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD740);

  // Gradients metallici
  static const LinearGradient metallicGradient = LinearGradient(
    colors: [
      Color(0xFF004C8C), // Blu profondo
      Color(0xFF2979FF), // Blu acceso
      Color(0xFF00E5FF), // Ciano brillante
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [
      Color(0xFF1565C0),
      Color(0xFF42A5F5),
      Color(0xFF80DEEA),
    ],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // Shadow helpers (metallic 3D look)
  static List<BoxShadow> metallicShadow = [
    BoxShadow(
      color: primaryLight.withOpacity(0.36),
      blurRadius: 12,
      spreadRadius: 1,
      offset: const Offset(2, 3),
    ),
    BoxShadow(
      color: primaryDark.withOpacity(0.32),
      blurRadius: 20,
      offset: const Offset(-3, -2),
    ),
  ];

  // Colori rapidi per le note
  static const List<Color> noteColors = [
    Color(0xFF2979FF),
    Color(0xFF00E5FF),
    Color(0xFF00BFA5),
    Color(0xFFFFC400),
    Color(0xFFFF4081),
    Color(0xFF7C4DFF),
    Color(0xFF76FF03),
    Color(0xFFFF6E40),
  ];
}
