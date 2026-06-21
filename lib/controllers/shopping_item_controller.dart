import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/shopping_item.dart';

class ShoppingItemController {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final String collectionName = 'shopping_items';

  Stream<List<ShoppingItem>> getItems() {
    return _firestore.collection(collectionName).orderBy('description').snapshots().map((s) {
      final items = s.docs.map((d) => ShoppingItem.fromMap(d.data(), d.id)).toList();
      items.sort((a, b) => a.description.toLowerCase().compareTo(b.description.toLowerCase()));
      return items;
    });
  }

  Future<void> addItem(ShoppingItem item) async {
    await _firestore.collection(collectionName).doc(item.id).set(item.toMap());
  }

  Future<void> updateItem(ShoppingItem item) async {
    await _firestore.collection(collectionName).doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }
}
