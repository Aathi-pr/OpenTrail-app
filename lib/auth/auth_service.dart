import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _googleSignIn.initialize(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
  }

  User? get currentUser => _auth.currentUser;

  String? get currentUserPhotoUrl {
    final photoUrl = _auth.currentUser?.photoURL;
    if (photoUrl == null) return null;

    return photoUrl.contains('=s96-c')
        ? photoUrl.replaceAll('=s96-c', '=s400-c')
        : photoUrl;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;


      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
