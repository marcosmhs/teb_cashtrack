import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/format.dart';

/// Período de uma fatura de cartão: lançamentos com data em `(start, end]`.
/// `start == null` significa "desde o início" (cartão sem dia de fechamento).
class InvoicePeriod {
  final DateTime? start;
  final DateTime end;

  const InvoicePeriod({this.start, required this.end});

  bool contains(DateTime date) {
    final day = dateOnly(date);
    if (start != null && !day.isAfter(start!)) return false;
    return !day.isAfter(end);
  }
}

class BalanceCalculator {
  const BalanceCalculator._();

  /// Saldo inicial + créditos − débitos da conta.
  static int accountBalance(Account account, Iterable<Transaction> transactions) {
    return transactions
        .where((t) => t.accountId == account.id)
        .fold(account.initialBalanceCents, (sum, t) => sum + t.signedCents);
  }

  /// Soma dos saldos das contas informadas.
  static int totalBalance(Iterable<Account> accounts, Iterable<Transaction> transactions) {
    return accounts.fold(0, (sum, a) => sum + accountBalance(a, transactions));
  }

  /// Soma assinada (créditos − débitos) de uma lista de lançamentos.
  static int sumSigned(Iterable<Transaction> transactions) {
    return transactions.fold(0, (sum, t) => sum + t.signedCents);
  }

  /// Fatura aberta na data [now] para o dia de fechamento [closingDay].
  /// Um lançamento feito no dia do fechamento entra na fatura que fecha nesse dia.
  static InvoicePeriod currentInvoicePeriod(int? closingDay, DateTime now) {
    final today = dateOnly(now);
    if (closingDay == null) return InvoicePeriod(end: DateTime(9999));

    DateTime closingIn(int year, int month) {
      final lastDay = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, closingDay > lastDay ? lastDay : closingDay);
    }

    final thisMonthClosing = closingIn(today.year, today.month);
    if (!today.isAfter(thisMonthClosing)) {
      return InvoicePeriod(start: closingIn(today.year, today.month - 1), end: thisMonthClosing);
    }
    return InvoicePeriod(start: thisMonthClosing, end: closingIn(today.year, today.month + 1));
  }

  /// Valor da fatura aberta do cartão (débitos − créditos no período).
  /// Positivo = valor a pagar; negativo = saldo credor.
  static int currentInvoice(Account card, Iterable<Transaction> transactions, DateTime now) {
    final period = currentInvoicePeriod(card.closingDay, now);
    return -transactions
        .where((t) => t.accountId == card.id && period.contains(t.date))
        .fold(0, (sum, t) => sum + t.signedCents);
  }
}
