// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file', // per upload su Drive (file per-app)
    ],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService() {
    // Puoi aggiungere eventuali listener all'avvio se vuoi
  }

  // ----------------------------
  // Autenticazioni
  // ----------------------------
  Future<User?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      notifyListeners();
      return cred.user;
    } catch (e) {
      debugPrint('Errore signInAnonymously: $e');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      // se vuoi forzare la verifica email:
      if (user != null && !user.emailVerified) {
        // invia email di verifica e fai logout (opzionale)
        await user.sendEmailVerification();
        // await _auth.signOut();
        // return null;
      }
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('Errore login email: $e');
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
      debugPrint('Errore registrazione: $e');
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
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
      debugPrint('Errore Google Sign-In: $e');
      return null;
    }
  }

  /// Stub / scaffold per Microsoft sign-in (OneDrive). Implementazione completa richiede
  /// registrare l'app su Azure AD, gestire redirect URI e token OAuth.
  Future<User?> signInWithMicrosoft() async {
    // TODO: Implementare flusso OAuth Microsoft (Azure) con WebView / external browser
    // e poi creare account Firebase custom token oppure associare all'utente.
    debugPrint('signInWithMicrosoft: non implementato, vedi TODO');
    return null;
  }

  Future<void> signOut() async {
    try {
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
    notifyListeners();
  }

  // ----------------------------
  // Helper per Google Drive upload
  // ----------------------------
  /// Recupera headers di autenticazione (Bearer) per chiamate Google REST API
  Future<Map<String, String>?> getGoogleAuthHeaders() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        // prova silent sign in
        final silent = await _googleSignIn.signInSilently();
        if (silent == null) return null;
      }
      final auth = await _googleSignIn.currentUser?.authentication;
      final token = auth?.accessToken;
      if (token == null) return null;
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };
    } catch (e) {
      debugPrint('getGoogleAuthHeaders error: $e');
      return null;
    }
  }

  /// upload file JSON notes.json su Google Drive (cartella per-app)
  /// Se vuoi un comportamento più ricercato (es. aggiornare se già esiste), va esteso.
  Future<bool> uploadNotesFileToDrive(File file) async {
    try {
      final headers = await getGoogleAuthHeaders();
      if (headers == null) {
        debugPrint('uploadNotesFileToDrive: no google headers');
        return false;
      }

      // Carica file in multipart (metadata + content)
      final metadata = {
        'name': file.uri.pathSegments.last,
        // 'parents': ['appDataFolder'] // puoi usare 'appDataFolder' per spazio privato dell'app
      };

      final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': headers['Authorization'] ?? ''});

      request.fields['metadata'] = jsonEncode(metadata);
      request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: file.uri.pathSegments.last));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Drive upload OK: ${response.body}');
        return true;
      } else {
        debugPrint('Drive upload failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('uploadNotesFileToDrive error: $e');
      return false;
    }
  }

  // ----------------------------
  // Funzioni locali utili per sync
  // ----------------------------
  Future<File> _getLocalNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<List<Map<String, dynamic>>> loadLocalNotesRaw() async {
    try {
      final file = await _getLocalNotesFile();
      if (!await file.exists()) return [];
      final s = await file.readAsString();
      final decoded = jsonDecode(s) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('loadLocalNotesRaw error: $e');
      return [];
    }
  }

  Future<void> saveLocalNotesRaw(List<Map<String, dynamic>> notes) async {
    try {
      final file = await _getLocalNotesFile();
      await file.writeAsString(jsonEncode(notes));
    } catch (e) {
      debugPrint('saveLocalNotesRaw error: $e');
    }
  }

  // helper pubblico
  Future<User?> getUser() async => _auth.currentUser;
}
