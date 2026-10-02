import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;

import '../data/user_collections.dart';
import '../models/account.dart';
import '../models/shopping_category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_purchase_list.dart';
import '../models/tag.dart';
import '../models/transaction.dart';

/// Copia os dados das coleções antigas (na raiz do Firestore, sem dono) para
/// `users/{uid}/...`, convertendo para o formato atual (centavos e Timestamp).
///
/// A operação é idempotente: os documentos mantêm o mesmo ID, então executar
/// de novo apenas sobrescreve as cópias. Os dados originais não são apagados.
class LegacyMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final Map<String, Map<String, dynamic> Function(Map<String, dynamic>, String)>
  _converters = {
    UserCollections.accounts: (m, id) => Account.fromMap(m, id).toMap(),
    UserCollections.transactions: (m, id) => Transaction.fromMap(m, id).toMap(),
    UserCollections.tags: (m, id) => Tag.fromMap(m, id).toMap(),
    UserCollections.shoppingCategories: (m, id) => ShoppingCategory.fromMap(m, id).toMap(),
    UserCollections.shoppingItems: (m, id) => ShoppingItem.fromMap(m, id).toMap(),
    UserCollections.shoppingPurchaseLists: (m, id) => ShoppingPurchaseList.fromMap(m, id).toMap(),
  };

  /// Retorna a quantidade de documentos copiados por coleção.
  Future<Map<String, int>> migrate() async {
    final result = <String, int>{};
    for (final entry in _converters.entries) {
      final legacy = await _firestore.collection(entry.key).get();
      final target = UserCollections.of(entry.key);

      const chunk = 450;
      for (var i = 0; i < legacy.docs.length; i += chunk) {
        final batch = _firestore.batch();
        for (final doc in legacy.docs.skip(i).take(chunk)) {
          batch.set(target.doc(doc.id), entry.value(doc.data(), doc.id));
        }
        await batch.commit();
      }
      result[entry.key] = legacy.docs.length;
    }
    return result;
  }
}
