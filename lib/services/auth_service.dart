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

  // 🔹 Sincronizzazione locale ↔ cloud (bozza)
  Future<void> syncWithCloud(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sincronizzazione completata")),
    );
  }

  // 🔹 Salva nota localmente
  Future<void> saveNoteLocally(Map<String, dynamic> note) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/notes.json");
    List notes = [];

    if (await file.exists()) {
      final data = await file.readAsString();
      notes = jsonDecode(data);
    }

    notes.add(note);
    await file.writeAsString(jsonEncode(notes));
  }
}
