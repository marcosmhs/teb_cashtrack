import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef JsonCollection = CollectionReference<Map<String, dynamic>>;

/// Acesso às coleções do usuário autenticado: `users/{uid}/{coleção}`.
/// Cada usuário enxerga apenas os próprios dados (ver `firestore.rules`).
class UserCollections {
  const UserCollections._();

  static const accounts = 'accounts';
  static const transactions = 'transactions';
  static const tags = 'tags';
  static const shoppingCategories = 'shopping_categories';
  static const shoppingItems = 'shopping_items';
  static const shoppingPurchaseLists = 'shopping_purchase_lists';

  /// Notificações de pagamento capturadas no Android (gravadas pelo serviço nativo).
  static const notificationCaptures = 'notification_captures';

  static const all = [
    accounts,
    transactions,
    tags,
    shoppingCategories,
    shoppingItems,
    shoppingPurchaseLists,
  ];

  static String get uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Nenhum usuário autenticado.');
    return user.uid;
  }

  static JsonCollection of(String name) {
    return FirebaseFirestore.instance.collection('users').doc(uid).collection(name);
  }

  /// Gera um ID único do Firestore (sem risco de colisão entre dispositivos).
  static String newId(String name) => of(name).doc().id;
}
