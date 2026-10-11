import 'package:flutter_test/flutter_test.dart';
import 'package:teb_cashtrack/models/tag.dart';
import 'package:teb_cashtrack/models/transaction.dart';
import 'package:teb_cashtrack/services/tag_stats.dart';

var _seq = 0;

Transaction _tx(
  String? tagId,
  int cents, {
  TransactionType type = TransactionType.debit,
  DateTime? date,
}) {
  return Transaction(
    id: '${_seq++}',
    date: date ?? DateTime(2026, 10, 5),
    accountId: 'a',
    amountCents: cents,
    tagId: tagId,
    type: type,
  );
}

void main() {
  group('totalsByTag', () {
    test('soma por tag apenas o tipo pedido, do maior para o menor', () {
      final totals = TagStats.totalsByTag([
        _tx('mercado', 1000),
        _tx('mercado', 2500),
        _tx('lazer', 5000),
        _tx(null, 300),
        _tx('salario', 900000, type: TransactionType.credit),
      ], TransactionType.debit);

      expect(totals.map((t) => t.tagId), ['lazer', 'mercado', null]);
      expect(totals[1].cents, 3500);
      expect(totals[1].count, 2);
    });

    test('receitas ficam separadas das despesas', () {
      final totals = TagStats.totalsByTag([
        _tx('salario', 900000, type: TransactionType.credit),
        _tx('mercado', 1000),
      ], TransactionType.credit);
      expect(totals.single.tagId, 'salario');
    });
  });

  group('sortByRecentUsage', () {
    final now = DateTime(2026, 10, 11, 12);
    final tags = [
      Tag(id: 'a', name: 'Academia'),
      Tag(id: 'm', name: 'Mercado'),
      Tag(id: 't', name: 'Transporte'),
      Tag(id: 'l', name: 'Lazer'),
    ];

    test('mais usadas nos últimos 30 dias primeiro; empates em ordem alfabética', () {
      final sorted = TagStats.sortByRecentUsage(tags, [
        _tx('t', 1, date: DateTime(2026, 10, 10)),
        _tx('t', 1, date: DateTime(2026, 10, 1)),
        _tx('m', 1, date: DateTime(2026, 9, 20)),
        _tx('t', 1, date: DateTime(2026, 9, 15)),
      ], now);
      expect(sorted.map((t) => t.id), ['t', 'm', 'a', 'l']);
    });

    test('ignora uso com mais de 30 dias', () {
      final sorted = TagStats.sortByRecentUsage(tags, [
        for (var i = 0; i < 5; i++) _tx('a', 1, date: DateTime(2026, 9, 1)),
        _tx('l', 1, date: DateTime(2026, 10, 9)),
      ], now);
      expect(sorted.first.id, 'l');
      expect(sorted.map((t) => t.id).skip(1), ['a', 'm', 't']);
    });

    test('não altera a lista original', () {
      final original = [...tags];
      TagStats.sortByRecentUsage(tags, [_tx('l', 1, date: DateTime(2026, 10, 9))], now);
      expect(tags.map((t) => t.id), original.map((t) => t.id));
    });
  });
}
