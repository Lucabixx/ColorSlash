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
      'https://www.googleapis.com/auth/drive.file', // Accesso ai file dell’app su Drive
    ],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService();

  // ----------------------------
  // 🔐 Metodi di autenticazione
  // ----------------------------

  /// Login anonimo (offline-ready)
  Future<User?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      notifyListeners();
      return cred.user;
    } catch (e) {
      debugPrint('❌ Errore signInAnonymously: $e');
      return null;
    }
  }

  /// Login via email e password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('⚠️ Email non verificata, inviata nuova verifica.');
      }

      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('❌ Errore login email: $e');
      return null;
    }
  }

  /// Registrazione nuovo utente
  Future<User?> registerWithEmail([String? email, String? password]) async {
    try {
      if (email == null || password == null || email.isEmpty || password.isEmpty) {
        debugPrint('⚠️ Email o password mancanti nella registrazione.');
        return null;
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user != null) {
        await user.sendEmailVerification();
        debugPrint('✅ Utente registrato e mail di verifica inviata.');
      }

      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('❌ Errore registrazione: $e');
      return null;
    }
  }

  /// Login con Google (sincronizzato a Drive)
  Future<User?> signInWithGoogle([BuildContext? context]) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // login annullato

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final result = await _auth.signInWithCredential(credential);

      notifyListeners();
      debugPrint('✅ Google Sign-In completato.');
      return result.user;
    } catch (e) {
      debugPrint('❌ Errore Google Sign-In: $e');
      return null;
    }
  }

  /// Integrazione futura: login con Microsoft / OneDrive
  Future<User?> signInWithMicrosoft() async {
    // TODO: integrare OAuth Microsoft tramite Azure e Firebase custom token
    debugPrint('⚠️ signInWithMicrosoft: da implementare');
    return null;
  }

  /// Logout completo (Firebase + Google)
  Future<void> signOut() async {
    try {
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Errore signOut Google: $e');
    }

    await _auth.signOut();
    notifyListeners();
  }

  // ----------------------------
  // ☁️ Sincronizzazione Cloud
  // ----------------------------

  /// Headers autenticazione Google REST API
  Future<Map<String, String>?> getGoogleAuthHeaders() async {
    try {
      final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) return null;

      final auth = await account.authentication;
      final token = auth.accessToken;
      if (token == null) return null;

      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };
    } catch (e) {
      debugPrint('❌ getGoogleAuthHeaders error: $e');
      return null;
    }
  }

  /// Upload locale su Google Drive
  Future<bool> uploadNotesFileToDrive(File file) async {
    try {
      final headers = await getGoogleAuthHeaders();
      if (headers == null) {
        debugPrint('❌ uploadNotesFileToDrive: no auth headers');
        return false;
      }

      final metadata = {'name': file.uri.pathSegments.last};

      final uri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': headers['Authorization'] ?? ''})
        ..fields['metadata'] = jsonEncode(metadata)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Drive upload OK: ${response.body}');
        return true;
      } else {
        debugPrint('❌ Drive upload failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ uploadNotesFileToDrive error: $e');
      return false;
    }
  }

  /// 🔄 Sincronizzazione completa: locale ↔ Firestore ↔ Google Drive
  Future<void> syncWithCloud(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Devi eseguire l’accesso per sincronizzare')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('☁️ Avvio sincronizzazione...')),
    );

    try {
      // 1️⃣ Recupera note da Firestore
      final snapshot = await _db
          .collection('notes')
          .where('userId', isEqualTo: user.uid)
          .get();

      final notesData =
          snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      // 2️⃣ Salva localmente
      await saveLocalNotesRaw(notesData);

      // 3️⃣ Esporta file su Google Drive (se login Google attivo)
      final file = await _getLocalNotesFile();
      final uploaded = await uploadNotesFileToDrive(file);

      if (uploaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Sincronizzazione completata con Drive')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Sincronizzazione Drive non riuscita')),
        );
      }
    } catch (e) {
      debugPrint('❌ syncWithCloud error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Errore sincronizzazione: $e')),
      );
    }
  }

  // ----------------------------
  // 📁 Gestione file locale
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
      debugPrint('❌ loadLocalNotesRaw error: $e');
      return [];
    }
  }

  Future<void> saveLocalNotesRaw(List<Map<String, dynamic>> notes) async {
    try {
      final file = await _getLocalNotesFile();
      await file.writeAsString(jsonEncode(notes));
    } catch (e) {
      debugPrint('❌ saveLocalNotesRaw error: $e');
    }
  }

  /// Utente corrente Firebase
  Future<User?> getUser() async => _auth.currentUser;
}
