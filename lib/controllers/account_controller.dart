import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/account.dart';

class AccountController {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final String collectionName = 'accounts';

  Stream<List<Account>> getAccounts() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => Account.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  Future<void> addAccount(Account account) async {
    await _firestore.collection(collectionName).doc(account.id).set(account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    await _firestore.collection(collectionName).doc(account.id).update(account.toMap());
  }

  Future<void> deleteAccount(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }
}
