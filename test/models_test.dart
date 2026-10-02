import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/models/account.dart';
import 'package:teb_cashtrack/models/shopping_purchase_list.dart';
import 'package:teb_cashtrack/models/transaction.dart';

void main() {
  group('Transaction', () {
    test('lê o formato legado (ISO string, double, strings vazias)', () {
      final tx = Transaction.fromMap({
        'date': '2026-03-04T00:00:00.000',
        'accountId': 'a',
        'amount': 12.5,
        'details': '',
        'tagId': '',
        'type': 'credit',
      }, '1');
      expect(tx.date, DateTime(2026, 3, 4));
      expect(tx.amountCents, 1250);
      expect(tx.details, isNull);
      expect(tx.tagId, isNull);
      expect(tx.type, TransactionType.credit);
      expect(tx.signedCents, 1250);
    });

    test('evita erro de ponto flutuante na conversão para centavos', () {
      final tx = Transaction.fromMap({'amount': 0.29, 'type': 'debit'}, '1');
      expect(tx.amountCents, 29);
      expect(tx.signedCents, -29);
    });

    test('ida e volta no formato atual', () {
      final original = Transaction(
        id: 'x',
        date: DateTime(2026, 1, 2),
        accountId: 'a',
        amountCents: 999,
        details: 'Mercado',
        tagId: 't',
        type: TransactionType.debit,
      );
      final map = original.toMap();
      expect(map['date'], isA<Timestamp>());
      final copy = Transaction.fromMap(map, 'x');
      expect(copy.amountCents, 999);
      expect(copy.date, original.date);
      expect(copy.details, 'Mercado');
      expect(copy.tagId, 't');
    });
  });

  group('Account', () {
    test('lê o rótulo legado do tipo e o saldo em reais', () {
      final account = Account.fromMap({
        'name': 'Nubank',
        'type': 'Cartão de Crédito',
        'balance': 100.1,
        'createdAt': '2026-01-01T00:00:00.000',
      }, '1');
      expect(account.type, AccountType.creditCard);
      expect(account.initialBalanceCents, 10010);
      expect(account.closingDay, isNull);
    });

    test('descarta closingDay de contas que não são cartão', () {
      final account = Account(
        id: '1',
        name: 'Conta',
        type: AccountType.checking,
        initialBalanceCents: 0,
        active: true,
        createdAt: DateTime(2026),
        closingDay: 10,
      );
      expect(account.toMap()['closingDay'], isNull);
    });
  });

  test('ShoppingPurchaseList.withBought não altera a original', () {
    final list = ShoppingPurchaseList(id: '1', date: DateTime(2026), itemIds: ['a', 'b']);
    final updated = list.withBought('a', true);
    expect(list.boughtItemIds, isEmpty);
    expect(updated.boughtItemIds, ['a']);
    expect(updated.withBought('a', false).boughtItemIds, isEmpty);
    expect(updated.withBought('b', true).isComplete, isTrue);
  });
}
