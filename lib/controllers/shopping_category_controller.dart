import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../models/shopping_category.dart';

class ShoppingCategoryController {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final String collectionName = 'shopping_categories';

  Stream<List<ShoppingCategory>> getCategories() {
    return _firestore
        .collection(collectionName)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => ShoppingCategory.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addCategory(ShoppingCategory category) async {
    await _firestore.collection(collectionName).doc(category.id).set(category.toMap());
  }

  Future<void> updateCategory(ShoppingCategory category) async {
    await _firestore.collection(collectionName).doc(category.id).update(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }

  Future<ShoppingCategory?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (!doc.exists) return null;
      return ShoppingCategory.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('Erro ao buscar categoria $id: $e');
      return null;
    }
  }
}
