import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:firebase_auth/firebase_auth.dart';

import '../data/user_collections.dart';

/// Exclui a conta do usuário e todos os seus dados (exigência do Google Play).
///
/// A ordem importa: confirma a senha, apaga `users/{uid}/...` enquanto as regras
/// do Firestore ainda reconhecem o dono e, por fim, remove o usuário do Firebase Auth.
class AccountDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _collections = [...UserCollections.all, UserCollections.notificationCaptures];

  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'user-not-found', message: 'Usuário não autenticado.');
    }

    // O Firebase só permite excluir a conta após um login recente.
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );

    for (final name in _collections) {
      final docs = (await UserCollections.of(name).get()).docs;
      const chunk = 450;
      for (var i = 0; i < docs.length; i += chunk) {
        final batch = _firestore.batch();
        for (final doc in docs.skip(i).take(chunk)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await _firestore.collection('users').doc(user.uid).delete();

    await user.delete();
  }
}
