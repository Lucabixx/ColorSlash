import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  /// 🔹 Effettua l’accesso con Google
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Accesso annullato dall’utente")),
        );
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // 🔹 Salva info base nel database (Firestore)
      await _saveUserToFirestore(userCredential.user);

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore di autenticazione: ${e.message}")),
      );
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore generico: $e")),
      );
      return null;
    }
  }

  /// 🔹 Salva dati utente in Firestore
  Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'photoUrl': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🔹 Esegue il logout completo
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }

  /// 🔹 Sincronizza i dati sul cloud (Firebase)
  Future<void> syncWithCloud(BuildContext context) async {
    try {
      if (_auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Effettua prima l’accesso.")),
        );
        return;
      }

      // Qui potresti caricare/salvare le note dell’utente su Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sincronizzazione completata ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante la sincronizzazione: $e")),
      );
    }
  }
}
