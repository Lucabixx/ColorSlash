// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloud_service.dart';
import 'local_storage.dart';

class AuthService extends ChangeNotifier {
  final _google = GoogleSignIn();
  final _auth = FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) return false;
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken);
      await _auth.signInWithCredential(credential);

      // after sign-in, upload local notes to cloud
      final notes = await LocalStorage.getAllNotes();
      await CloudService.uploadAllNotes(notes);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Google sign-in failed: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
    notifyListeners();
  }

  Future<void> syncWithCloud(BuildContext ctx) async {
    if (!isSignedIn) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Effettua il login con Google per sincronizzare')));
      return;
    }

    final notes = await LocalStorage.getAllNotes();
    await CloudService.uploadAllNotes(notes);
    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Sincronizzazione completata')));
  }
}
