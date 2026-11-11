import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;

import '../data/local_first.dart';
import '../data/user_collections.dart';
import '../models/account.dart';

class AccountController {
  JsonCollection get _collection => UserCollections.of(UserCollections.accounts);

  String newId() => UserCollections.newId(UserCollections.accounts);

  Stream<List<Account>> getAccounts() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Account.fromMap(d.data(), d.id)).toList());
  }

  /// Salva a conta. Se ela for marcada como principal, desmarca as demais
  /// na mesma operação, garantindo um único meio de pagamento principal.
  Future<void> saveAccount(Account account) async {
    if (!account.isDefault) {
      return writeLocal(_collection.doc(account.id).set(account.toMap()), 'a conta');
    }
    final currentDefaults = await _collection.where('isDefault', isEqualTo: true).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in currentDefaults.docs.where((d) => d.id != account.id)) {
      batch.update(doc.reference, {'isDefault': false});
    }
    batch.set(_collection.doc(account.id), account.toMap());
    return writeLocal(batch.commit(), 'a conta');
  }

  Future<void> deleteAccount(String id) =>
      writeLocal(_collection.doc(id).delete(), 'a exclusão da conta');
}
