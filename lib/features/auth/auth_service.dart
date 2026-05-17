import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  // Aktuálny používateľ
  static User? get currentUser => _auth.currentUser;

  // Stream zmien auth stavu
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  // Email + heslo — registrácia
  static Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vezmi meno z emailu — časť pred @
      final name = email.split('@').first;

      // Nastav displayName
      await credential.user?.updateDisplayName(name);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Email + heslo — prihlásenie
  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Facebook Sign-In
  static Future<UserCredential?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile'], // email vymazať
      );
      if (result.status != LoginStatus.success) return null;

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Facebook Sign-In error: $e');
      return null;
    }
  }

  static Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign-in error: $e');
      return null;
    }
  }

  // Odhlásenie
  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken != null) {
        await FacebookAuth.instance.logOut();
      }
    } catch (_) {}

    await _auth.signOut();
  }

  // Preklad chybových kódov
  static String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Tento email je už použitý.';
      case 'invalid-email':
        return 'Neplatný formát emailu.';
      case 'weak-password':
        return 'Heslo musí mať aspoň 6 znakov.';
      case 'user-not-found':
        return 'Účet s týmto emailom neexistuje.';
      case 'wrong-password':
        return 'Nesprávne heslo.';
      case 'invalid-credential':
        return 'Nesprávny email alebo heslo.';
      case 'user-disabled':
        return 'Tento účet bol zablokovaný.';
      case 'too-many-requests':
        return 'Príliš veľa pokusov. Skús to neskôr.';
      case 'network-request-failed':
        return 'Skontroluj internetové pripojenie.';
      case 'operation-not-allowed':
        return 'Tento spôsob prihlásenia nie je povolený.';
      default:
        return 'Nastala chyba ($code). Skús znova.';
    }
  }
}
