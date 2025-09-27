import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloud_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();
  final CloudService _cloud = CloudService();

  bool get isSignedIn => _auth.currentUser != null;

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) return false;
      final authData = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: authData.accessToken,
        idToken: authData.idToken,
      );
      await _auth.signInWithCredential(credential);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Errore login Google: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
    notifyListeners();
  }

  Future<void> syncWithCloud(BuildContext context) async {
    if (!isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Effettua il login con Google")),
      );
      return;
    }
    await _cloud.uploadAllNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sincronizzazione completata ✅")),
    );
  }
}
