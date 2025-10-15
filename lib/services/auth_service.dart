import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  AuthService() {
    // Keep local user in sync with FirebaseAuth state
    _auth.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  String? get userEmail => _user?.email;
  bool get isSignedIn => _user != null;

  Future<void> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _user = cred.user;
      notifyListeners();
    } on FirebaseAuthException {
      // Rethrow so caller can inspect e.code and show friendly messages
      rethrow;
    }
  }

  Future<void> createAccount({required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      _user = cred.user;
      notifyListeners();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
