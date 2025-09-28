import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // 🔹 Login con email e password -> ritorna true se OK
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user != null;
    } catch (e) {
      debugPrint("Errore login email: $e");
      return false;
    }
  }

  // 🔹 Registrazione con email e password -> ritorna true se OK
  Future<bool> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user != null;
    } catch (e) {
      debugPrint("Errore registrazione: $e");
      return false;
    }
  }

  // 🔹 Login con Google -> ritorna User? (null se annullato/errore)
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      debugPrint("Errore Google Sign-In: $e");
      return null;
    }
  }

  // 🔹 Logout
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    notifyListeners();
  }

  // 🔹 Percorso del file locale
  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  // 🔹 Carica note locali
  Future<List<Map<String, dynamic>>> _loadLocalNotes() async {
    final file = await _getLocalFile();
    if (!await file.exists()) return <Map<String, dynamic>>[];
    final content = await file.readAsString();
    final List data = jsonDecode(content);
    return data.cast<Map<String, dynamic>>();
  }

  // 🔹 Salva note localmente
  Future<void> _saveLocalNotes(List<Map<String, dynamic>> notes) async {
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(notes));
  }

  // 🔹 Sincronizzazione locale ↔ cloud (bidirezionale)
  // Richiede che l'utente sia loggato. Usa campi 'id' e 'updatedAt' (o 'lastModified') come timestamp.
  Future<void> syncWithCloud(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nessun utente loggato")),
        );
      }
      return;
    }

    try {
      final localNotes = await _loadLocalNotes(); // List<Map<String,dynamic>>
      final cloudSnap = await _db.collection('users').doc(user.uid).collection('notes').get();
      final cloudNotes = cloudSnap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return m;
      }).toList();

      // Mappe per ricerca rapida
      final localMap = {for (var n in localNotes) n['id'] as String: n};
      final cloudMap = {for (var n in cloudNotes) n['id'] as String: n};

      // Unione chiavi
      final allIds = {...localMap.keys, ...cloudMap.keys};

      for (final id in allIds) {
        final local = localMap[id];
        final cloud = cloudMap[id];

        if (local == null && cloud != null) {
          // solo cloud -> aggiungi localmente
          localNotes.add(cloud);
        } else if (cloud == null && local != null) {
          // solo local -> salva su cloud
          await _db
              .collection('users')
              .doc(user.uid)
              .collection('notes')
              .doc(local['id'] as String)
              .set(Map<String, dynamic>.from(local));
        } else if (local != null && cloud != null) {
          // entrambi: confronta timestamp (usa 'updatedAt' o 'lastModified')
          final localTime = _parseTimestamp(local['updatedAt'] ?? local['lastModified']);
          final cloudTime = _parseTimestamp(cloud['updatedAt'] ?? cloud['lastModified']);

          if (localTime.isAfter(cloudTime)) {
            // local più recente -> push cloud
            await _db
                .collection('users')
                .doc(user.uid)
                .collection('notes')
                .doc(local['id'] as String)
                .set(Map<String, dynamic>.from(local));
          } else if (cloudTime.isAfter(localTime)) {
            // cloud più recente -> sostituisci in locale
            final index = localNotes.indexWhere((n) => n['id'] == id);
            if (index != -1) localNotes[index] = cloud;
          }
        }
      }

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

  DateTime _parseTimestamp(dynamic t) {
    if (t == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (t is int) return DateTime.fromMillisecondsSinceEpoch(t);
    if (t is String) {
      try {
        return DateTime.parse(t);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
