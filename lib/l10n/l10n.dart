import 'package:flutter/material.dart';

/// Classe che definisce le lingue supportate dall'app.
class L10n {
  /// Lista delle lingue disponibili
  static final all = [
    const Locale('en'), // Inglese
    const Locale('it'), // Italiano
  ];

  /// Restituisce la bandiera o il nome leggibile della lingua
  static String getFlag(String code) {
    switch (code) {
      case 'en':
        return '🇬🇧 English';
      case 'it':
        return '🇮🇹 Italiano';
      default:
        return code;
    }
  }
}