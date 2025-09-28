import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // 🔹 Login con Email e Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint("Errore login: $e");
      return null;
    }
  }

  // 🔹 Registrazione nuovo utente
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint("Errore registrazione: $e");
      return null;
    }
  }

  // 🔹 Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // =====================================================
  // 📂 GESTIONE FILE LOCALI
  // =====================================================

  Future<Directory> _getNotesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final notesDir = Directory('${dir.path}/notes');
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir;
  }

  // 🔸 Salva una nota in locale
  Future<void> saveNoteLocally(String id, Map<String, dynamic> data) async {
    final dir = await _getNotesDir();
    final file = File('${dir.path}/$id.json');
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await file.writeAsString(jsonEncode(data));
  }

  // 🔸 Carica tutte le note locali
  Future<List<Map<String, dynamic>>> loadLocalNotes() async {
    final dir = await _getNotesDir();
    final files = dir.listSync().whereType<File>();
    List<Map<String, dynamic>> notes = [];

    for (var file in files) {
      try {
        final content = await file.readAsString();
        final jsonData = jsonDecode(content);
        notes.add(jsonData);
      } catch (e) {
        debugPrint("Errore lettura file ${file.path}: $e");
      }
    }
    return notes;
  }

  // 🔸 Elimina una nota locale
  Future<void> deleteNoteLocally(String id) async {
    final dir = await _getNotesDir();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // =====================================================
  // 🔄 SINCRONIZZAZIONE BIDIREZIONALE CON FIRESTORE
  // =====================================================

  Future<void> syncWithCloud(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Devi prima accedere per sincronizzare.")),
      );
      return;
    }

    try {
      final notesDir = await _getNotesDir();
      final localFiles = notesDir.listSync().whereType<File>().toList();

      final cloudCollection =
          _firestore.collection('users').doc(user.uid).collection('notes');

      // 🔼 UPLOAD — Invia le note locali più aggiornate
      for (var file in localFiles) {
        final id = file.uri.pathSegments.last.replaceAll('.json', '');
        final localJson = jsonDecode(await file.readAsString());
        final docRef = cloudCollection.doc(id);
        final cloudDoc = await docRef.get();

        if (!cloudDoc.exists ||
            (cloudDoc.data()?['updatedAt'] ?? 0) < (localJson['updatedAt'] ?? 0)) {
          await docRef.set(localJson, SetOptions(merge: true));
        }
      }

      // 🔽 DOWNLOAD — Scarica note più recenti dal cloud
      final snapshot = await cloudCollection.get();
      for (var doc in snapshot.docs) {
        final id = doc.id;
        final filePath = '${notesDir.path}/$id.json';
        final file = File(filePath);

        final cloudData = doc.data();
        final exists = await file.exists();

        if (!exists) {
          await file.writeAsString(jsonEncode(cloudData));
        } else {
          final localData = jsonDecode(await file.readAsString());
          if ((cloudData['updatedAt'] ?? 0) > (localData['updatedAt'] ?? 0)) {
            await file.writeAsString(jsonEncode(cloudData));
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sincronizzazione completata!")),
      );
    } catch (e) {
      debugPrint("Errore syncWithCloud: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante la sincronizzazione: $e")),
      );
    }
  }
}
