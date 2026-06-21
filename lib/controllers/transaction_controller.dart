import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class TransactionController {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final String collectionName = 'transactions';

  Stream<List<Transaction>> getTransactions() {
    return _firestore
        .collection(collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Transaction.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  /// Últimos lançamentos (limit)
  Stream<List<Transaction>> getLatestTransactions(int limit) {
    return _firestore
        .collection(collectionName)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Transaction.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Transaction>> getTransactionsForAccount(String accountId) {
    return _firestore
        .collection(collectionName)
        .where('accountId', isEqualTo: accountId)
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((e) {
          // Log Firestore stream errors
          debugPrint('Erro em getTransactionsForAccount($accountId): $e');
        })
        .map((s) {
          try {
            return s.docs.map((d) => Transaction.fromMap(d.data(), d.id)).toList();
          } catch (e) {
            // Log mapping/parsing errors and return empty list to keep stream alive
            debugPrint('Erro ao mapear transações em getTransactionsForAccount($accountId): $e');
            return <Transaction>[];
          }
        });
  }

  /// Sum total for a set of account IDs: debits summed minus credits summed
  Stream<double> getTotalForAccountIds(List<String> accountIds) {
    if (accountIds.isEmpty) return Stream.value(0.0);
    // Firestore supports whereIn with up to 10 items; if more, split client-side
    final query = _firestore.collection(collectionName).where('accountId', whereIn: accountIds);
    return query.snapshots().map((s) {
      double totalDebit = 0.0;
      double totalCredit = 0.0;
      for (final d in s.docs) {
        final tx = Transaction.fromMap(d.data(), d.id);
        if (tx.type.toLowerCase() == 'debit') {
          totalDebit += tx.amount;
        } else {
          totalCredit += tx.amount;
        }
      }
      // Créditos aumentam o saldo, débitos reduzem o saldo => saldo = créditos - débitos
      return totalCredit - totalDebit;
    });
  }

  /// Transactions for multiple account IDs. If more than 10 ids, falls back to client-side filter.
  Stream<List<Transaction>> getTransactionsForAccountIds(List<String> accountIds) {
    if (accountIds.isEmpty) return Stream.value(<Transaction>[]);
    if (accountIds.length <= 10) {
      return _firestore
          .collection(collectionName)
          .where('accountId', whereIn: accountIds)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => Transaction.fromMap(d.data(), d.id)).toList());
    }
    // Fallback: stream all and filter client-side (less efficient)
    return _firestore
        .collection(collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => Transaction.fromMap(d.data(), d.id))
              .where((tx) => accountIds.contains(tx.accountId))
              .toList(),
        );
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _firestore.collection(collectionName).doc(transaction.id).set(transaction.toMap());
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _firestore.collection(collectionName).doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }
}
