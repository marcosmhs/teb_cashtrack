import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/models/account.dart';
import 'package:teb_cashtrack/models/transaction.dart';
import 'package:teb_cashtrack/services/balance_calculator.dart';

Account _account(
  String id, {
  int initial = 0,
  AccountType type = AccountType.checking,
  int? closingDay,
}) {
  return Account(
    id: id,
    name: id,
    type: type,
    initialBalanceCents: initial,
    active: true,
    createdAt: DateTime(2026),
    closingDay: closingDay,
  );
}

Transaction _tx(String accountId, int cents, TransactionType type, DateTime date) {
  return Transaction(
    id: '$accountId-$cents-$date',
    date: date,
    accountId: accountId,
    amountCents: cents,
    type: type,
  );
}

void main() {
  final d = DateTime(2026, 5, 10);

  group('accountBalance', () {
    test('soma saldo inicial, créditos e débitos apenas da conta', () {
      final account = _account('a', initial: 10000);
      final txs = [
        _tx('a', 2500, TransactionType.credit, d),
        _tx('a', 1000, TransactionType.debit, d),
        _tx('b', 99999, TransactionType.credit, d),
      ];
      expect(BalanceCalculator.accountBalance(account, txs), 11500);
    });

    test('totalBalance soma as contas', () {
      final txs = [
        _tx('a', 500, TransactionType.debit, d),
        _tx('b', 700, TransactionType.credit, d),
      ];
      expect(
        BalanceCalculator.totalBalance([_account('a', initial: 1000), _account('b')], txs),
        1200,
      );
    });
  });

  group('currentInvoicePeriod', () {
    test('antes do fechamento: do fechamento anterior até o deste mês', () {
      final p = BalanceCalculator.currentInvoicePeriod(15, DateTime(2026, 5, 10));
      expect(p.start, DateTime(2026, 4, 15));
      expect(p.end, DateTime(2026, 5, 15));
    });

    test('no dia do fechamento ainda é a fatura que fecha hoje', () {
      final p = BalanceCalculator.currentInvoicePeriod(15, DateTime(2026, 5, 15, 23, 59));
      expect(p.end, DateTime(2026, 5, 15));
    });

    test('depois do fechamento: fatura do mês seguinte', () {
      final p = BalanceCalculator.currentInvoicePeriod(15, DateTime(2026, 5, 20));
      expect(p.start, DateTime(2026, 5, 15));
      expect(p.end, DateTime(2026, 6, 15));
    });

    test('ajusta o dia de fechamento para meses curtos e virada de ano', () {
      final feb = BalanceCalculator.currentInvoicePeriod(31, DateTime(2026, 2, 10));
      expect(feb.start, DateTime(2026, 1, 31));
      expect(feb.end, DateTime(2026, 2, 28));

      final jan = BalanceCalculator.currentInvoicePeriod(5, DateTime(2026, 1, 3));
      expect(jan.start, DateTime(2025, 12, 5));

      final dec = BalanceCalculator.currentInvoicePeriod(5, DateTime(2025, 12, 20));
      expect(dec.end, DateTime(2026, 1, 5));
    });

    test('limites do período: exclui o início e inclui o fim', () {
      final p = BalanceCalculator.currentInvoicePeriod(15, DateTime(2026, 5, 10));
      expect(p.contains(DateTime(2026, 4, 15, 12)), isFalse);
      expect(p.contains(DateTime(2026, 4, 16)), isTrue);
      expect(p.contains(DateTime(2026, 5, 15, 20)), isTrue);
      expect(p.contains(DateTime(2026, 5, 16)), isFalse);
    });
  });

  group('currentInvoice', () {
    test('soma débitos menos créditos apenas do período', () {
      final card = _account('c', type: AccountType.creditCard, closingDay: 15);
      final txs = [
        _tx('c', 5000, TransactionType.debit, DateTime(2026, 4, 10)), // fatura anterior
        _tx('c', 3000, TransactionType.debit, DateTime(2026, 4, 20)),
        _tx('c', 1000, TransactionType.credit, DateTime(2026, 5, 1)), // estorno
        _tx('c', 2000, TransactionType.debit, DateTime(2026, 5, 15)),
      ];
      expect(BalanceCalculator.currentInvoice(card, txs, DateTime(2026, 5, 10)), 4000);
    });

    test('cartão sem dia de fechamento considera todos os lançamentos', () {
      final card = _account('c', type: AccountType.creditCard);
      final txs = [
        _tx('c', 5000, TransactionType.debit, DateTime(2020)),
        _tx('c', 7000, TransactionType.credit, DateTime(2026)),
      ];
      expect(BalanceCalculator.currentInvoice(card, txs, DateTime(2026, 5, 10)), -2000);
    });
  });
}
