import '../data/user_collections.dart';
import '../models/shopping_purchase_list.dart';

class ShoppingPurchaseListController {
  JsonCollection get _collection => UserCollections.of(UserCollections.shoppingPurchaseLists);

  String newId() => UserCollections.newId(UserCollections.shoppingPurchaseLists);

  Stream<List<ShoppingPurchaseList>> getPurchaseLists() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ShoppingPurchaseList.fromMap(d.data(), d.id)).toList());
  }

  /// Acompanha uma lista específica; emite `null` se ela for excluída.
  Stream<ShoppingPurchaseList?> watchPurchaseList(String id) {
    return _collection.doc(id).snapshots().map((d) {
      final data = d.data();
      return data == null ? null : ShoppingPurchaseList.fromMap(data, d.id);
    });
  }

  Future<void> savePurchaseList(ShoppingPurchaseList list) async {
    await _collection.doc(list.id).set(list.toMap());
  }

  Future<void> deletePurchaseList(String id) async {
    await _collection.doc(id).delete();
  }
}
