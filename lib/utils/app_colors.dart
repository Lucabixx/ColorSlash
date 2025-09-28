import 'package:flutter/material.dart';

/// 🎨 Tavolozza colori di ColorSlash
/// Con effetto blu metallizzato 3D e bagliori luminosi
class AppColors {
  // 🌌 Blu metallizzato 3D (colore primario)
  static const Color primary = Color(0xFF0072FF); // blu elettrico metallizzato
  static const Color primaryLight = Color(0xFF4DA3FF); // riflesso chiaro
  static const Color primaryDark = Color(0xFF003C8F); // profondità metallizzata

  // 🌈 Gradiente principale
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF00B4FF), // Azzurro brillante
      Color(0xFF0072FF), // Blu elettrico
      Color(0xFF003C8F), // Blu profondo
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sfondo e superficie
  static const Color background = Color(0xFF0E0E10);
  static const Color surface = Color(0xFF1C1F24);
  static const Color cardBackground = Color(0xFF1E1E22);

  // Testi
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  // Stati
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFD50000);

  // Colori note
  static const List<Color> noteColors = [
    Colors.white,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  // Effetto glow blu
  static BoxShadow glow = BoxShadow(
    color: primaryLight.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: 2,
    offset: const Offset(0, 4),
  );
}
