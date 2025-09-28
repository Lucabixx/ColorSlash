import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // 🔹 Login con email e password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      debugPrint("Errore login email: $e");
      return null;
    }
  }

  // 🔹 Registrazione con email e password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      debugPrint("Errore registrazione: $e");
      return null;
    }
  }

  // 🔹 Login con Google
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
    await GoogleSignIn().signOut();
  }

  // 🔹 Percorso del file locale
  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  // 🔹 Carica note locali
  Future<List<Map<String, dynamic>>> _loadLocalNotes() async {
    final file = await _getLocalFile();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final List data = jsonDecode(content);
    return data.cast<Map<String, dynamic>>();
  }

  // 🔹 Salva note localmente
  Future<void> _saveLocalNotes(List<Map<String, dynamic>> notes) async {
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(notes));
  }

  // 🔹 Sincronizzazione locale ↔ cloud
  Future<void> syncWithCloud(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nessun utente loggato")),
      );
      return;
    }

    try {
      final localNotes = await _loadLocalNotes();

      final cloudSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();

      final cloudNotes =
          cloudSnap.docs.map((d) => d.data()..['id'] = d.id).toList();

      // Mappa ID → Nota
      final localMap = {for (var n in localNotes) n['id']: n};
      final cloudMap = {for (var n in cloudNotes) n['id']: n};

      // 🔁 Sincronizzazione bidirezionale
      for (var id in {...localMap.keys, ...cloudMap.keys}) {
        final local = localMap[id];
        final cloud = cloudMap[id];

        if (local == null && cloud != null) {
          // Esiste solo nel cloud → aggiungi in locale
          localNotes.add(cloud);
        } else if (cloud == null && local != null) {
          // Esiste solo in locale → aggiungi nel cloud
          await _db
              .collection('users')
              .doc(user.uid)
              .collection('notes')
              .doc(local['id'])
              .set(local);
        } else if (local != null && cloud != null) {
          // Esistono entrambi → confronta timestamp
          final localTime = local['updatedAt'] ?? 0;
          final cloudTime = cloud['updatedAt'] ?? 0;
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

      await _saveLocalNotes(localNotes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sincronizzazione completata ✅")),
      );
    } catch (e) {
      debugPrint("Errore durante la sincronizzazione: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore sincronizzazione: $e")),
      );
    }
  }
}
