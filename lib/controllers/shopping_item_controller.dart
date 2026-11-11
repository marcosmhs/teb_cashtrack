import '../data/local_first.dart';
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

  Future<void> saveItem(ShoppingItem item) =>
      writeLocal(_collection.doc(item.id).set(item.toMap()), 'o item');

  Future<void> deleteItem(String id) =>
      writeLocal(_collection.doc(id).delete(), 'a exclusão do item');
}
