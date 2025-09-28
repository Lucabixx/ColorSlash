import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        // invia mail verifica
        await user.sendEmailVerification();
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

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await user.sendEmailVerification();
      }
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint("Errore registrazione: $e");
      return null;
    }
  }

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
      notifyListeners();
      return result.user;
    } catch (e) {
      debugPrint("Errore Google Sign-In: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    notifyListeners();
  }

  // --- Funzioni locali e sync (come vedi prima) ---
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
      final localNotes = await _loadLocalNotes();
      final cloudSnap = await _db.collection('users').doc(user.uid).collection('notes').get();
      final cloudNotes = cloudSnap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return m;
      }).toList();

      final localMap = {for (var n in localNotes) n['id']: n};
      final cloudMap = {for (var n in cloudNotes) n['id']: n};

      final ids = {...localMap.keys, ...cloudMap.keys};

      for (final id in ids) {
        final local = localMap[id];
        final cloud = cloudMap[id];
        if (local == null && cloud != null) {
          localNotes.add(cloud);
        } else if (cloud == null && local != null) {
          await _db.collection('users').doc(user.uid).collection('notes').doc(local['id']).set(local);
        } else if (local != null && cloud != null) {
          final lt = _parseTimestamp(local['updatedAt']);
          final ct = _parseTimestamp(cloud['updatedAt']);
          if (lt > ct) {
            await _db.collection('users').doc(user.uid).collection('notes').doc(local['id']).set(local);
          } else if (ct > lt) {
            final idx = localNotes.indexWhere((n) => n['id'] == id);
            if (idx != -1) localNotes[idx] = cloud;
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
      debugPrint("Errore sincronizzazione: $e");
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
