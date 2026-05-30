import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'auth_service.dart';
import '../logging/error_logger.dart';

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return _mapUser(fbUser);
    });
  }

  @override
  AuthUser? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _mapUser(fbUser);
  }

  AuthUser _mapUser(fb.User fbUser) {
    return AuthUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<AuthUser> signUp(String email, String password,
      {String? displayName}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }
      final user = _auth.currentUser;
      if (user == null) throw const AuthException('Account creation failed.');
      return _mapUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<AuthUser> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const AuthException('Sign in failed.');
      return _mapUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final provider = fb.GoogleAuthProvider();
      final fb.UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(provider);
      } else {
        credential = await _auth.signInWithProvider(provider);
      }
      final user = credential.user;
      if (user == null) throw const AuthException('Google sign-in failed.');
      return _mapUser(user);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('Not signed in.');
    await user.updateDisplayName(name.trim());
    await user.reload();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('Not signed in.');
    try {
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthException(
          'Please sign out and sign back in before deleting your account.',
        );
      }
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        ErrorLogger.instance.capture(
          'Unhandled Firebase Auth error: $code',
          source: 'FirebaseAuth',
        );
        return 'Authentication error. Please try again.';
      }
  }
}
