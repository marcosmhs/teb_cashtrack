import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../models/tag.dart';

class TagController {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final String collectionName = 'tags';

  Stream<List<Tag>> getTags() {
    return _firestore
        .collection(collectionName)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Tag.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addTag(Tag tag) async {
    await _firestore.collection(collectionName).doc(tag.id).set(tag.toMap());
  }

  Future<void> updateTag(Tag tag) async {
    await _firestore.collection(collectionName).doc(tag.id).update(tag.toMap());
  }

  Future<void> deleteTag(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }

  Future<Tag?> getTagById(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (!doc.exists) return null;
      return Tag.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('Erro ao buscar tag $id: $e');
      return null;
    }
  }
}
