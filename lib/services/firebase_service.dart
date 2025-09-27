import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initializeFirebase(BuildContext context) async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      debugPrint("❌ Errore inizializzazione Firebase: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore inizializzazione Firebase: $e")),
        );
      }
    }
  }
}
