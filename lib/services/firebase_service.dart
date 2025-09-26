import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();

  FirebaseService._private();
  static final FirebaseService instance = FirebaseService._private();

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user;
    } catch (e) {
      print('signInWithGoogle error: $e');
      rethrow;
    }
  }
}
