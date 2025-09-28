// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';

/// AuthService estende ChangeNotifier così può essere usato con Provider.
/// Contiene: login email/password (con verifica email), registrazione,
/// login Google, logout, e funzioni di sync locale <-> cloud (firebase/firestore).
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ----------------------------
  // Login con email e password
  // Se l'utente non ha verificato l'email invia la mail di verifica,
  // esegue signOut e restituisce null.
  // ----------------------------
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        // Invia mail di verifica se non verificata
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint("Impossibile inviare email di verifica: $e");
        }
        // Facciamo sign out per forzare la verifica
        await _auth.signOut();
        return null;
      }
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint("Errore login email: $e");
      return null;
    }
  }

  // ----------------------------
  // Registrazione con email e password
  // Dopo la creazione invia mail di verifica e ritorna User? (o null se errore)
  // ----------------------------
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null) {
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint("Errore invio verifica email: $e");
        }
      }
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint("Errore registrazione: $e");
      return null;
    }
  }

  // ----------------------------
  // Login con Google
  // ----------------------------
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // utente ha cancellato
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final result = await _auth.signInWithCredential(credential);
      notifyListeners();
      return result.user;
    } catch (e) {
      debugPrint("Errore Google Sign-In: $e");
      return null;
    }
  }

  // ----------------------------
  // Logout
  // ----------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      notifyListeners();
    } catch (e) {
      debugPrint("Errore signOut: $e");
    }
  }

  // ----------------------------
  // Funzioni locali per le note (file JSON) - helper
  // ----------------------------
  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  Future<List<Map<String, dynamic>>> _loadLocalNotes() async {
    final file = await _getLocalFile();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final List data = jsonDecode(content);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _saveLocalNotes(List<Map<String, dynamic>> notes) async {
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(notes));
  }

  // ----------------------------
  // Sincronizzazione bidirezionale locale <-> cloud (Firebase)
  // Nota: la struttura delle note deve essere coerente
  // (campo 'id' string, 'updatedAt' epoch int o ISO string convertibile)
  // ----------------------------
  Future<void> syncWithCloud(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nessun utente loggato")),
      );
      return;
    }

    try {
      // carica locali
      final localNotes = await _loadLocalNotes();

      // carica cloud
      final cloudSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();
      final cloudNotes = cloudSnap.docs
          .map((d) {
            final m = Map<String, dynamic>.from(d.data());
            m['id'] = d.id;
            return m;
          })
          .toList();

      final Map<String, Map<String, dynamic>> localMap = {
        for (var n in localNotes) n['id']: Map<String, dynamic>.from(n)
      };
      final Map<String, Map<String, dynamic>> cloudMap = {
        for (var n in cloudNotes) n['id']: Map<String, dynamic>.from(n)
      };

      final ids = {...localMap.keys, ...cloudMap.keys};

      for (final id in ids) {
        final local = localMap[id];
        final cloud = cloudMap[id];

        if (local == null && cloud != null) {
          // solo cloud -> aggiungi locally
          localNotes.add(cloud);
        } else if (cloud == null && local != null) {
          // solo local -> push su cloud
          await _db
              .collection('users')
              .doc(user.uid)
              .collection('notes')
              .doc(local['id'])
              .set(local);
        } else if (local != null && cloud != null) {
          // entrambi -> confronta timestamp
          final localTime = _parseTimestamp(local['updatedAt']);
          final cloudTime = _parseTimestamp(cloud['updatedAt']);
          if (localTime > cloudTime) {
            await _db
                .collection('users')
                .doc(user.uid)
                .collection('notes')
                .doc(local['id'])
                .set(local);
          } else if (cloudTime > localTime) {
            final index = localNotes.indexWhere((n) => n['id'] == id);
            if (index != -1) localNotes[index] = cloud;
          }
        }
      }

      // salva locali aggiornati
      await _saveLocalNotes(localNotes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sincronizzazione completata ✅")),
        );
      }
    } catch (e) {
      debugPrint("Errore durante la sincronizzazione: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore sincronizzazione: $e")),
        );
      }
    }
  }

  int _parseTimestamp(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) {
      try {
        return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }
}
