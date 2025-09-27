import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  /// 🔹 Login con Email e Password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Errore login email: ${e.message}");
      return false;
    }
  }

  /// 🔹 Registrazione con Email e Password
  Future<bool> registerWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Errore registrazione: ${e.message}");
      return false;
    }
  }

  /// 🔹 Login con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Se nuovo utente, crealo su Firestore
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        if (!(await docRef.get()).exists) {
          await docRef.set({
            'email': user.email,
            'name': user.displayName,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      notifyListeners();
      return user;
    } catch (e) {
      debugPrint("Errore Google Sign-In: $e");
      return null;
    }
  }

  /// 🔹 Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint("Errore logout: $e");
    }
  }

  /// 🔹 Mock: sincronizza con il cloud
  Future<void> syncWithCloud(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sincronizzazione con il cloud...")),
    );

    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Sincronizzazione completata")),
    );
  }
}
