import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _emailKey = 'cached_email';
  static const _passwordKey = 'cached_password';

  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _saveCredentials(email, password);
    return credential.user;
  }

  Future<User?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _saveCredentials(email, password);
    return credential.user;
  }

  Future<User?> tryAutoLogin() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    if (email == null || password == null) {
      return null;
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException {
      await clearCredentials();
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await clearCredentials();
  }

  Future<void> updateEmail(String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found', message: 'Usuário não autenticado.');
    }
    await user.verifyBeforeUpdateEmail(email.trim());
    await _saveEmail(email);
  }

  Future<void> updatePassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found', message: 'Usuário não autenticado.');
    }
    await user.updatePassword(password);
    await _savePassword(password);
  }

  Future<String?> getCurrentEmail() async {
    return _auth.currentUser?.email;
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim());
    await prefs.setString(_passwordKey, password);
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim());
  }

  Future<void> _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }
}
