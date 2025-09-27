
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// 🔹 Inizializzazione Firebase centralizzata
class FirebaseService {
  static bool _initialized = false;

  /// Chiama questo metodo **una sola volta** all’avvio dell’app (es. nel main)
  static Future<void> initializeFirebase(BuildContext context) async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      debugPrint("❌ Errore inizializzazione Firebase: $e");

      // Mostra un messaggio d'errore visivo se serve
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore inizializzazione Firebase: $e")),
        );
      }
    }
  }
}
