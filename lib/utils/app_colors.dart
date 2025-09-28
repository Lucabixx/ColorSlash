import 'package:flutter/material.dart';

/// 🎨 Tavolozza colori principale di ColorSlash
class AppColors {
  // 🔹 Colore primario: blu metallizzato 3D
  static const Color primary = Color(0xFF0D47A1); // Blu profondo
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color primaryDark = Color(0xFF002171);

  // 🔹 Gradiente effetto "metallo 3D"
  static const LinearGradient metallicGradient = LinearGradient(
    colors: [
      Color(0xFF0D47A1), // base blu
      Color(0xFF1976D2), // blu acceso
      Color(0xFF64B5F6), // riflesso
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🔹 Colori di sfondo (dark mode)
  static const Color background = Color(0xFF0F111A);
  static const Color surface = Color(0xFF1C1E26);
  static const Color cardBackground = Color(0xFF232530);

  // 🔹 Testi
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  // 🔹 Azioni e stati
  static const Color accent = Color(0xFF2196F3); // blu chiaro d'accento
  static const Color success = Color(0xFF00C853); // verde
  static const Color warning = Color(0xFFFFC107); // giallo
  static const Color error = Color(0xFFD50000);   // rosso

  // 🔹 Colori selezionabili per note/liste
  static const List<Color> noteColors = [
    Colors.white,
    Color(0xFFFF8A80),
    Color(0xFFFFD180),
    Color(0xFFFFFF8D),
    Color(0xFFA5D6A7),
    Color(0xFF81D4FA),
    Color(0xFFCE93D8),
    Color(0xFFF48FB1),
  ];

  // 🔹 Ombre e bagliori per effetto 3D
  static final BoxShadow softShadow = BoxShadow(
    color: Colors.black.withOpacity(0.4),
    blurRadius: 12,
    offset: const Offset(2, 4),
  );

  static final BoxShadow glow = BoxShadow(
    color: primaryLight.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: 2,
  );
}
