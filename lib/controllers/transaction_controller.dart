import 'package:cloud_firestore/cloud_firestore.dart' show QueryDocumentSnapshot, Timestamp;

import '../data/local_first.dart';
import '../data/user_collections.dart';
import '../models/transaction.dart';

class TransactionController {
  JsonCollection get _collection => UserCollections.of(UserCollections.transactions);

  String newId() => UserCollections.newId(UserCollections.transactions);

  List<Transaction> _map(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) =>
      docs.map((d) => Transaction.fromMap(d.data(), d.id)).toList();

  /// Todos os lançamentos do usuário, do mais recente para o mais antigo.
  Stream<List<Transaction>> getTransactions() {
    return _collection.orderBy('date', descending: true).snapshots().map((s) => _map(s.docs));
  }

  /// Lançamentos com data entre [from] e [to] (inclusive). Limites nulos ficam em aberto.
  Stream<List<Transaction>> getTransactionsInRange({DateTime? from, DateTime? to}) {
    var query = _collection.orderBy('date', descending: true);
    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      final endExclusive = DateTime(to.year, to.month, to.day + 1);
      query = query.where('date', isLessThan: Timestamp.fromDate(endExclusive));
    }
    return query.snapshots().map((s) => _map(s.docs));
  }

  Stream<List<Transaction>> getTransactionsForAccount(String accountId) {
    // Ordenação feita no cliente para não exigir índice composto (accountId + date).
    return _collection.where('accountId', isEqualTo: accountId).snapshots().map((s) {
      return _map(s.docs)..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  /// Conta pelos documentos, não por `count()`: agregações só rodam no servidor,
  /// e esta leitura também funciona sem conexão (usa o banco do aparelho).
  Future<int> countForAccount(String accountId) async {
    final result = await _collection.where('accountId', isEqualTo: accountId).get();
    return result.size;
  }

  Future<void> saveTransaction(Transaction transaction) =>
      writeLocal(_collection.doc(transaction.id).set(transaction.toMap()), 'o lançamento');

  Future<void> deleteTransaction(String id) =>
      writeLocal(_collection.doc(id).delete(), 'a exclusão do lançamento');
}
