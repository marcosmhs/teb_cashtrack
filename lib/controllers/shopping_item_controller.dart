import '../data/user_collections.dart';
import '../models/shopping_item.dart';

class ShoppingItemController {
  JsonCollection get _collection => UserCollections.of(UserCollections.shoppingItems);

  String newId() => UserCollections.newId(UserCollections.shoppingItems);

  Stream<List<ShoppingItem>> getItems() {
    return _collection.snapshots().map((s) {
      final items = s.docs.map((d) => ShoppingItem.fromMap(d.data(), d.id)).toList();
      items.sort((a, b) => a.description.toLowerCase().compareTo(b.description.toLowerCase()));
      return items;
    });
  }

  Future<void> saveItem(ShoppingItem item) async {
    await _collection.doc(item.id).set(item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _collection.doc(id).delete();
  }
}
