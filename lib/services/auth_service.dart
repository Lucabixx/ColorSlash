import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService();

  // ----------------------------
  // 🔐 Autenticazione
  // ----------------------------

  Future<User?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      debugPrint('✅ Accesso anonimo riuscito (uid: ${cred.user?.uid})');
      notifyListeners();
      return cred.user;
    } catch (e) {
      debugPrint('❌ Errore signInAnonymously: $e');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('⚠️ Email non verificata, inviata nuova verifica.');
      }
      debugPrint('✅ Accesso email riuscito: $email');
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('❌ Errore login email: $e');
      return null;
    }
  }

  Future<User?> registerWithEmail([String? email, String? password]) async {
    try {
      if (email == null || password == null || email.isEmpty || password.isEmpty) {
        debugPrint('⚠️ Email o password mancanti nella registrazione.');
        return null;
      }

      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await user.sendEmailVerification();
        debugPrint('✅ Registrazione completata: $email');
      }

      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Errore FirebaseAuth: ${e.code} → ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Errore generico registrazione: $e');
      return null;
    }
  }

  /// 🔑 Google Sign-In con debug dettagliato
  Future<User?> signInWithGoogle([BuildContext? context]) async {
    debugPrint('🚀 Avvio Google Sign-In...');
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ Login Google annullato dall’utente');
        _showSnack(context, "Login Google annullato");
        return null;
      }

      debugPrint('📧 Utente Google selezionato: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Token Google non validi → accessToken: ${googleAuth.accessToken}, idToken: ${googleAuth.idToken}');
        _showSnack(context, "Errore Google Sign-In: token non valido");
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      debugPrint('🔄 In attesa di Firebase credential...');
      final result = await _auth.signInWithCredential(credential);

      if (result.user == null) {
        debugPrint('❌ Firebase non ha restituito un utente valido.');
        _showSnack(context, "Errore durante l’autenticazione Firebase.");
        return null;
      }

      debugPrint('✅ Google Sign-In completato per ${result.user?.email}');
      notifyListeners();
      return result.user;
    } on PlatformException catch (e) {
      debugPrint('❌ PlatformException durante Google Sign-In: ${e.code} → ${e.message}');
      _showSnack(context, "Errore piattaforma: ${e.message}");
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} → ${e.message}');
      _showSnack(context, "Errore Firebase: ${e.message}");
      return null;
    } catch (e) {
      debugPrint('❌ Errore generico Google Sign-In: $e');
      _showSnack(context, "Errore imprevisto: $e");
      return null;
    }
  }

  Future<User?> signInWithMicrosoft() async {
    debugPrint('⚠️ signInWithMicrosoft: da implementare');
    return null;
  }

  Future<void> signOut() async {
    try {
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
        debugPrint('👋 Logout Google completato');
      }
    } catch (e) {
      debugPrint('❌ Errore signOut Google: $e');
    }

    await _auth.signOut();
    debugPrint('✅ Logout Firebase completato');
    notifyListeners();
  }

  // ----------------------------
  // ☁️ Cloud + Drive
  // ----------------------------

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

  Future<bool> uploadNotesFileToDrive(File file) async {
    try {
      final headers = await getGoogleAuthHeaders();
      if (headers == null) {
        debugPrint('❌ uploadNotesFileToDrive: no auth headers');
        return false;
      }

      final metadata = {'name': file.uri.pathSegments.last};
      final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart');

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

  // Utility Snack
  void _showSnack(BuildContext? context, String msg) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      debugPrint('🔔 Snack: $msg');
    }
  }

  Future<File> _getLocalNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<User?> getUser() async => _auth.currentUser;
}
