import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/user_collections.dart';
import '../models/tag.dart';

class TagController {
  JsonCollection get _collection => UserCollections.of(UserCollections.tags);

  String newId() => UserCollections.newId(UserCollections.tags);

  Stream<List<Tag>> getTags() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => Tag.fromMap(d.data(), d.id)).toList());
  }

  Future<void> saveTag(Tag tag) async {
    await _collection.doc(tag.id).set(tag.toMap());
  }

  /// Exclui a tag e remove a referência a ela dos lançamentos, evitando tags órfãs.
  Future<void> deleteTag(String id) async {
    final firestore = FirebaseFirestore.instance;
    final linked = await UserCollections.of(
      UserCollections.transactions,
    ).where('tagId', isEqualTo: id).get();

    // Lotes do Firestore aceitam até 500 operações.
    const chunk = 450;
    for (var i = 0; i < linked.docs.length; i += chunk) {
      final batch = firestore.batch();
      for (final doc in linked.docs.skip(i).take(chunk)) {
        batch.update(doc.reference, {'tagId': null});
      }
      await batch.commit();
    }
    await _collection.doc(id).delete();
  }
}
