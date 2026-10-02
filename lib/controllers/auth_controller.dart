import 'package:firebase_auth/firebase_auth.dart';

/// Autenticação via Firebase Auth. A sessão é persistida pelo próprio Firebase,
/// então nenhuma credencial é armazenada localmente pelo app.
class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  String? get currentEmail => _auth.currentUser?.email;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  /// Envia o e-mail de verificação para o novo endereço. A troca só é efetivada
  /// depois que o usuário confirma pelo link recebido.
  Future<void> updateEmail(String email) async {
    await _requireUser().verifyBeforeUpdateEmail(email.trim());
  }

  Future<void> updatePassword(String password) async {
    await _requireUser().updatePassword(password);
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found', message: 'Usuário não autenticado.');
    }
    return user;
  }

  /// Traduz os códigos de erro do Firebase Auth para mensagens amigáveis.
  static String describeError(Object error) {
    if (error is! FirebaseAuthException) return 'Ocorreu um erro inesperado. Tente novamente.';
    switch (error.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Este usuário foi desativado.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'requires-recent-login':
        return 'Por segurança, saia e entre novamente antes de alterar estes dados.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return error.message ?? 'Erro de autenticação (${error.code}).';
    }
  }
}
