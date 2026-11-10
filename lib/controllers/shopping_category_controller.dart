import '../data/local_first.dart';
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

  Future<void> saveCategory(ShoppingCategory category) =>
      writeLocal(_collection.doc(category.id).set(category.toMap()), 'a categoria');

  /// Conta pelos documentos, não por `count()`: agregações só rodam no servidor,
  /// e esta leitura também funciona sem conexão (usa o banco do aparelho).
  Future<int> countItems(String categoryId) async {
    final result = await UserCollections.of(
      UserCollections.shoppingItems,
    ).where('categoryId', isEqualTo: categoryId).get();
    return result.size;
  }

  Future<void> deleteCategory(String id) =>
      writeLocal(_collection.doc(id).delete(), 'a exclusão da categoria');
}
