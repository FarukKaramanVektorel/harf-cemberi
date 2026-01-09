import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AuthService._init();

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google using Firebase Auth
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Use Firebase Auth's Google provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      if (kIsWeb) {
        // Web: Use popup
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: Use redirect or native
        return await _auth.signInWithProvider(googleProvider);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      throw e;
    }
  }

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
