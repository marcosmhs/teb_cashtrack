import '../data/user_collections.dart';
import '../models/shopping_category.dart';

class ShoppingCategoryController {
  JsonCollection get _collection => UserCollections.of(UserCollections.shoppingCategories);

  String newId() => UserCollections.newId(UserCollections.shoppingCategories);

  Stream<List<ShoppingCategory>> getCategories() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => ShoppingCategory.fromMap(d.data(), d.id)).toList());
  }

  Future<void> saveCategory(ShoppingCategory category) async {
    await _collection.doc(category.id).set(category.toMap());
  }

  Future<int> countItems(String categoryId) async {
    final result = await UserCollections.of(
      UserCollections.shoppingItems,
    ).where('categoryId', isEqualTo: categoryId).count().get();
    return result.count ?? 0;
  }

  Future<void> deleteCategory(String id) async {
    await _collection.doc(id).delete();
  }
}
