import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/shopping_purchase_list.dart';

class ShoppingPurchaseListController {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final String collectionName = 'shopping_purchase_lists';

  Future<void> addPurchaseList(ShoppingPurchaseList list) async {
    await _firestore.collection(collectionName).doc(list.id).set(list.toMap());
  }

  Future<void> updatePurchaseList(ShoppingPurchaseList list) async {
    await _firestore.collection(collectionName).doc(list.id).update(list.toMap());
  }

  Stream<List<ShoppingPurchaseList>> getPurchaseLists() {
    return _firestore
        .collection(collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ShoppingPurchaseList.fromMap(d.data(), d.id)).toList());
  }
}
