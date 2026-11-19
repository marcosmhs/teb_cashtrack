import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/models/transaction.dart';

void main() {
  Transaction read(String? source) => Transaction.fromMap({
    'date': Timestamp.fromDate(DateTime(2026, 11, 10, 12, 30)),
    'accountId': 'card',
    'amountCents': 4590,
    'details': 'Padaria Pão Quente',
    'type': 'debit',
    'source': source,
  }, 'x');

  test('lançamento importado da Pluggy', () {
    final tx = read('pluggy');
    expect(tx.isAutomatic, isTrue);
    expect(tx.isFromPluggy, isTrue);
    expect(tx.sourceLabel, 'banco');
    expect(tx.signedCents, -4590);
  });

  test('lançamento de notificação', () {
    final tx = read('notification');
    expect(tx.isAutomatic, isTrue);
    expect(tx.isFromPluggy, isFalse);
    expect(tx.sourceLabel, 'automático');
  });

  test('lançamento manual não tem origem', () {
    final tx = read(null);
    expect(tx.isAutomatic, isFalse);
    expect(tx.sourceLabel, isNull);
  });
}
