import 'package:flutter/material.dart';

/// 🎨 Tavolozza colori principale in stile Blu Metallizzato 3D
class AppColors {
  // 🔹 Colori base
  static const Color primary = Color(0xFF1E88E5); // Blu metallizzato principale
  static const Color primaryLight = Color(0xFF64B5F6); // Luce metallizzata
  static const Color primaryDark = Color(0xFF0D47A1); // Ombra profonda

  // 🔹 Colori di superficie
  static const Color background = Color(0xFF0B0E16); // Sfondo quasi nero
  static const Color surface = Color(0xFF121826); // Superficie secondaria (card, box)
  static const Color cardBackground = Color(0xFF1B2333); // Card con effetto 3D

  // 🔹 Testi
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  // 🔹 Stati e feedback
  static const Color accent = Color(0xFF29B6F6); // Accento ciano metallizzato
  static const Color success = Color(0xFF00E676); // Verde brillante
  static const Color warning = Color(0xFFFFD54F); // Giallo caldo
  static const Color error = Color(0xFFFF5252); // Rosso neon

  // 🔹 Effetti di sfumatura (usati per 3D e luci)
  static const Gradient metallicGradient = LinearGradient(
    colors: [
      Color(0xFF42A5F5),
      Color(0xFF1E88E5),
      Color(0xFF0D47A1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🔹 Colori per note personalizzate
  static const List<Color> noteColors = [
    Colors.white,
    Color(0xFF90CAF9), // blu chiaro
    Color(0xFF80DEEA), // turchese
    Color(0xFF81C784), // verde chiaro
    Color(0xFFFFF59D), // giallo pastello
    Color(0xFFFFAB91), // arancio
    Color(0xFFF48FB1), // rosa tenue
    Color(0xFFCE93D8), // viola chiaro
  ];

  // 🔹 Ombre 3D per elementi fluttuanti
  static List<BoxShadow> metallicShadow = [
    BoxShadow(
      color: primaryLight.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(-4, -4),
    ),
    BoxShadow(
      color: primaryDark.withOpacity(0.6),
      blurRadius: 16,
      offset: const Offset(6, 6),
    ),
  ];
}
