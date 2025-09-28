import 'package:flutter/material.dart';

/// 🎨 Tavolozza colori principale di ColorSlash
class AppColors {
  // Colore primario del brand
  static const Color primary = Color(0xFF6A1B9A); // Viola principale

  // Colori di sfondo
  static const Color background = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);

  // Testi
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  // Azioni
  static const Color accent = Color(0xFF9C27B0);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFD50000);

  // Colori delle note
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
}
