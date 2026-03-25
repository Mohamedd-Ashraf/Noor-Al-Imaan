import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Authentication and Google Sign-In into a single service.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Current Firebase user (null when signed out or guest).
  User? get currentUser => _auth.currentUser;

  /// Whether the user is currently authenticated (not anonymous).
  bool get isAuthenticated {
    final user = currentUser;
    return user != null && !user.isAnonymous;
  }

  /// Whether the user is in guest mode (anonymous auth).
  bool get isGuest {
    final user = currentUser;
    return user != null && user.isAnonymous;
  }

  /// Real-time auth state stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Google Sign-In ──────────────────────────────────────────────────────

  /// Signs in with Google. Returns the [UserCredential] on success.
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthCancelledException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // If already signed in anonymously, link the Google credential.
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        return await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // Another account already uses this Google credential.
          // Sign out anonymous, sign in with Google directly.
          await _auth.signOut();
          return await _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }

    return await _auth.signInWithCredential(credential);
  }

  // ── Email / Password ────────────────────────────────────────────────────

  /// Creates a new account with email & password.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    // If already signed in anonymously, link email credential.
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      try {
        return await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          await _auth.signOut();
          return await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
        rethrow;
      }
    }

    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with an existing email & password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sends a password-reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Guest (anonymous) ───────────────────────────────────────────────────

  /// Signs in anonymously (guest mode).
  Future<UserCredential> signInAsGuest() async {
    return await _auth.signInAnonymously();
  }

  // ── Sign Out ────────────────────────────────────────────────────────────

  /// Signs out of Firebase and Google.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn.signOut failed: $e');
    }
    await _auth.signOut();
  }

  // ── Account Deletion ────────────────────────────────────────────────────

  /// Deletes the current user account.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await user.delete();
  }
}

/// Custom exception for auth-cancelled scenarios.
class AuthCancelledException implements Exception {
  final String code;
  final String message;
  const AuthCancelledException({required this.code, required this.message});

  @override
  String toString() => 'AuthCancelledException($code): $message';
}
