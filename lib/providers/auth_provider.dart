import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  User? get currentUser => _user;
  bool get isLoggedIn => _user != null;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _authService.signInWithEmail(email, password);
  }

  Future<void> register(String email, String password) async {
    await _authService.registerWithEmail(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
