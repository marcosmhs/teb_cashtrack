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

  Future<void> saveAccount(Account account) async {
    await _collection.doc(account.id).set(account.toMap());
  }

  Future<void> deleteAccount(String id) async {
    await _collection.doc(id).delete();
  }
}
